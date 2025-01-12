//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI
import CloudKit
import Combine

struct NewAddInfoView: View {
    
    let hapticGenerator = UINotificationFeedbackGenerator()
    @State private var newInfo: String = ""
    @State private var apiCallInProgress: Bool = false
    @State private var thrownError: String = ""
    @State private var showError: Bool = false
    @State private var saveButtonIsVisible: Bool = true
    @State private var showSettings: Bool = false
    @State private var isLoading: Bool = false // used just for the button
    @State private var showNoInternet: Bool = false
    @State private var showLang: Bool = false
    @State private var showSuccess: Bool = false
    @State private var isTextFieldEmpty: Bool = true

    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @StateObject private var photoPicker = ImagePickerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var apiCalls: ApiCallViewModel
    @EnvironmentObject var languageSettings: LanguageSettings
    @FocusState private var isFocused: Bool
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private var shouldShowLoading: Bool {
        apiCallInProgress || showSuccess
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        HStack {
                            Image(systemName: "plus.bubble").bold()
                            Text("info").bold()
                            if showLang {
                                Text("\(languageSettings.selectedLanguage.displayName)")
                                    .foregroundStyle(.gray)
//                                    .padding(.leading, 8)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
                            }
                            Spacer()
//#if DEBUG
//                            Text("Upsert Successful: \(pineconeManager.upsertSuccessful ? "Yes" : "No")")
//                                .foregroundColor(pineconeManager.upsertSuccessful ? .green : .red)
//                                .padding()
//                                .onTapGesture {
//                                    pineconeManager.upsertSuccessful.toggle()
//                                }
//#endif
                        }
                        .font(.callout)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
                        HStack {
                            TextEditor(text: $newInfo)
                                .background(Color.cardBackground)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                                .frame(height: Constants.textEditorHeight)
//                                .if(UIDevice.current.userInterfaceIdiom != .pad) { view in
//                                    view.frame(maxWidth: idealWidth(for: geometry.size.width))
//                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: isFocused ? Color.blue.opacity(0.8) : Color.blue.opacity(0.5),
                                        radius: isFocused ? 1 : 4,
                                        x: isFocused ? 6 : 4,
                                        y: isFocused ? 6 : 4) // Enhanced shadow on focus
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isFocused ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .onTapGesture {
                                    isFocused = true
                                }
                                .focused($isFocused)
                                .padding(.bottom)
                                .onChange(of: newInfo) { _, newValue in
                                    isTextFieldEmpty = newValue.count < 8
                                }
                        }
                        
                        // photo Picker Button
                        Button(action: {
                            photoPicker.presentPicker()
                        }) {
                            VStack(alignment: .center) {
                                if isIPad() {
                                    Image(systemName: photoPicker.selectedImage == nil ? "photo.badge.plus.fill" : "photo.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 80)
                                        .foregroundColor(.white)
                                        .background(Color.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                } else {
                                    Image(systemName: photoPicker.selectedImage == nil ? "photo.badge.plus.fill" : "photo.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(colorScheme == .light ? Color.customLightBlue : Color.darkModeImageBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                        .offset(x: 5)
                                }
                                if let image = photoPicker.selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: isIPad() ? 220 : 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                            .overlay(alignment: .center) {
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(lineWidth: 1)
                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                                    .foregroundColor(Color.gray)
                                            }
                                        
                                        // Remove image button
                                        Button(action: {
                                            withAnimation {
                                                photoPicker.selectedImage = nil
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                                .frame(width: isIPad() ? 30 : 20, height: isIPad() ? 30 : 20)
                                        }
                                        .offset(x: isIPad() ? 10 : 5, y: isIPad() ? -10 : -5)
                                    }
                                }
                            }
                        }
                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .background(colorScheme == .light ? Color.cardBackground : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: photoPicker.selectedImage == nil ? Color.blue.opacity(0.3) : Color.blue.opacity(0.5),
                                radius: photoPicker.selectedImage == nil ? 2 : 4,
                                x: photoPicker.selectedImage == nil ? 3 : 4,
                                y: photoPicker.selectedImage == nil ? 3 : 4) // Enhanced shadow on focus
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.bottom)
                        ZStack {
                            if saveButtonIsVisible && pineconeManager.pineconeError == nil {
                                SaveButton
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
                            } else if pineconeManager.pineconeError == nil && shouldShowLoading {
                                LoadingTransitionView(isUpserting: $apiCallInProgress, isSuccess: $showSuccess)
                                    .frame(width: isIPad() ? 440 : 220, height: isIPad() ? 440 : 220)
                                    .padding()
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: shouldShowLoading)
                        Spacer()
                    }
                    .padding(.horizontal, Constants.standardCardPadding)
                    
                    .sheet(isPresented: $photoPicker.isPickerPresented) {
                        PHPickerViewControllerRepresentable(viewModel: photoPicker)
                    }
                    .onAppear {
                        if !showLang {
                            showLang.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                            withAnimation {
                                showLang.toggle()
                            }
                        }
                    }
                    .sheet(isPresented: $showError) {
                        ErrorView(thrownError: thrownError, dismissAction: self.performClearTask)
                            .presentationDetents([.fraction(0.4)])
                            .presentationDragIndicator(.hidden)
                            .presentationBackground(Color.clear)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                    }
                    .navigationBarTitleView {
                        HStack {
                            Text("Add New Info").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                            LottieRepresentableNavigation(filename: "UploadingFile").frame(width: 45, height: 50).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                        }.padding(.top, isIPad() ? 15 : 0)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if keyboardResponder.currentHeight > 0 {
                            Button {
                                hideKeyboard()
                            } label: {
                                HideKeyboardLabel()
                            }
                        }
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .frame(width: 45, height: 45)
                                .padding(.bottom, 5)
                                .padding(.top, isIPad() ? 15 : 0)
                                .opacity(0.8)
                                .accessibilityLabel("Settings")
                        }
                    }
                }
                .onChange(of: languageSettings.selectedLanguage) {
                    withAnimation {
                        showLang = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                        withAnimation {
                            showLang = false
                        }
                    }
                }
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNoInternet = true
                    }
                }
                .onChange(of: thrownError) {
                    if !pineconeManager.accountDeleted {
                        if thrownError != "" {
                            showError = true
                        }
                        else {
                            showError = false
                        }
                    }
                }
                
                .onChange(of: pineconeManager.upsertSuccessful) { _, isSuccesful in
                    if isSuccesful {
                        withAnimation {
                            newInfo = ""
                            photoPicker.selectedImage = nil
                            apiCallInProgress = false
                            showSuccess = true
                            pineconeManager.refreshNamespacesIDs()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            saveButtonIsVisible = true
                            showSuccess = false
                            isLoading = false
                            hapticGenerator.notificationOccurred(.success)
                        }
                    }
                }
                .onChange(of: pineconeManager.pineconeError) { _, error in
                    if pineconeManager.accountDeleted != true {
                        if let error = error {
                            self.thrownError = error.localizedDescription
                            
                        }
                    }
                }
                .alert(isPresented: $showNoInternet) {
                    Alert(
                        title: Text("You are not connected to the Internet"),
                        message: Text("Please check your connection"),
                        dismissButton: .cancel(Text("OK"))
                    )
                }
                .fullScreenCover(isPresented: $showSettings) {
                    SettingsView(showSettings: $showSettings)
                }
                .onDisappear {
                    if !thrownError.isEmpty || pineconeManager.pineconeError != nil {
                        performClearTask()
                    }
                }
            }
        }
    }
}

// MARK: - Subviews and Helper Functions

extension NewAddInfoView {
    private var SaveButton: some View {

        CoolButton(title: "Save", systemImage: "cloud.circle.fill", action: addNewInfoAction)
        .padding(.top, 12)
        .padding(.horizontal)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
        .opacity(isTextFieldEmpty ? 0.5 : 1.0)
        .disabled(isTextFieldEmpty)
    }
    
    
    private func performClearTask() {
        withAnimation {
            self.thrownError = ""
            openAiManager.clearManager()
            pineconeManager.clearManager()
            self.apiCallInProgress = false
            self.saveButtonIsVisible = true
        }
    }
    
    private func addNewInfoAction() {

        if isLoading { return }
        isLoading = true
        hideKeyboard()
        self.saveButtonIsVisible = false
        self.apiCallInProgress = true
        if pineconeManager.upsertSuccessful {
            pineconeManager.upsertSuccessful.toggle()
        }
        Task {
            await startAddInfoProcess()
        }
    }
    
    private func startAddInfoProcess() async {
        // Clear any existing subscriptions
        cancellables.removeAll()
        
        do {
            // Request embeddings
            debugLog("startAddInfoProcess do {")
            try await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
            // Proceed to handle embeddings completed
            
            debugLog("startAddInfoProcess before handleEmbeddingsCompleted{")
            await handleEmbeddingsCompleted()
        } catch {
            // Handle error
            handleError(error)
        }
    }
    
    private func handleEmbeddingsCompleted() async {
        if openAiManager.embeddings.isEmpty {
            handleError(NSError(domain: "OpenAI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Embeddings are empty"]))
            return
        }
        
        apiCalls.incrementApiCallCount()
        let metadata = toDictionary(desc: self.newInfo)
        let uniqueID = UUID().uuidString
        
        
        pineconeManager.upsertData(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata)
        handleUpsertSuccess(uniqueID: uniqueID)
    }
    
    private func handleUpsertSuccess(uniqueID: String) {
        debugLog("handleUpsertSuccess Called")
        
        if let image = photoPicker.selectedImage {
            Task {
                do {
                    try await cloudKit.saveImageItem(image: image, uniqueID: uniqueID)
                    // Handle success if needed
                } catch {
                    handleError(error)
                    return
                }
            }
        }
        
        cancellables.removeAll()

    }
    
    private func handleError(_ error: Error) {
        
        debugLog("handleError called with error: \(error)")
        withAnimation {
            apiCallInProgress = false
            isLoading = false
            self.thrownError = error.localizedDescription
        }
        cancellables.removeAll()
    }
}


struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {

        let responder = KeyboardResponder()
        let networkManager = NetworkManager()
        let cloudKit = CloudKitViewModel.shared
        let apiCalls = ApiCallViewModel()
        let languageSettings = LanguageSettings.shared

        let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
        let openAIActor = OpenAIActor()

        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
        let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)

        NewAddInfoView()
            .environmentObject(pineconeViewModel)
            .environmentObject(openAIViewModel)
            .environmentObject(responder)
            .environmentObject(networkManager)
            .environmentObject(cloudKit)
            .environmentObject(apiCalls)
            .environmentObject(languageSettings)
    }
}
