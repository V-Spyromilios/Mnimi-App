//
//  EditInfoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import SwiftUI

struct EditInfoView: View {
    
    @StateObject var viewModel: EditInfoViewModel
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var openAiManager: OpenAIManager
    @State var showProgress: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var showPop: Bool = false
    
    var body: some View {
        
        ZStack {
            
            InfoView(viewModel: viewModel, showPop: $showPop, presentationMode: presentationMode).opacity(showProgress ? 0.5 : 1.0)
                
            
            if showProgress {
                ProgressView()
            }
        }
        
        .alert(item: $viewModel.activeAlert) { alertType in
            switch alertType {
            case .editConfirmation:
                return Alert(
                    title: Text("Save Info?"),
                    message: Text("Are you sure you want to save these changes?"),
                    primaryButton: .destructive(Text("OK")) {
                        withAnimation {
                            hideKeyboard()
                            showProgress = true
                        }
                        Task {
                            await upsertEditedInfo()
                            pineconeManager.clearManager()
                            await openAiManager.clearManager()
                            DispatchQueue.main.async {
                                showProgress = false
                                viewModel.activeAlert = nil // resetting the activeAlert
                            }
                        }
                    },
                    secondaryButton: .cancel {
                        viewModel.activeAlert = nil // Resetting the activeAlert.
                    }
                )
            case .deleteWarning:
                return Alert(
                    title: Text("Delete Info?"),
                    message: Text("Are you sure you want to delete this info?"),
                    primaryButton: .destructive(Text("OK")) {
                        withAnimation {
                            hideKeyboard()
                            showProgress = true
                        }
                        Task {
                            let idToDelete = viewModel.id
                            do {
                                try await pineconeManager.deleteVectorFromPinecone(id: idToDelete)
                            } catch {
                               
                                showPop = true
                            }
                            if pineconeManager.vectorDeleted {
                               
                                showPop = true
                                pineconeManager.deleteVector(withId: idToDelete)
                                try await pineconeManager.fetchAllNamespaceIDs()
                            }
                            DispatchQueue.main.async {
                                showProgress = false
                                self.viewModel.activeAlert = nil
                            }
                        }
                    },
                    secondaryButton: .cancel {
                        self.viewModel.activeAlert = nil
                    }
                )
            }
        }
    }

    private func upsertEditedInfo() async {
        
        let metadata = toDictionary(desc: self.viewModel.description)
        
        await openAiManager.requestEmbeddings(for: self.viewModel.description, isQuestion: false)
        if !openAiManager.embeddings.isEmpty {
            do {
                try await pineconeManager.upsertDataToPinecone(id: self.viewModel.id, vector: openAiManager.embeddings, metadata: metadata)
            }
            catch {
                print("EditInfoView :: Error while upserting: \(error.localizedDescription)")
            }
            if pineconeManager.upsertSuccesful {
                DispatchQueue.main.async {
                    pineconeManager.isDataSorted = false
                    pineconeManager.refreshAfterEditing = true
                }
                do {
                    try await pineconeManager.refreshNamespacesIDs()
                    
                } catch {
                    //show Error Alert
                    print("EditInfoView :: Error refreshNamespacesIDs: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
//                    popMessage = "Info saved successfully!"
                    showPop = true
                }
            }
        }
    }
}


#Preview {
    
    EditInfoView(viewModel: EditInfoViewModel(vector: Vector(id: "uuid-test01", metadata: [
        "timestamp":"2024",
        "description":"Pokemon",
    ])))
    
}
