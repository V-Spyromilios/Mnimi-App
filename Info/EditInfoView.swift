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
    
    let hapticGenerator = UINotificationFeedbackGenerator()
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
    @State private var shake: Bool = false
    @State private var oldText: String = ""
    @State private var deleteAnimating: Bool = false
    @State private var buttonIsVisible: Bool = true
    @State private var showShareSheet: Bool = false
    @State private var shakeOffset: CGFloat = 0
    
    private var shouldShowLoading: Bool {
        inProgress || showSuccess
    }
    
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
                    withAnimation(.easeInOut) {
                        deleteAnimating = true
                        self.viewModel.activeAlert = .deleteWarning }
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .font(.title3).foregroundStyle(.red.opacity(0.7)).fontDesign(.rounded)
                        .padding(.leading, 8)
                        .padding(.top, isIPad() ? 15 : 0)
                }
                .scaleEffect(deleteAnimating ? 1.1 : 1)
            }
        }
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                showNoInternet = true
                if inProgress {
                    withAnimation(.easeInOut) {
                        inProgress = false }
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
                        onEdit()
                    },
                    secondaryButton: .cancel {
                        withAnimation(.easeInOut) {
                            viewModel.activeAlert = nil
                            buttonIsVisible = true
                        }
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
                        withAnimation(.easeInOut) {
                            deleteAnimating = false
                            self.viewModel.activeAlert = nil
                            buttonIsVisible = true
                            
                        }
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
                            buttonIsVisible = true
                        }
                    }
                )
            }
        }
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left").font(.title3).foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
            }.padding(.top, isIPad() ? 15 : 0)
        }, trailing: Button(action: {
            withAnimation(.easeInOut) {
                showShareSheet.toggle() }
        }, label: {
            Image(systemName: "square.and.arrow.up").font(.title3).foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded)
                .scaleEffect(showShareSheet ? 1.1 : 1)
        }))
        .sheet(isPresented: $showShareSheet) {
            let item = viewModel.description
            ShareSheet(items: [item])
        }
    }
    
    private func onEdit() {
        Task {
            await upsertEditedInfo()
            apiCalls.incrementApiCallCount()
            openAiManager.clearManager()
            pineconeManager.clearManager()
        }
    }
    
    @MainActor
    private func upsertEditedInfo() async {
        inProgress = true
        
        let metadata = toDictionary(desc: self.viewModel.description)
        do {
            try await openAiManager.requestEmbeddings(for: self.viewModel.description, isQuestion: false)
            
            if !openAiManager.embeddings.isEmpty {
                pineconeManager.upsertData(id: self.viewModel.id, vector: openAiManager.embeddings, metadata: metadata)
                
                handleUpsertSuccess()
            } else {
                // Handle the case where embeddings are empty
                inProgress = false
                viewModel.occuredErrorDesc = "Embeddings are empty."
                viewModel.activeAlert = .error
            }
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func handleUpsertSuccess() {
        withAnimation {
            hapticGenerator.notificationOccurred(.success)
            showSuccess = true
            inProgress = false
            pineconeManager.resetAfterSuccessfulUpserting()
            pineconeManager.refreshNamespacesIDs()
            
            openAiManager.clearManager()
            pineconeManager.clearManager()
            apiCalls.incrementApiCallCount()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                showSuccess = false
                buttonIsVisible = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func handleError(_ error: Error) {
        withAnimation {
            inProgress = false
            viewModel.occuredErrorDesc = error.localizedDescription
            viewModel.activeAlert = .error
        }
    }
    
    private func deleteInfo() {
        Task {
            inProgress = true
            let idToDelete = viewModel.id
            
            pineconeManager.deleteVectorFromPinecone(id: idToDelete)
            handleDeletionSuccess(idToDelete: idToDelete)
        }
    }
    
    private func handleDeletionSuccess(idToDelete: String) {
        
        pineconeManager.deleteVector(withId: idToDelete)
        pineconeManager.resetAfterSuccessfulUpserting()
        pineconeManager.refreshNamespacesIDs()
        showSuccess = true
        inProgress = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            showSuccess = false
            inProgress = false
            buttonIsVisible = true
        }
        //        lottieAnimationID = UUID()
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
                VStack {
                    if buttonIsVisible {
                        Button(action:  {
                            if shake { return }
                            
                            if viewModel.description.isEmpty || (oldText == viewModel.description) {
                                withAnimation { shake = true }
                                return
                            }
                            withAnimation {
                                hideKeyboard()
                                self.viewModel.activeAlert = .editConfirmation
                                buttonIsVisible.toggle()
                            }
                        }) {
                            HStack(spacing: 12) {
                            Image(systemName: "cloud")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
                                .foregroundColor(.blue)
                            Text("Save")
                                .font(.system(size: 18, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.blue)
                                .accessibility(label: Text("Securely save this edited information to the cloud"))
                                .accessibility(hint: Text("This will store your data securely."))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                           LinearGradient(
                                               gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.4)]),
                                               startPoint: .top,
                                               endPoint: .bottom
                                           )
                                       )
                        )
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(ShakeEffect(animatableData: shakeOffset))
                        .padding(.top, 12)
                        .padding(.horizontal)
                        .animation(.easeInOut, value: keyboardResponder.currentHeight)
                        .id("SubmitButton")
                        .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
                    }
                    
                    else if shouldShowLoading  && pineconeManager.pineconeError == nil {
                        LoadingTransitionView(isUpserting: $inProgress, isSuccess: $showSuccess)
                            .frame(width: isIPad() ? 440 : 220, height: isIPad() ? 440 : 220)
                            .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                    removal: .opacity))
                    }
                } .animation(.easeInOut(duration: 0.5), value: shouldShowLoading)
                Spacer()
            }
            .padding(.horizontal, Constants.standardCardPadding)
            .padding(.top, 12)
        }
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
