//
//  EditInfoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import SwiftUI
import CloudKit

struct EditInfoView: View {
    
    @StateObject var viewModel: EditInfoViewModel
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showNoInternet = false
    @State var showSuccess: Bool = false
    @State var inProgress: Bool = false
    
    var body: some View {
        
        ZStack {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            VStack {
                InfoView(viewModel: viewModel, showSuccess: $showSuccess, inProgress: $inProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
               
            }
        }
        .navigationBarBackButtonHidden(true) 
        .alert(isPresented: $showNoInternet) {
            Alert(
                title: Text("You are not connected to the Internet"),
                message: Text("Please check your connection"),
                dismissButton: .cancel(Text("OK"))
            )
        }
        
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                showNoInternet = true
                if inProgress {
                    inProgress = false
                }
            }
        }
        .onChange(of: showSuccess) { _, show in
            if show {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    showSuccess = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        
        .alert(item: $viewModel.activeAlert) { alertType in
            switch alertType {
            case .editConfirmation:
                return Alert(
                    title: Text("Save Info?"),
                    message: Text("Are you sure you want to save these changes?"),
                    primaryButton: .destructive(Text("OK")) {
                        
                        Task {
                            await upsertEditedInfo()
                            await openAiManager.clearManager()
                            await pineconeManager.clearManager()
                            
                        }
                    },
                    secondaryButton: .cancel {
                        viewModel.activeAlert = nil
                    }
                )
            case .deleteWarning:
                return Alert(
                    title: Text("Delete Info?"),
                    message: Text("Are you sure you want to delete this info?"),
                    primaryButton: .destructive(Text("OK")) {
                        
                        inProgress = true
                        Task {
                            let idToDelete = viewModel.id
                            do {
                                try await pineconeManager.deleteVectorFromPinecone(id: idToDelete)
                                try await cloudKit.deleteImageItem(uniqueID: idToDelete)
                                if pineconeManager.vectorDeleted {
                                    pineconeManager.deleteVector(withId: idToDelete)
                                    try await pineconeManager.fetchAllNamespaceIDs()
                                }
                                DispatchQueue.main.async {
                                    inProgress = false
                                    showSuccess = true
                                }
                            }
                            catch let error as AppNetworkError {
                                await MainActor.run {
                                    viewModel.occuredErrorDesc = error.errorDescription
                                    inProgress = false
                                    viewModel.activeAlert = .error
                                }
                                
                            } catch let error as AppCKError {
                                await MainActor.run {
                                    viewModel.occuredErrorDesc = error.errorDescription
                                    inProgress = false
                                    viewModel.activeAlert = .error
                                }
                                
                            } 
                            catch let error as CKError {
                                await MainActor.run {
                                    viewModel.occuredErrorDesc = error.customErrorDescription
                                    inProgress = false
                                    viewModel.activeAlert = .error
                                }
                            }
                            catch {
                                await MainActor.run {
                                    viewModel.occuredErrorDesc = error.localizedDescription
                                    inProgress = false
                                    viewModel.activeAlert = .error
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel {
                        self.viewModel.activeAlert = nil
                    }
                )
            case .error:
                return Alert(
                    title: Text("Oops"),
                    message: Text("\(viewModel.occuredErrorDesc)\nPlease try again later"),
                    dismissButton: .default(Text("OK")) {
                        withAnimation {
                            viewModel.occuredErrorDesc = ""
                            self.viewModel.activeAlert = nil
                        }
                    }
                )
            }
        }
        .navigationBarTitleView {

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("<").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                    LottieRepresentableNavigation(filename: "smallVault").frame(width: 55, height: 55).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) }
            }
        }
    }
    
    private func upsertEditedInfo() async {

        await MainActor.run {
            inProgress = true
        }
        
        let metadata = toDictionary(desc: self.viewModel.description)
        do {
            await openAiManager.requestEmbeddings(for: self.viewModel.description, isQuestion: false)
            
            if !openAiManager.embeddings.isEmpty {
                try await pineconeManager.upsertDataToPinecone(id: self.viewModel.id, vector: openAiManager.embeddings, metadata: metadata)
            }
            
            if pineconeManager.upsertSuccesful {
                await MainActor.run {
                    pineconeManager.isDataSorted = false
                    pineconeManager.refreshAfterEditing = true
                }
            }
            
            try await pineconeManager.refreshNamespacesIDs()
            
            await MainActor.run {
                inProgress = false
                showSuccess = true
            }
        } catch let error as AppNetworkError {
            await MainActor.run {
                viewModel.occuredErrorDesc = error.errorDescription
                inProgress = false
                viewModel.activeAlert = .error
            }
        } catch let error as AppCKError {
            await MainActor.run {
                viewModel.occuredErrorDesc = error.errorDescription
                inProgress = false
                viewModel.activeAlert = .error
            }
        } catch {
            await MainActor.run {
                viewModel.occuredErrorDesc = error.localizedDescription
                inProgress = false
                viewModel.activeAlert = .error
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
