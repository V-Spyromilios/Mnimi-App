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
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    @State private var showNoInternet = false
    @State var showSuccess: Bool = false
    @State var inProgress: Bool = false
    @EnvironmentObject var apiCalls: ApiCallViewModel
    
    //newInfo
    @State private var thrownError: String = ""
    @State private var apiCallInProgress: Bool = false
    @State private var animateStep: Int = 0
    @State private var shake: Bool = false
    @State private var oldText: String = ""
    @State private var DeleteAnimating: Bool = false
    
    var body: some View {
        
        ZStack {
            GeometryReader { geometry in
                
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                
                newInfo()
                   
                    .frame(height: geometry.size.height)
                
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
        .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if keyboardResponder.currentHeight > 0 {
                        Button {
                            hideKeyboard()
                        } label: {
                            HideKeyboardLabel()
                        }.padding(.top, isIPad() ? 15: 0)
                    }
                    
                    Button(action: {
                        DeleteAnimating = true
                        self.viewModel.activeAlert = .deleteWarning
                    }) {
                        LottieRepresentable(filename: "deleteBin", loopMode: .playOnce, isPlaying: $DeleteAnimating).foregroundStyle(.customLightBlue)
                            .frame(width: 40, height: 50)
                            .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                            .padding(.top, isIPad() ? 15: 0)
                    }
                }
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
                            apiCalls.incrementApiCallCount()
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
                                    apiCalls.incrementApiCallCount()
                                    pineconeManager.deleteVector(withId: idToDelete)
                                    
                                    try await pineconeManager.fetchAllNamespaceIDs()
                                    apiCalls.incrementApiCallCount()
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
        .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
//                        LottieRepresentableNavigation(filename: "smallVault").frame(width: 55, height: 55).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                    }.padding(.top, isIPad() ? 15: 0)
                })
            
    }
    
    private func upsertEditedInfo() async {

        await MainActor.run {
            inProgress = true
        }
        
        let metadata = toDictionary(desc: self.viewModel.description)
        do {
            try await openAiManager.requestEmbeddings(for: self.viewModel.description, isQuestion: false)
            
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
    
    private func newInfo() -> some View {
        ScrollView {
        VStack {
            HStack {
                Image(systemName: "rectangle.and.pencil.and.ellipsis").bold()
                Text("Edit Info:").bold()
                Spacer() //or .frame(alignment:) in the hstack
            }.font(.callout).padding(.bottom, 8)
            
            
            TextEditor(text: $viewModel.description)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(height: Constants.textEditorHeight)
            //                    .frame(maxWidth: idealWidth(for: geometry.size.width))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                        .foregroundColor(Color.gray)
                )
            
                .padding(.bottom)
            
            
            Button(action:  {
                
                if shake { return }

                if viewModel.description.isEmpty || (oldText == viewModel.description) {
                    withAnimation { shake = true }
                    return
                }
                DispatchQueue.main.async {
                    withAnimation {
                        hideKeyboard()
                        self.viewModel.activeAlert = .editConfirmation }
                }
            }
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                        .fill(Color.customLightBlue)
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .frame(height: Constants.buttonHeight)
                    
                    Text("Save").font(.title2).bold()
                        .foregroundColor(Color.buttonText)
                        .accessibilityLabel("save")
                }
                .contentShape(Rectangle())
                
            }
            .frame(maxWidth: .infinity)
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
            .padding(.top, 12)
            .padding(.horizontal)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
            .id("SubmitButton")
            .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
            
            if inProgress {
                LottieRepresentable(filename: "Ai Cloud", loopMode: .loop, speed: 0.8).frame(width: isIPad() ? 440: 220, height: isIPad() ? 440: 220).animation(.easeInOut, value: inProgress)
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
            }
            
            else if showSuccess {
                LottieRepresentable(filename: "Approved", loopMode: .playOnce).frame(height: isIPad() ? 440: 130).padding(.top, 15).id(UUID()).animation(.easeInOut, value: showSuccess)
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
            }
            Spacer()
        } .padding(.horizontal, Constants.standardCardPadding)
                .padding(.top, 12)
    } .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
    }

}


#Preview {
    
    EditInfoView(viewModel: EditInfoViewModel(vector: Vector(id: "uuid-test01", metadata: [
        "timestamp":"2024",
        "description":"Pokemon",
    ])))
    
}
