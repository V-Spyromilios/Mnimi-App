//
//  EditInfoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import SwiftUI
import CloudKit
import Combine

struct EditInfoView: View {
    
    @StateObject var viewModel: EditInfoViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var apiCalls: ApiCallViewModel
    
    @State private var showNoInternet = false
    @State private var showSuccess: Bool = false
    @State private var inProgress: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Additional State variables
    @State private var shake: Bool = false
    @State private var oldText: String = ""
    @State private var deleteAnimating: Bool = false
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
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
                    }.padding(.top, isIPad() ? 15 : 0)
                }
                
                Button(action: {
                    deleteAnimating = true
                    self.viewModel.activeAlert = .deleteWarning
                }) {
                    LottieRepresentable(filename: "deleteBin", loopMode: .playOnce, isPlaying: $deleteAnimating)
                        .foregroundStyle(.customLightBlue)
                        .frame(width: 40, height: 50)
                        .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                        .padding(.top, isIPad() ? 15 : 0)
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
                        upsertEditedInfo()
                        apiCalls.incrementApiCallCount()
                        openAiManager.clearManager()
                        pineconeManager.clearManager()
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
                        deleteInfo()
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
            }.padding(.top, isIPad() ? 15 : 0)
        })
    }
    
    private func upsertEditedInfo() {
        inProgress = true
        cancellables.removeAll()
        
        let metadata = toDictionary(desc: self.viewModel.description)
        openAiManager.requestEmbeddings(for: self.viewModel.description, isQuestion: false)
        
        // Observe embeddings completion
        openAiManager.$embeddingsCompleted
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { _ in
                handleEmbeddingsReady(metadata: metadata)
            }
            .store(in: &cancellables)
        
        // Observe OpenAI errors
        openAiManager.$openAIError
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { error in
                handleError(error)
            }
            .store(in: &cancellables)
    }
    
    private func handleEmbeddingsReady(metadata: [String: Any]) {
        if !openAiManager.embeddings.isEmpty {
            pineconeManager.upsertData(id: self.viewModel.id, vector: openAiManager.embeddings, metadata: metadata)
            
            // Observe upsert success
            pineconeManager.$upsertSuccesful
                .receive(on: DispatchQueue.main)
                .filter { $0 }
                .sink { _ in
                    handleUpsertSuccess()
                }
                .store(in: &cancellables)
            
            // Observe Pinecone errors
            pineconeManager.$pineconeError
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { error in
                    handleError(error)
                }
                .store(in: &cancellables)
        } else {
            // Handle the case where embeddings are empty
            inProgress = false
            viewModel.occuredErrorDesc = "Embeddings are empty."
            viewModel.activeAlert = .error
            cancellables.removeAll()
        }
    }
    
    private func handleUpsertSuccess() {
        pineconeManager.resetAfterSuccessfulUpserting()
        pineconeManager.refreshNamespacesIDs()
        
        inProgress = false
        showSuccess = true
        
        // Clear cancellables related to this operation
        cancellables.removeAll()
    }
    
    private func handleError(_ error: Error) {
        inProgress = false
        viewModel.occuredErrorDesc = error.localizedDescription
        viewModel.activeAlert = .error
        
        // Clear cancellables related to this operation
        cancellables.removeAll()
    }
    
    private func deleteInfo() {
        cancellables.removeAll()
        let idToDelete = viewModel.id
        pineconeManager.deleteVectorFromPinecone(id: idToDelete)
        
        // Observe deletion success
        pineconeManager.$vectorDeleted
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { _ in
                handleDeletionSuccess(idToDelete: idToDelete)
            }
            .store(in: &cancellables)
        
        // Observe errors
        pineconeManager.$pineconeError
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { error in
                handleError(error)
            }
            .store(in: &cancellables)
    }
    
    private func handleDeletionSuccess(idToDelete: String) {
        pineconeManager.deleteVector(withId: idToDelete)
        pineconeManager.refreshNamespacesIDs()
        
        inProgress = false
        showSuccess = true
        
        // Clear cancellables
        cancellables.removeAll()
    }
    
    private func newInfo() -> some View {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis").bold()
                    Text("Edit Info:").bold()
                    Spacer()
                }.font(.callout).padding(.bottom, 8)
                
                TextEditor(text: $viewModel.description)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(height: Constants.textEditorHeight)
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
                    withAnimation {
                        hideKeyboard()
                        self.viewModel.activeAlert = .editConfirmation
                    }
                }) {
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
                    LottieRepresentable(filename: "Ai Cloud", loopMode: .loop, speed: 0.8)
                        .frame(width: isIPad() ? 440 : 220, height: isIPad() ? 440 : 220)
                        .animation(.easeInOut, value: inProgress)
                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                } else if showSuccess {
                    LottieRepresentable(filename: "Approved", loopMode: .playOnce)
                        .frame(height: isIPad() ? 440 : 130)
                        .padding(.top, 15)
                        .id(UUID())
                        .animation(.easeInOut, value: showSuccess)
                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                }
                Spacer()
            }
            .padding(.horizontal, Constants.standardCardPadding)
            .padding(.top, 12)
        }
        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    EditInfoView(viewModel: EditInfoViewModel(vector: Vector(id: "uuid-test01", metadata: [
        "timestamp": "2024",
        "description": "Pokemon",
    ])))
    .environmentObject(PineconeViewModel(pineconeActor: PineconeActor(), CKviewModel: CloudKitViewModel()))
    .environmentObject(OpenAIViewModel(openAIActor: OpenAIActor()))
    .environmentObject(CloudKitViewModel())
    .environmentObject(NetworkManager())
    .environmentObject(KeyboardResponder())
    .environmentObject(ApiCallViewModel())
}
