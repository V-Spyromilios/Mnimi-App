////
//// QuestionView.swift
//// MyndVault
////
//// Created by Evangelos Spyromilios on 25.04.24.
////
//
//import SwiftUI
//import CloudKit
//import EventKit
//
//struct QuestionView: View {
//    
//    @EnvironmentObject var openAiManager: OpenAIViewModel
//    @EnvironmentObject var pineconeManager: PineconeViewModel
//    @EnvironmentObject var keyboardResponder: KeyboardResponder
//    @EnvironmentObject var cloudKitManager: CloudKitViewModel
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject var networkManager: NetworkManager
//    @EnvironmentObject var apiCalls: ApiCallViewModel
//    @EnvironmentObject var languageSettings: LanguageSettings
//
//    @State private var question: String = ""
//    @State private var thrownError: String = ""
//    @State private var goButtonIsVisible: Bool = true
//    @State private var showNoInternet = false
//    @State private var fetchedImages: [UIImage] = []
//    @State private var isLoading: Bool = false
////    @State private var showLang: Bool = false
//    @State private var showError: Bool = false
//    @State private var isTextFieldEmpty: Bool = true
//    @State private var showSettingsAlert: Bool = false
//    @State private var recordingURL: URL?
//    @FocusState private var isFocused: Bool
//    @State private var intentResponseIsRunning: Bool = false
//    @StateObject private var questionAudioRecorder: AudioRecorder = AudioRecorder()
//    @State private var isProcessingAudio: Bool = false
//    @State private var onReminderSuccess: Bool = false
//    @State private var showRecordPopup: Bool = false
//    private var shouldShowGoButton: Bool {
//        goButtonIsVisible &&
//        openAiManager.stringResponseOnQuestion.isEmpty &&
//        pineconeManager.pineconeErrorFromQ == nil
//    }
//    
//    private var shouldShowProgressView: Bool {
//        !goButtonIsVisible &&
//        thrownError.isEmpty &&
//        pineconeManager.pineconeErrorFromQ == nil &&
//        isLoading
//    }
//    private var hasResponse: Bool {
//        !openAiManager.stringResponseOnQuestion.isEmpty
//    }
//    
//    enum ActiveModal: Identifiable {
//        case error(String)
//        case fullImage(UIImage)
//        case calendar
//        case calendarPermission
//        
//        var id: String {
//            switch self {
//            case .error(let message): return "error_\(message)"
//            case .fullImage: return "fullImage"
//            case .calendar: return "calendar"
//            case .calendarPermission: return "calendarPermission"
//            }
//        }
//    }
//    @State private var activeModal: ActiveModal?
//    @State private var selectedEvent: EKEvent?
//    
//    var body: some View {
//        NavigationStack {
//            GeometryReader { geometry in
//
//                ZStack {
//                    
//                    LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
//                        .opacity(0.4)
//                        .ignoresSafeArea()
//                    
//                    ScrollView {
//                        
//                        HStack {
//                            Image(systemName: "bubble.left.and.text.bubble.right").bold()
//                            Text("Instruction").bold()
//                            //                        if showLang {
//                            Text("\(languageSettings.selectedLanguage.displayName)")
//                                .foregroundStyle(.gray)
//                                .padding(.leading, 8)
//                                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                                        removal: .opacity))
//                            //                                .animation(.easeInOut(duration: 0.5), value: showLang)
//                            //                        }
//                            Spacer()
//                        }
//                        .font(.callout)
//                        .padding(.top, 12)
//                        .padding(.bottom, 8)
//                        .padding(.horizontal, Constants.standardCardPadding)
//                        
//                        TextEditor(text: $question)
//                            .fontDesign(.rounded)
//                            .font(.title2)
//                            .multilineTextAlignment(.leading)
//                            .frame(height: Constants.textEditorHeight)
//                            .clipShape(RoundedRectangle(cornerRadius: 10))
//                            .shadow(color: isFocused ? Color.blue.opacity(0.5) : Color.blue.opacity(0.4),
//                                    radius: isFocused ? 3 : 2,
//                                    x: isFocused ? 4 : 2,
//                                    y: isFocused ? 4 : 2)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 10)
//                                    .stroke(isFocused ? Color.blue.opacity(0.5) : Color.gray.opacity(0.5), lineWidth: 1)
//                            )
//                            .onTapGesture {
//                                isFocused = true
//                            }
//                            .focused($isFocused)
//                            .padding(.bottom)
//                            .padding(.horizontal, Constants.standardCardPadding)
//                            .onChange(of: question) { _, newValue in
//                                isTextFieldEmpty = newValue.count < 8
//                            }
//                        VStack {
//                            ZStack {
//                                if shouldShowGoButton {
//                                    GoButton
//                                        .padding(.bottom)
//                                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                                                removal: .opacity))
//                                    
//                                } else if shouldShowProgressView {
//                                    LoadingTransitionView(isUpserting: $isLoading, isSuccess: .constant(false))
//                                        .frame(width: isIPad() ? 440 : 220, height: isIPad() ? 440 : 220)
//                                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                                                removal: .opacity))
//                                    
//                                }
//                            }
//                            .animation(.easeInOut(duration: 0.5), value: shouldShowProgressView)
//                            
//                            if hasResponse {
//                                Group {
//                                    ResponseView
//                                    //                                    .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                    //                                                            removal: .opacity))
//                                    //                                    .animation(.easeInOut(duration: 0.5), value: hasResponse)
//                                    
//                                    if self.thrownError == "" && hasResponse {
//                                        ClearButton
//                                            .padding(.horizontal)
//                                            .padding(.bottom)
//                                        //                                        .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                        //                                                                removal: .opacity))
//                                        //                                        .animation(.easeInOut(duration: 0.5), value: hasResponse)
//                                    }
//                                }
//                                .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
//                                                        removal: .opacity))
//                                .animation(.easeInOut(duration: 0.5), value: hasResponse) //TODO: Check if transitions smoothly
//                            }
//                        }
//                    }
//                    .background(Color.clear)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .topBarTrailing) {
//                            if keyboardResponder.currentHeight > 0 {
//                                Button {
//                                    hideKeyboard()
//                                } label: {
//                                    HideKeyboardLabel()
//                                }
//                                .padding(.top, isIPad() ? 15: 0)
//                            }
//                        }
//                    }
//                    .sheet(item: $activeModal) { activeItem in
//                        switch activeItem {
//                        case .error(let message):
//                            ErrorView(thrownError: message) {
//                                performClearTask()
//                                activeModal = nil
//                            }
//                            .presentationDetents([.fraction(0.4)])
//                            .presentationDragIndicator(.hidden)
//                            .presentationBackground(Color.clear)
//
//                        case .fullImage(let image):
//                            FullScreenImage(image: image)
//                                .presentationDragIndicator(.hidden)
//                                .presentationBackground(Color.clear)
//                                .onTapGesture { activeModal = nil }
//                                .statusBarHidden()
//
//                        case .calendar:
//                            calendarSheetContent()
//                        case .calendarPermission:
//                            VStack(spacing: 16) {
//                                Text("❌ Calendar Access Denied")
//                                    .font(.title)
//                                    .foregroundColor(.red)
//
//                                Text("MyndVault needs access to your calendar to schedule events when you want to.")
//                                    .multilineTextAlignment(.center)
//                                    .padding(.horizontal)
//
//                                Button("Open Settings") {
//                                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                                        UIApplication.shared.open(url)
//                                    }
//                                }
//                                .buttonStyle(.borderedProminent)
//
//                                Button("Cancel") {
//                                    activeModal = nil
//                                }
//                                .buttonStyle(.bordered)
//                            }
//                            .padding()
//                        }
//                    }
//                    //                .onChange(of: languageSettings.selectedLanguage) { _, newValue in
//                    //                    showLang = true
//                    //                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.showLangDuration) {
//                    //                        showLang = false
//                    //                    }
//                    //                }
//                    .onChange(of: openAiManager.gptResponseError) { _, newValue in
//                        if let error = newValue {
//                            self.isLoading = false
//                            activeModal = .error(error.localizedDescription)
//                        }
//                    }
//                    .onChange(of: pineconeManager.pineconeErrorFromQ) { _, newValue in
//                        if let error = newValue {
//                            self.isLoading = false
//                            activeModal = .error(error.localizedDescription)
//                        }
//                    }
//                    .onChange(of: recordingURL) { _, url in
//                        guard let url = url else { return }
//                        
//                        question = ""
//                        goButtonIsVisible = true
//                        thrownError = ""
//                        openAiManager.stringResponseOnQuestion = ""
//                        Task {
//                            await openAiManager.processAudio(fileURL: url, fromQuestion: true)
//                        }
//                    }
//                    .onChange(of: openAiManager.transcriptionForQuestion) {_, transcript in
//                        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                            Task {
//                                await openAiManager.getTranscriptAnalysis(transcrpit: transcript)
//                            }
//                        } else {
//                            debugLog("⚠️ Transcription was empty. Aborting flow.")
//                                   isLoading = false
//                                   isProcessingAudio = false
//                                   showRecordPopup = false
//                        }
//                    }
//                    .onChange(of: openAiManager.stringResponseOnQuestion) { _, newValue in
//                        if !newValue.isEmpty {
//                        debugLog("stringResponseOnQuestion, setting isLoading to false")
//                            isLoading = false
//                            intentResponseIsRunning = false
//                            isProcessingAudio = false
//                            showRecordPopup = false
//                            
////                            goButtonIsVisible = true
//                            //MARK: HERE
//                        }
//                    }
//                    .onChange(of: pineconeManager.pineconeQueryResponse) { _, newValue in
//                        if let pineconeResponse = newValue {
//                            handlePineconeResponse(pineconeResponse)
//                        }
//                    }
////                    .onChange(of: openAiManager.questionEmbeddingsCompleted) { _, newValue in
////                        debugLog("OnChange :: handleQuestionEmbeddingsCompleted : \(newValue)")
////                        if newValue {
////                            handleQuestionEmbeddingsCompleted()
////                        }
////                    }
//                    .onChange(of: openAiManager.questionEmbeddingTrigger) {
//                        handleQuestionEmbeddingsCompleted()
//                    }
//                    .onChange(of: openAiManager.transriptionErrorForQuestion) { _, error in
//                        guard let error = error else { return }
//                        Task {
//                            await handleError(error)
//                        }
//                    }
//                    .onChange(of: openAiManager.openAIErrorFromQuestion) {_, error in
//                        guard let error = error else { return }
//                        Task {
//                            await handleError(error)
//                        }
//                    }
//                    .navigationBarTitleView {
//                        HStack {
//                            Text("Assistant").font(.headline).bold().foregroundStyle(.blue.opacity(0.8)).fontDesign(.rounded).padding(.trailing, 5)
//                                .minimumScaleFactor(0.8)
//                                .lineLimit(2)
//                            LottieRepresentableNavigation(filename: "robotForQuestion").frame(width: 55, height: 55).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
//                        }.padding(.top, isIPad() ? 15: 0)
//                    }
//                    .alert(isPresented: $showNoInternet) {
//                        Alert(
//                            title: Text("You are not connected to the Internet"),
//                            message: Text("Please check your connection"),
//                            dismissButton: .cancel(Text("OK"))
//                        )
//                    }
//                    .onChange(of: networkManager.hasInternet) { _, hasInternet in
//                        if !hasInternet {
//                            showNoInternet = true
//                            if isLoading {
//                                performClearTask()
//                            }
//                        }
//                    }
//                    
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            if !isLoading && keyboardResponder.currentHeight <= 0 {
//                                RecordButton(
//                                    onPressBegan: { print("🎤 Recording started!") },
//                                    onPressEnded: { print("🛑 Recording ended!") },
//                                    onConfirmRecording: { url in
//                                        guard FileManager.default.fileExists(atPath: url.path) else {
//                                            print("⚠️ Recording file does not exist at \(url)")
//                                            return
//                                        }
//                                        self.recordingURL = url
//                                    },
//                                    showAlert: $showSettingsAlert,
//                                    isProcessing: $isProcessingAudio,
//                                    showPopup: $showRecordPopup,
//                                    audioRecorder: questionAudioRecorder,
//                                    showReminderSuccess: $onReminderSuccess
//                                )
//                                .padding(.bottom, geometry.safeAreaInsets.bottom)
//                                .padding(.trailing, Constants.standardCardPadding * 2)
//                                .ignoresSafeArea(.keyboard, edges: .bottom)
//                                .transition(.opacity.combined(with: .scale))
//                            }
//                        }
//                    }
//                    .animation(.easeInOut, value: isLoading)
//                    .onChange(of: openAiManager.calendarEvent) { _, newEvent in
//                        guard let newEvent = newEvent else {
//                            debugLog("onChange(of: openAiManager.calendarEvent) RETURNED")
//                            return
//                        }
//                        debugLog("New calendar event observed by the view!")
//                        isLoading = false
//                        intentResponseIsRunning = false
//                        isProcessingAudio = false
//                        showRecordPopup = false
//                        openAiManager.intentResponse = nil
//                        selectedEvent = newEvent
//                        activeModal = .calendar
//                    }
//                    .onChange(of: openAiManager.reminderCreated) { _, success in
//                        if success {
//                            intentResponseIsRunning = false
//                            isProcessingAudio = false
//                            onReminderSuccess = true
//
//                            openAiManager.intentResponse = nil
//                            openAiManager.reminderCreated = false
//                            isLoading = false
//                        }
//                    }
//                    .onChange(of: openAiManager.reminderError) {_, error in
//                        
//                        guard let error = error else { return }
//                            Task {
//                                await self.handleError(error)
//                            }
//                    }
//                    .onChange(of: openAiManager.intentResponse) {_, response in
//                        
//                        guard let response = response else { return }
//                        guard response.type != "unknown", !response.type.isEmpty else {
//                            debugLog("⚠️ openAiManager.intentResponse.type was nil. Aborting flow.")
//                            isLoading = false
//                            isProcessingAudio = false
//                            showRecordPopup = false
//                            return
//                        }
//                        processIntent(response)
//                    }
//                    .onChange(of: openAiManager.showCalendarPermissionAlert) {_, alert in
//                            if alert {
//                                activeModal = .calendarPermission
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private func calendarSheetContent() -> some View {
//        CalendarEventEditorView(
//            eventStore: openAiManager.eventStore,
//            event: selectedEvent,
//            onDismiss: {
//                openAiManager.calendarEvent = nil
//                selectedEvent = nil
//                activeModal = nil
//            }, isLoading: $isLoading
//        )
//    }
//    
//    @ViewBuilder
//    private var ResponseView: some View {
//        HStack {
//            Image(systemName: "quote.bubble").bold()
//            Text("Reply").bold()
//            Spacer()
//        }
//        .font(.callout)
//        .padding(.top, 12)
//        .padding(.bottom, 8)
//        .padding(.horizontal, Constants.standardCardPadding)
//        
//        ZStack {
//            RoundedRectangle(cornerRadius: 10.0)
//                .stroke(lineWidth: 1)
//                .opacity(colorScheme == .light ? 0.3 : 0.7)
//            
//            Text(openAiManager.stringResponseOnQuestion)
//                .fontDesign(.rounded)
//                .font(.title2)
//                .multilineTextAlignment(.leading)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(7)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(lineWidth: 1)
//                        .opacity(colorScheme == .light ? 0.3 : 0.7)
//                        .foregroundColor(Color.gray)
//                )
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(colorScheme == .light ? Color.white : Color.black)
//                        .shadow(color: Color.black, radius: colorScheme == .light ? 5 : 3)
//                )
//        }
//        .padding(.bottom)
//        .padding(.horizontal, Constants.standardCardPadding)
//        
//        ImageGridView
//    }
//    
//    @ViewBuilder
//    private var ImageGridView: some View {
//        LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
//            ForEach(0..<fetchedImages.count, id: \.self) { index in
//                ImageView(
//                    index: index,
//                    image: fetchedImages[index],
//                    activeModal: $activeModal
//                )
//            }
//        }
//    }
//    
//    private func handleQuestionEmbeddingsCompleted() {
//        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
//        //apiCalls.incrementApiCallCount()
//    }
//    
//    private var ClearButton: some View {
//        Button(action: performClearTask) {
//            
//            HStack(spacing: 12) {
//                Image(systemName: "arrow.uturn.backward")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(height: 24)
//                    .foregroundColor(.blue)
//                Text("OK")
//                    .font(.system(size: 18, weight: .bold))
//                    .fontDesign(.rounded)
//                    .foregroundColor(.blue)
//                    .accessibility(label: Text("reset the question and reply"))
//                    .accessibility(hint: Text("This will reset your question and reply text fields"))
//            }
//            .padding()
//            .frame(maxWidth: .infinity)
//            .frame(height: Constants.buttonHeight)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.4)]),
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//            )
//            
//        }
//        .padding(.top, 12)
//        .padding(.bottom, 12)
//        .padding(.horizontal)
//        .frame(maxWidth: .infinity)
//    }
//    
//    private var GoButton: some View {
//        
//        CoolButton(title: String(localized: "goButtonTitle"), systemImage: "paperplane.circle.fill", action: performTask)
//            .padding(.top, 12)
//            .padding(.horizontal)
//            .padding(.horizontal)
//            .frame(maxWidth: .infinity)
//            .opacity(isTextFieldEmpty ? 0.5 : 1.0)
////            .disabled(isTextFieldEmpty)
//            .accessibility(label: Text("Ask Question"))
//            .accessibility(hint: Text("This will query the database and return a reply"))
//    }
//    
//    private func performClearTask() {
//        
//        withAnimation(.easeInOut(duration: 0.3)) {
//            self.question = ""
//            self.thrownError = ""
//            activeModal = .none
//            fetchedImages = []
//            self.goButtonIsVisible = true
//            if isLoading { isLoading = false }
//            
//        }
//        openAiManager.clearManager()
//        pineconeManager.clearManager()
//    }
//    
//    private func processIntent(_ intent: IntentClassificationResponse) {
//        
//        debugLog("Started processIntetn: \(intent.type)")
//        debugLog("is on main thread: \(Thread.isMainThread)")
//        debugLog(" processIntetn: about to call openAiManager.handleClassifiedIntent()")
//        openAiManager.handleClassifiedIntent(intent)
//    }
//    
//    //TIP: .onChange requires the type to conform to Equatable !!
//    
//    private func performTask() {
//        
//        guard !isLoading else { return }
//
//        if isTextFieldEmpty {
//            self.thrownError = String(localized: "8charsErrorMessage.")
//            activeModal = .error(thrownError)
//            return
//        }
//
//        withAnimation(.easeInOut) {
//            goButtonIsVisible = false
//            hideKeyboard()
//            isLoading = true
//        }
//        Task {
//            await openAiManager.getTranscriptAnalysis(transcrpit: question)
////            do {
////                try await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
////            }
////            catch {
////                await handleError(error)
////            }
//        }
//    }
//    
//    private func handleError(_ error: Error) async {
//        debugLog("handleError called with error: \(error)")
//
//        if activeModal != nil { return }
//        if isProcessingAudio { isProcessingAudio = false}
//        if showRecordPopup { showRecordPopup = false }
//
//        
//        intentResponseIsRunning = false
//        openAiManager.intentResponse = nil
//        
//        await MainActor.run {
//            withAnimation(.easeInOut) {
//                isLoading = false
//            }
//            
//            if let networkError = error as? AppNetworkError {
//                self.thrownError = networkError.errorDescription
//            } else if let ckError = error as? AppCKError {
//                self.thrownError = ckError.errorDescription
//            } else if let cloudKitError = error as? CKError {
//                self.thrownError = cloudKitError.customErrorDescription
//            } else {
//                self.thrownError = error.localizedDescription
//            }
//            
//            activeModal = .error(thrownError)
//        }
//    }
//    
//    private func handlePineconeResponse(_ pineconeResponse: PineconeQueryResponse) {
//        for match in pineconeResponse.matches {
//            let id = match.id
//            Task {
//                if openAiManager.intentResponse?.type == "is_question" {
//                    let userQuestion = openAiManager.intentResponse?.query ?? ""
//                debugLog("User question from Voice over: \(userQuestion), calling getGptResponse")
//                    await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: userQuestion)
//                }
//                else if self.question != "" {
//                debugLog("handlePineconeResponse for question: \(question)")
//                    await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: question)
//                }
//                else {
//                    debugLog("type: \(String(describing: openAiManager.intentResponse?.type))\nquery: \(openAiManager.intentResponse?.query ?? "Default")")
//                }
//                
////                do {
////                    if let image = try await cloudKitManager.fetchImageItem(uniqueID: id) {
////                        await MainActor.run {
////                            fetchedImages.append(image)
////                        }
////                    }
////                } catch let error as AppNetworkError {
////                    await MainActor.run {
////                        self.thrownError = error.errorDescription
////                        self.activeModal = .error(thrownError)
////                    }
////                } catch let error as AppCKError {
////                    await MainActor.run {
////                        self.thrownError = error.errorDescription
////                        self.activeModal = .error(thrownError)
////                    }
////                }
////                catch let error as CKError {
////                    await MainActor.run {
////                        self.thrownError = error.customErrorDescription
////                        self.activeModal = .error(thrownError)
////                    }
////                }
////                catch {
////                    await MainActor.run {
////                        self.thrownError = error.localizedDescription
////                        self.activeModal = .error(thrownError)
////                    }
////                }
//            }
//        }
//    }
//    
//}
//struct CalendarEventEditorView: View {
//    let eventStore: EKEventStore
//    let event: EKEvent?
//    let onDismiss: () -> Void
//    @Binding var isLoading: Bool
//    
//    var body: some View {
//        Group {
//            if let event = event {
//                EventEditView(eventStore: eventStore, event: event, onDismiss: onDismiss)
//                    .onAppear {
//                        if isLoading {
//                            isLoading = false
//                        }
//                    }
//            } else {
//                Text("⚠️ No event available")
//            }
//        }
//    }
//}
//
//
//struct QuestionView_Previews: PreviewProvider {
//    static var previews: some View {
//        let cloudKit = CloudKitViewModel.shared
//        let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
//        let openAIActor = OpenAIActor()
//        let languageSettings = LanguageSettings.shared
//        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
//        let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
//        let networkManager = NetworkManager()
//        QuestionView()
//            .environmentObject(openAIViewModel)
//            .environmentObject(pineconeViewModel)
//            .environmentObject(KeyboardResponder())
//            .environmentObject(languageSettings)
//            .environmentObject(networkManager)
//            .environment(\.locale, Locale(identifier: "he"))
//    }
//}
