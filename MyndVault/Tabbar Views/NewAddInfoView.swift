//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI
import CloudKit

struct NewAddInfoView: View {
    @State private var newInfo: String = ""
    @State private var apiCallInProgress: Bool = false
    @State private var thrownError: String = ""
    @State private var showError: Bool = false
    
    @State private var saveButtonIsVisible: Bool = true
    @State private var showSettings: Bool = false
    
    @State private var isLoading: Bool = false //used just for the button
    @State private var shake: Bool = false
    @State private var showNoInternet: Bool = false
    @State private var showLang: Bool = false
    @State private var clearButtonIsVisible: Bool = false
    @State private var showSuccess: Bool = false
    @Binding var showConfetti: Bool
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @StateObject private var photoPicker = ImagePickerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var apiCalls: ApiCallViewModel
    @EnvironmentObject var languageSettings: LanguageSettings
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    
                    VStack {
                        
                        HStack {
                            Image(systemName: "plus.bubble").bold()
                            Text("info").bold()
                            if showLang { Text("\(languageSettings.selectedLanguage.displayName)").foregroundStyle(.gray).padding(.leading, 8)
                                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            }
                            Spacer()
                        }.font(.callout).padding(.top,12).padding(.bottom, 8)
                        
                        HStack {
                            TextEditor(text: $newInfo)
                                .background(Color.cardBackground)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                                .frame(height: Constants.textEditorHeight)
                                .frame(maxWidth: idealWidth(for: geometry.size.width))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10.0)
                                        .stroke(lineWidth: 1)
                                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                                        .foregroundColor(Color.gray)
                                )
                                .padding(.bottom)

                        }
                        Button(action: {
                            photoPicker.presentPicker()
                        }) {
                            HStack {
                                Image(systemName: photoPicker.selectedImage == nil ? "photo.badge.plus.fill" : "photo.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 35, height: 30)
                                    .foregroundStyle(Color.customTiel)
                                Text(photoPicker.selectedImage == nil ? "Add photo" : "Change photo")
                                Spacer()
                                if let image = photoPicker.selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                            .overlay(alignment: .center) {
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(lineWidth: 1)
                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                                    .foregroundColor(Color.gray)
                                            }
                                        Button(action: {
                                            withAnimation {
                                                photoPicker.selectedImage = nil
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Color.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
                        .background(colorScheme == .light ? Color.cardBackground : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
                                .foregroundColor(Color.gray)
                        )
                        .padding(.bottom)
                        
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
                                   Image(systemName: "gearshape.2")
                                        .frame(width: 45, height: 45)
                                        .padding(.bottom, 5)
                                        .opacity(0.8)
                                    .accessibilityLabel("Settings") }
                            }
                            
                        }
                        Spacer()
                    }
                    //                    .frame(height: geometry.size.height)
                    .padding(.horizontal, Constants.standardCardPadding)
                    .overlay {
                        if showConfetti {
                            LottieRepresentable(filename: "Confetti").frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
                        }
                    }
                    .sheet(isPresented: $photoPicker.isPickerPresented) {
                        PHPickerViewControllerRepresentable(viewModel: photoPicker)
                        
                    }
                    .onAppear {
                        if !showLang {
                            showLang.toggle() }
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                            withAnimation {
                                showLang.toggle() }
                        }
                    }
                    
                    //                    if self.thrownError != "" {
                    //                        ClearButton
                    //                            .offset(y: keyboardResponder.currentHeight > 0 ? 70 : 0)
                    //                    }
                    if saveButtonIsVisible && pineconeManager.receivedError == nil {
                        SaveButton
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                    }
                    if apiCallInProgress && thrownError == "" && pineconeManager.receivedError == nil {
                        
                        CircularProgressView(progressTracker: progressTracker).padding()
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        LottieRepresentable(filename: "Brain Configurations", loopMode: .playOnce, speed: 0.4)
                            .frame(width: 220, height: 220)
                            //.id(UUID())
                            .animation(.easeInOut, value: apiCallInProgress)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                    }
                    else if pineconeManager.upsertSuccesful && showSuccess {
                        
                        LottieRepresentable(filename: "Approved", loopMode: .playOnce).frame(height: 130).padding(.top, 15).id(UUID()).animation(.easeInOut, value: showSuccess)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                    withAnimation { showSuccess = false }
                                }
                            }
                    }
                        Spacer()
                        
                    }
                        .sheet(isPresented: $showError) {
                            
                            ErrorView(thrownError: thrownError, dismissAction: self.performClearTask)
                                .presentationDetents([.fraction(0.4)])
                                .presentationDragIndicator(.hidden)
                                .presentationBackground(Color.clear)
                                .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            
                        }
                        .background {
                            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                                .opacity(0.4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea()
                        }
                        
                        .navigationBarTitleView {
                            HStack {
                                Text("Add New Info").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                                LottieRepresentableNavigation(filename: "UploadingFile").frame(width: 45, height: 50).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) } //TODO: Check how it looks
                        }
                }
                
                .onChange(of: shake) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                shake = false }
                        }
                    }
                }
                .onChange(of: languageSettings.selectedLanguage) {
                    withAnimation {
                        showLang = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                        withAnimation {
                            showLang = false }
                    }
                }
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNoInternet = true
                    }
                }
                .onChange(of: thrownError) {
                    showError.toggle()
                }
                .alert(isPresented: $showNoInternet) {
                    Alert(
                        title: Text("You are not connected to the Internet"),
                        message: Text("Please check your connection"),
                        dismissButton: .cancel(Text("OK"))
                    )
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(showSettings: $showSettings)
            }
            .onDisappear {
                if thrownError != "" || pineconeManager.receivedError != nil {
                    performClearTask()
                }
            }
        }
        private var SaveButton: some View {
            Button(action: addNewInfoAction) {
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                        .fill(Color.customLightBlue)
                        .frame(height: Constants.buttonHeight)
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    Text("Save").font(.title2).bold().foregroundColor(Color.buttonText)
                        .accessibilityLabel("save")
                }
                .contentShape(Rectangle())
                
            }
            .frame(maxWidth: .infinity)
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
            .padding(.top, 12)
            .padding(.horizontal)
            .padding(.horizontal)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
        }
        
        private var ClearButton: some View {
            Button(action: performClearTask) {
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                        .fill(Color.customLightBlue)
                        .frame(height: Constants.buttonHeight)
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    
                    Text("OK").font(.title2).bold().foregroundColor(Color.buttonText)
                        .accessibilityLabel("clear")
                }
                .contentShape(Rectangle())
            }
            .padding(.top, 12)
            .padding(.horizontal)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
            .frame(maxWidth: .infinity)
        }
        
        private func performClearTask() {
            
            withAnimation {
                progressTracker.reset()
                self.thrownError = ""
                self.clearButtonIsVisible = false
                Task {
                    await openAiManager.clearManager()
                    await pineconeManager.clearManager()
                }
                self.apiCallInProgress = false
                self.saveButtonIsVisible = true
            }
        }
        
        private func addNewInfoAction() {
            
            if shake || isLoading { return }
            if newInfo.count < 5 {
                withAnimation { shake = true }
                return
            }
            isLoading = true
            hideKeyboard()
            self.saveButtonIsVisible = false
            self.apiCallInProgress = true
            progressTracker.reset()
            if pineconeManager.upsertSuccesful {
                pineconeManager.upsertSuccesful.toggle()
            }
            Task { await addInfoOperations() }
        }
    
    
        
        private func addInfoOperations() async {
            
            do {
                //MARK: TEST THROW
                //            let miaMalakia = AppCKError.UnableToGetNameSpace
                //            throw miaMalakia
                
                try await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
                
                if openAiManager.embeddingsCompleted {
                    apiCalls.incrementApiCallCount()
                    let metadata = toDictionary(desc: self.newInfo)
                    
                    let uniqueID = UUID().uuidString
                    
                    try await pineconeManager.upsertDataToPinecone(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata)
                    if pineconeManager.upsertSuccesful {
                        
                        apiCalls.incrementApiCallCount()
                        if let image = photoPicker.selectedImage {
                            try await cloudKit.saveImageItem(image: image, uniqueID: uniqueID)
                        }
                        showSuccess.toggle()
                    }
                    await MainActor.run {
                        apiCallInProgress = false
                        saveButtonIsVisible = true
                        newInfo = ""
                        isLoading = false
                    }
                }
            }
            catch let error as AppNetworkError {
                await MainActor.run {
                    apiCallInProgress = false
                    isLoading = false
                    self.thrownError = error.errorDescription }
            }
            catch let error as AppCKError {
                await MainActor.run {
                    apiCallInProgress = false
                    isLoading = false
                    self.thrownError = error.errorDescription }
            }
            catch let error as CKError {
                await MainActor.run {
                    apiCallInProgress = false
                    isLoading = false
                    self.thrownError = error.customErrorDescription }
            }
            catch {
                await MainActor.run {
                    apiCallInProgress = false
                    isLoading = false
                    self.thrownError = error.localizedDescription }
            }
        }
    }


struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        let progress = ProgressTracker()
        let openAI = OpenAIManager()
        let pinecone = PineconeManager()
        let networkManager = NetworkManager()
        let cloudKit = CloudKitViewModel()
        let apiCalls = ApiCallViewModel()
        let languageSettings = LanguageSettings()

        NewAddInfoView(showConfetti: .constant(true))
            .environmentObject(pinecone)
            .environmentObject(openAI)
            .environmentObject(progress)
            .environmentObject(responder)
            .environmentObject(networkManager)
            .environmentObject(cloudKit)
            .environmentObject(apiCalls)
            .environmentObject(languageSettings)
    }
}
