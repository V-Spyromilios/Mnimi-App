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
    @State var topBarMessage: String = ""
    
    
    var body: some View {
        
       
        ZStack {
            if viewModel.showTopBar {
                TopNotificationBar(message: topBarMessage, show: $viewModel.showTopBar)
                    .transition(.move(edge: .top))
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            topBarMessage = ""
                        }
                    }
            }
            else if showProgress {
                ProgressView()
            }
            
            InfoView(viewModel: viewModel).opacity(showProgress ? 0.5 : 1.0)
        }
        .alert(item: $viewModel.activeAlert) { alertType in
            switch alertType {
            case .editConfirmation:
                return Alert(
                    title: Text("Save Info?"),
                    message: Text("Are you sure you want to save these changes?"),
                    primaryButton: .destructive(Text("OK")) {
                        withAnimation {
                            showProgress = true
                        }
                        Task {
                            await upsertEditedInfo()
                            pineconeManager.clearManager()
                            await openAiManager.clearManager()
                            DispatchQueue.main.async {
                                showProgress = false
                                viewModel.activeAlert = nil // Resetting the activeAlert after action
                            }
                        }
                    },
                    secondaryButton: .cancel {
                        viewModel.activeAlert = nil // Resetting the activeAlert when canceled
                    }
                )
            case .deleteWarning:
                return Alert(
                    title: Text("Delete Info?"),
                    message: Text("Are you sure you want to delete this info?"),
                    primaryButton: .destructive(Text("OK")) {
                        withAnimation {
                            showProgress = true
                        }
                        Task {
                            do {
                                try await pineconeManager.deleteVector(id: viewModel.id)
                            } catch {
                                topBarMessage = "Unable to Delete, \(error.localizedDescription)."
                                viewModel.showTopBar = true
                            }
                            if pineconeManager.vectorDeleted {
                                topBarMessage = "Info deleted!"
                                viewModel.showTopBar = true
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

        
//        .alert(isPresented: $viewModel.showDeleteWarning) {
//            Alert(
//                title: Text("Delete Info?"),
//                message: Text("Are you sure you want to delete this info?"),
//                primaryButton: .destructive(Text("OK")) {
//                    withAnimation {
//                        showProgress = true
//                        
//                        Task {
//                            do {
//                                try await pineconeManager.deleteVector(id: viewModel.id)
//                                
//                            } catch {
//                                
//                                topBarMessage = "Unable to Delete, \(error.localizedDescription)."
//                                viewModel.showTopBar = true
//                                
//                                
//                            }
//                            if pineconeManager.vectorDeleted {
//                                
//                                topBarMessage = "Info deleted!"
//                                viewModel.showTopBar = true
//                                
//                            }
//                        }
//                        Task {
//                            pineconeManager.clearManager()
//                            await openAiManager.clearManager()
//                        }
//                        showProgress = false
//                    }
//                },
//                secondaryButton: .cancel()
//            )
//        }
        
        
    }
    
    //TODO: This also needs Progress View
    private func upsertEditedInfo() async {
        let metadata: [String: String] = [
            "relevantFor": self.viewModel.relevantFor,
            "description": self.viewModel.description,
            "timestamp": self.viewModel.timestamp
        ]
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
                    pineconeManager.refreshAfterEditing = true
                }
                do {
                    try await pineconeManager.refreshNamespacesIDs()
                    
                } catch {
                    //Show Error Alert
                    print("EditInfoView :: Error refreshNamespacesIDs: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    topBarMessage = "Info saved successfully!"
                    viewModel.showTopBar = true
                }
            }
        }
    }
}


#Preview {
    
    EditInfoView(viewModel: EditInfoViewModel(vector: Vector(id: "uuid-test01", metadata: [
        "timestamp":"2024",
        "relevantFor":"Charlie",
        "description":"Pokemon",
    ])))
    
    
}
