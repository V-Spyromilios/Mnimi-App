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
    @State private var fetchedImages: [UIImage] = []
    @State private var isLoading: Bool = false
    @State private var showLang: Bool = false
    @State private var showError: Bool = false
    @State private var clearButtonIsVisible: Bool = false
    @State private var isTextFieldEmpty: Bool = true
    @FocusState private var isFocused: Bool
    
    private var shouldShowGoButton: Bool {
        goButtonIsVisible &&
        openAiManager.stringResponseOnQuestion.isEmpty &&
        pineconeManager.pineconeErrorFromQ == nil
    }
    
    private var shouldShowProgressView: Bool {
        !goButtonIsVisible &&
        thrownError.isEmpty &&
        pineconeManager.pineconeErrorFromQ == nil &&
        isLoading
    }
    private var hasResponse: Bool {
        !openAiManager.stringResponseOnQuestion.isEmpty
    }
    
    enum ActiveModal: Identifiable {
        case error(String)
        case fullImage(UIImage)
        
        var id: String {
            switch self {
            case .error(let message): return "error_\(message)"
            case .fullImage: return "fullImage"
            }
        }
    }
    @State private var activeModal: ActiveModal?
    
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
                        }//TODO: Add the text should not be empty or smth
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
                        .onChange(of: question) { _, newValue in
                            isTextFieldEmpty = newValue.count < 8
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
                    }
                }
                .sheet(item: $activeModal) { activeItem in
                    switch activeItem {
                    case .error(let message):
                        ErrorView(thrownError: message) {
                            activeModal = nil
                            performClearTask()
                        }
                        .presentationDetents([.fraction(0.4)])
                        .presentationDragIndicator(.hidden)
                        .presentationBackground(Color.clear)
                    case .fullImage(let image):
                        FullScreenImage(image: image)
                            .presentationDragIndicator(.hidden)
                            .presentationBackground(Color.clear)
                            .onTapGesture {
                                activeModal = nil
                            }
                            .statusBarHidden()
                    }
                }
                .onChange(of: languageSettings.selectedLanguage) { _, newValue in
                    showLang = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
                        showLang = false
                    }
                }
                .onChange(of: openAiManager.openAIError) { _, newValue in
                    if let error = newValue {
                        self.isLoading = false
                        activeModal = .error(error.localizedDescription)
                    }
                }
                .onChange(of: pineconeManager.pineconeErrorFromQ) { _, newValue in
                    if let error = newValue {
                        self.isLoading = false
                        activeModal = .error(error.localizedDescription)
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
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNoInternet = true
                        if isLoading {
                            performClearTask()
                        }
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
                    activeModal: $activeModal
                )
            }
        }
    }
    
    private func handleQuestionEmbeddingsCompleted() {
        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
        apiCalls.incrementApiCallCount()
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            
            HStack(spacing: 12) {
                Image(systemName: "arrow.uturn.backward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                    .foregroundColor(.blue)
                Text("OK")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.blue)
                    .accessibility(label: Text("reset the question and reply"))
                    .accessibility(hint: Text("This will reset your question and reply text fields"))
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
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    private var GoButton: some View {
        
        CoolButton(title: "Go", systemImage: "paperplane.circle.fill", action: performTask)
            .padding(.top, 12)
            .padding(.horizontal)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .opacity(isTextFieldEmpty ? 0.5 : 1.0)
            .disabled(isTextFieldEmpty)
            .accessibility(label: Text("Ask Question"))
            .accessibility(hint: Text("This will query the database and return a reply"))
    }
    
    private func performClearTask() {
        
        withAnimation(.easeInOut(duration: 0.4)) {
            self.question = ""
            self.thrownError = ""
            fetchedImages = []
            self.goButtonIsVisible = true
            if isLoading { isLoading = false }
        }
        openAiManager.clearManager()
        pineconeManager.clearManager()
    }
    
    //TIP: .onChange requires the type to conform to Equatable !!
    
    private func performTask() {
        
        guard !isLoading else { return }
        
        if question.count < 8 {
            return
        }
        withAnimation(.easeInOut) {
            goButtonIsVisible = false
            hideKeyboard()
            isLoading = true
        }
        Task {
            do {
                try await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
            }
            catch {
                await handleError(error)
            }
        }
        apiCalls.incrementApiCallCount()
    }
    
    private func handleError(_ error: Error) async {
        
        debugLog("handleError called from QuestionView with error: \(error)")
        withAnimation(.easeInOut) {
            isLoading = false
        }
        
        Task {
            await MainActor.run {
                if let networkError = error as? AppNetworkError {
                    self.thrownError = networkError.errorDescription
                    activeModal = .error(thrownError)
                } else if let ckError = error as? AppCKError {
                    self.thrownError = ckError.errorDescription
                    activeModal = .error(thrownError)
                } else if let cloudKitError = error as? CKError {
                    self.thrownError = cloudKitError.customErrorDescription
                    activeModal = .error(thrownError)
                } else {
                    self.thrownError = error.localizedDescription
                    activeModal = .error(thrownError)
                }
            }
        }
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
            await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: question)
        }
        apiCalls.incrementApiCallCount()
    }
}


struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        let cloudKit = CloudKitViewModel.shared
        let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
        let openAIActor = OpenAIActor()
        let languageSettings = LanguageSettings.shared
        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
        let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
        let networkManager = NetworkManager()
        QuestionView()
            .environmentObject(openAIViewModel)
            .environmentObject(pineconeViewModel)
            .environmentObject(KeyboardResponder())
            .environmentObject(languageSettings)
            .environmentObject(networkManager)
    }
}
