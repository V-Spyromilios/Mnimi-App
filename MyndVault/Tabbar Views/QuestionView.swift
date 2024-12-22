//
// QuestionView.swift
// MyndVault
//
// Created by Evangelos Spyromilios on 25.04.24.
//

import SwiftUI
import CloudKit

struct QuestionView: View {
    
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKitManager: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var apiCalls: ApiCallViewModel
    @EnvironmentObject var languageSettings: LanguageSettings
    
    @State private var question: String = ""
    @State private var thrownError: String = ""
    @State private var goButtonIsVisible: Bool = true
    @State private var selectedImageIndex: Int? = nil
    @State private var showNoInternet = false
    
    @State private var showFullImage: Bool = false
    @State private var showSettings: Bool = false
    @State private var fetchedImages: [UIImage] = []
    @State private var isLoading: Bool = false
    @State private var shake: Bool = false
    @State private var showLang: Bool = false
    @State private var showError: Bool = false
    @State private var clearButtonIsVisible: Bool = false
    
    private var shouldShowGoButton: Bool {
        goButtonIsVisible &&
        openAiManager.stringResponseOnQuestion.isEmpty &&
        pineconeManager.pineconeError == nil
    }
    
    private var shouldShowProgressView: Bool {
        !goButtonIsVisible &&
        progressTracker.progress < 0.99 &&
        progressTracker.progress > 0.1 &&
        thrownError.isEmpty &&
        pineconeManager.pineconeError == nil
    }
    private var hasResponse: Bool {
        !openAiManager.stringResponseOnQuestion.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                ScrollView {
                    
                    HStack {
                        Image(systemName: "questionmark.bubble").bold()
                        Text("Question").bold()
                        if showLang {
                            Text("\(languageSettings.selectedLanguage.displayName)")
                                .foregroundStyle(.gray)
                                .padding(.leading, 8)
                                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                        removal: .opacity))
                                .animation(.easeInOut(duration: 0.5), value: showLang)
                        }
                        Spacer()
                    }
                    .font(.callout)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .padding(.horizontal, Constants.standardCardPadding)
                    
                    TextEditor(text: $question)
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
                        .padding(.horizontal, Constants.standardCardPadding)
                        .onAppear {
                            if !showLang {
                                showLang.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                                    withAnimation {
                                        showLang.toggle()
                                    }
                                }
                            }
                        }
                    VStack {
                        ZStack {
                            if shouldShowGoButton {
                                GoButton
                                    .padding(.bottom)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
    
                            } else if shouldShowProgressView {
                                LoadingTransitionView(isUpserting: $isLoading, isSuccess: .constant(false))
                                    .frame(width: isIPad() ? 440 : 220, height: isIPad() ? 440 : 220)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
                                   
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: shouldShowProgressView)
                        
                        if hasResponse {
                            Group {
                                ResponseView
                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                            removal: .opacity))
                                    .animation(.easeInOut(duration: 0.5), value: hasResponse)
                                
                                if self.thrownError == "" && hasResponse {
                                    ClearButton
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                                removal: .opacity))
                                        .animation(.easeInOut(duration: 0.5), value: hasResponse)
                                }
                            }
                        }
                    }
                }
                .background(Color.clear)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if keyboardResponder.currentHeight > 0 {
                            Button {
                                hideKeyboard()
                            } label: {
                                HideKeyboardLabel()
                            }
                            .padding(.top, isIPad() ? 15: 0)
                        }
                        
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                                .frame(width: 45, height: 45)
                                .padding(.bottom, 5)
                                .padding(.top, isIPad() ? 15: 0)
                                .opacity(0.8)
                                .accessibilityLabel("settings")
                        }
                    }
                }
                .fullScreenCover(isPresented: $showFullImage) {
                    if let selectedImageIndex = self.selectedImageIndex {
                        FullScreenImage(show: $showFullImage, image: fetchedImages[selectedImageIndex])
                    } else {
                        Text("No Image Selected").bold()
                    }
                }
                .sheet(isPresented: $showError) {
                    ErrorView(thrownError: thrownError, dismissAction: self.performClearTask)
                        .presentationDetents([.fraction(0.4)])
                        .presentationDragIndicator(.hidden)
                        .presentationBackground(Color.clear)
                }
                .onChange(of: selectedImageIndex) { oldValue, newValue in
                    if newValue == nil {
                        showFullImage = false
                    }
                }
                .onChange(of: languageSettings.selectedLanguage) { _, newValue in
                    showLang = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                        showLang = false
                    }
                }
                .onChange(of: thrownError) {
                    showError.toggle()
                }
                .onChange(of: openAiManager.openAIError) { _, newValue in
                    if let error = newValue {
                        self.isLoading = false
                        self.thrownError = error.localizedDescription
                    }
                }
                .onChange(of: pineconeManager.pineconeError) { _, newValue in
                    if let error = newValue {
                        self.isLoading = false
                        self.thrownError = error.localizedDescription
                    }
                }
                .onChange(of: openAiManager.stringResponseOnQuestion) { _, newValue in
                    isLoading = false
                }
                .onChange(of: pineconeManager.pineconeQueryResponse) { _, newValue in
                    if let pineconeResponse = newValue {
                        handlePineconeResponse(pineconeResponse)
                    }
                }
                .onChange(of: openAiManager.questionEmbeddingsCompleted) { _, newValue in
                    if newValue {
                        handleQuestionEmbeddingsCompleted()
                    }
                }
                .onChange(of: shake) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shake = false
                        }
                    }
                }
                .navigationBarTitleView {
                    HStack {
                        Text("Ask me").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                        LottieRepresentableNavigation(filename: "robotForQuestion").frame(width: 55, height: 55).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                    }.padding(.top, isIPad() ? 15: 0)
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
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNoInternet = true
                        if isLoading {
                            performClearTask()
                        }
                    }
                }
                .onDisappear {
                    if thrownError != "" || pineconeManager.pineconeError != nil {
                        performClearTask()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var ResponseView: some View {
        HStack {
            Image(systemName: "quote.bubble").bold()
            Text("Reply").bold()
            Spacer()
        }
        .font(.callout)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.horizontal, Constants.standardCardPadding)
        
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .stroke(lineWidth: 1)
                .opacity(colorScheme == .light ? 0.3 : 0.7)
            
            Text(openAiManager.stringResponseOnQuestion)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1)
                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                        .foregroundColor(Color.gray)
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .light ? Color.white : Color.black)
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3)
                )
        }
        .padding(.bottom)
        .padding(.horizontal, Constants.standardCardPadding)
        
        ImageGridView
    }
    
    @ViewBuilder
    private var ImageGridView: some View {
        LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
            ForEach(0..<fetchedImages.count, id: \.self) { index in
                ImageView(
                    index: index,
                    image: fetchedImages[index],
                    selectedImageIndex: $selectedImageIndex,
                    showFullImage: $showFullImage
                )
            }
        }
    }
    
    @ViewBuilder
    private var ProgressViewContent: some View {

        LottieRepresentable(filename: "Ai Cloud", loopMode: .loop, speed: 0.8)
            .frame(height: isIPad() ? 440 : 300)
    }
    //...more function below

    
    private func handleQuestionEmbeddingsCompleted() {
        progressTracker.setProgress(to: 0.35)
        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
        apiCalls.incrementApiCallCount()
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                    .fill(Color.customLightBlue)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    .frame(height: Constants.buttonHeight)
                
                Text("OK").font(.title2).bold()
                    .fontDesign(.rounded)
                    .foregroundColor(Color.buttonText)
                    .accessibilityLabel("Clear and reset")
            }
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        .animation(.easeInOut, value: shake)
    }
    
    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                    .fill(Color.customLightBlue)
                    .frame(height: Constants.buttonHeight)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                Text("Go").font(.title2).bold()
                    .fontDesign(.rounded)
                    .foregroundColor(Color.buttonText)
                    .accessibilityLabel("Go")
            }
            .contentShape(Rectangle())
            
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        .animation(.easeInOut, value: shake)
    }
    
    private func performClearTask() {
        
        withAnimation(.easeInOut(duration: 0.4)) {
            self.question = ""
            self.thrownError = ""
            fetchedImages = []
            self.goButtonIsVisible = true
            progressTracker.reset()
            if isLoading { isLoading = false }
        }
        openAiManager.clearManager()
        pineconeManager.clearManager()
    }
    
    //TIP: .onChange requires the type to conform to Equatable !!
    
    private func performTask() {
        
        guard !shake && !isLoading else { return }
        
        if question.count < 8 {
            withAnimation(.easeOut) { shake = true }
            return
        }
        withAnimation(.easeOut) {
            goButtonIsVisible = false
            hideKeyboard()
            isLoading = true
            progressTracker.reset()
        }
        Task {
            do {
                try await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
            } catch {
                debugLog("\(error)")
            }
        }
        apiCalls.incrementApiCallCount()
    }
    
    private func handlePineconeResponse(_ pineconeResponse: PineconeQueryResponse) {
        for match in pineconeResponse.matches {
            let id = match.id
            Task {
                do {
                    if let image = try await cloudKitManager.fetchImageItem(uniqueID: id) {
                        await MainActor.run {
                            fetchedImages.append(image)
                        }
                    }
                } catch let error as AppNetworkError {
                    await MainActor.run {
                        self.thrownError = error.errorDescription
                    }
                } catch let error as AppCKError {
                    await MainActor.run {
                        self.thrownError = error.errorDescription
                    }
                }
                catch let error as CKError {
                    await MainActor.run {
                        self.thrownError = error.customErrorDescription
                    }
                }
                catch {
                    await MainActor.run {
                        self.thrownError = error.localizedDescription
                    }
                }
            }
        }
        Task {
            await openAiManager.getGptResponse(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
        }
        apiCalls.incrementApiCallCount()
    }
}


struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        let cloudKit = CloudKitViewModel.shared
        let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
        let openAIActor = OpenAIActor()
        
        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
        let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
        let progressTracker = ProgressTracker()
        
        QuestionView()
            .environmentObject(openAIViewModel)
            .environmentObject(pineconeViewModel)
            .environmentObject(progressTracker)
    }
}
