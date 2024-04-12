//
//  EditInfoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import SwiftUI
//TODO: Save button to dismiss keyboard and view if upserting is success. show extra Alert if upsert failed.

//TODO: Implement Button, confirmation, success for delete entry.

//TODO: View to look like the newPromptView -> AddNew (plus the Delete functionality)

//TODO: !!! Does not edit Entry in Pinecone !!!

struct EditInfoView: View {
    
    @StateObject var viewModel: EditInfoViewModel
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var openAiManager: OpenAIManager
    @State var showProgress: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
   

    var body: some View {
        ZStack {
            
            
            VStack {
                if showProgress {
                    ProgressView()
                }
                else  {
                    InfoView(viewModel: viewModel).padding()
                }
            }
            if viewModel.showTopBar {
                TopNotificationBar(message: "Info saved successfully !", show: $viewModel.showTopBar)
                    .transition(.move(edge: .top))
                    .animation(.easeInOut, value: viewModel.showTopBar)
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
            .alert(isPresented: $viewModel.showConfirmation) {
                Alert(
                    title: Text("Save Info?"),
                    message: Text("Are you sure you want to save these changes?"),
                    primaryButton: .destructive(Text("OK")) {
                        withAnimation {
                            showProgress = true
                        }
                        Task {
                            await upsertEditedInfo()
                            pineconeManager.clearManager()
                            openAiManager.clearManager()
                        }
                        withAnimation {
                            showProgress = false
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
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
                do {
                    try await pineconeManager.refreshNamespacesIDs()
                } catch {
                    //Show Error Alert
                    print("EditInfoView :: Error refreshNamespacesIDs: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
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
    .environmentObject(PineconeManager())
    .environmentObject(OpenAIManager())
    
}
