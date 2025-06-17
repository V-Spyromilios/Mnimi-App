//
//  KView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 12.04.25.
//
/*
 ✅ Final UX Summary
 Input                                  Detected by GPT             Action Taken
 
 what is my license plate again?â€         is_question              Search Pinecone -> GPT response -> .response
 Remind me to call mom tonight              is_reminder             Create reminder, show visual success
 Add lunch with Leo Friday 12              is_calendar              Use EventEditView to create event
 My license plate is AB123              (default -> save info)      Save to Pinecone as embedding
 
 
 Font Size      Recommended Line Spacing
 17                 4
 18                 5
 20                 7
 22                 8
 
 */

import SwiftUI
import EventKit
import SwiftData

struct KView: View {
    
    enum ViewState: Equatable {
        case idle
        case input
        case response
        case onApiCall
        case onSuccess
        case onError(AnyDisplayableError)
        
        static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.input, .input), (.response, .response),
                (.onApiCall, .onApiCall), (.onSuccess, .onSuccess):
                return true
            case (.onError(let e1), .onError(let e2)):
                return e1.id == e2.id
            default:
                return false
            }
        }
    }
    @Binding var launchURL: URL?
    
    @State private var viewState: ViewState = .idle
    @State private var selectedImage: String = ""
    @State private var text: String = ""
    @State private var recordingURL: URL?
    @FocusState private var isEditorFocused: Bool
    @EnvironmentObject var audioRecorder: AudioRecorder
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @EnvironmentObject var usageManager: ApiCallUsageManager
    @State private var micColor: Color = .white
    @State private var viewTransitionDelay: Double = 0.4
    @State private var viewTransitionDuration: Double = 0.4
    @Binding var showVault: Bool
    @State private var showSettings: Bool = false
    @State private var showPaywall: Bool = false
    
    @AppStorage("microphonePermissionGranted") var micGranted: Bool?
    
#if DEBUG
    @State var currentIndex: Int = 0
#endif
    
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geo in
                if viewState == .idle {
                    Image(selectedImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .clipped()
                    
#if DEBUG
                    Button(action: {
                        //                       showNextImage()
                        showPaywall.toggle()
                        print("Image: \(selectedImage)")
                    }) {
                        Text("Paywall")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                    .zIndex(3)
                    
#endif
                }
                
//                ScrollView {
                    VStack {
                        if viewState != .idle {
                            InputView(
                                kViewState: $viewState, text: $text,
                                isEditorFocused: _isEditorFocused,
                                geometry: geo,
                                showPaywall: $showPaywall, delay: $viewTransitionDelay,
                                duration: $viewTransitionDuration
                            )
                            .ignoresSafeArea(.keyboard, edges: .all)
                            .transition(.opacity)
                            .frame(height: geo.size.height)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
//                    Spacer()
//                }
//                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                //                .frame(width: geo.size.width)
                .zIndex(0)
                .allowsHitTesting(!(showSettings || showVault)) // disable interaction
            }
            .ignoresSafeArea(.keyboard, edges: .all)
            .onAppear {
                selectedImage = imageForToday()
                if let uiImage = UIImage(named: selectedImage) {
                    let brightness = bottomTrailingBrightness(of: uiImage)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        micColor = brightness > 0.6 ? .black : .white
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                CustomPaywallView {
                    showPaywall = false
                }
                
            }
            .onChange(of: recordingURL) { _, url in
                if let url {
                    Task {
                        await openAiManager.processAudio(fileURL: url, fromQuestion: true)
                    }
                }
            }
            .onChange(of: openAiManager.transcriptionFromWhisper) { _, newTranscript in
                guard !newTranscript.isEmpty else { return }
                text = newTranscript
                showInputView()
                audioRecorder.deleteAudioAndUrl()
                recordingURL = nil
                usageManager.trackApiCall()
            }
            //MARK: For the Widget
            .onChange(of: launchURL) { _, url in
                guard let url = url else { return }
                if url.scheme == "mnimi", url.host == "add" {
                    print("🚀 Triggering input mode from widget")
                    viewState = .input
                    launchURL = nil // Reset after handling
                }
            }
            
            if let micGranted = micGranted, micGranted == true {
                KRecordButton(recordingURL: $recordingURL, audioRecorder: audioRecorder, micColor: $micColor)
                    .opacity((viewState == .idle && !(showSettings || showVault)) ? 1 : 0)
                    .allowsHitTesting(viewState == .idle && !(showSettings || showVault)) // prevent interaction while overlays are shown
                    .padding(.trailing, 20)
                    .padding(.bottom, 140)
            }
            
            // MARK: - Drag gesture layers
            vaultSwipeGestureLayer
            settingsSwipeGestureLayer
            
            // MARK: - Overlay blocker + views
            if showSettings || showVault {
                Color.black.opacity(0.001) // absorbs taps
                    .ignoresSafeArea()
                    .zIndex(2)
                    .onTapGesture {} // absorbs touches
                
                if showSettings {
                    KSettings()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.35), value: showSettings)
                        .zIndex(3)
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.width > 80 {
                                        withAnimation { showSettings = false }
                                    }
                                }
                        )
                }
                
                if showVault {
                    KVault()
                        .frame(width: UIScreen.main.bounds.width)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.35), value: showVault)
                        .zIndex(3)
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    if value.translation.width < -80 {
                                        withAnimation { showVault = false }
                                    }
                                }
                        )
                        .modelContainer(Persistence.container)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .gesture(
            showSettings || showVault ? nil :
                DragGesture(minimumDistance: 30)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    if value.startLocation.x < 20 && value.translation.width > 100 {
                        withAnimation { showVault = true }
                    } else if value.startLocation.x > UIScreen.main.bounds.width - 20 && value.translation.width < -100 {
                        withAnimation { showSettings = true }
                    }
                }
        )
        .onTapGesture {
            if !showSettings && !showVault {
                handleTap()
            }
        }
    }
    
    func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .month, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
    
#if DEBUG
    func showNextImage() {
        currentIndex = (currentIndex + 1) % backgroundImages.count
        selectedImage = backgroundImages[currentIndex]
    }
#endif
    
    private func handleTap() {
        switch viewState {
        case .idle:  showInputView()
        default:     toIdleView()
        }
    }
    
    private func bottomTrailingBrightness(of image: UIImage) -> CGFloat {
        // Bottom-right 20% width and 30% height
        let focusRect = CGRect(x: 0.8, y: 0.0, width: 0.2, height: 0.3)
        return localizedBrightness(of: image, relativeRect: focusRect)
    }
    private var vaultSwipeGestureLayer: some View {
        Color.clear
            .frame(width: 20)
            .contentShape(Rectangle())
            .onTapGesture {} // keeps it interactive
            .offset(x: showVault ? 0 : -UIScreen.main.bounds.width)
    }
    
    private var settingsSwipeGestureLayer: some View {
        Color.clear
            .frame(width: 20)
            .contentShape(Rectangle())
            .onTapGesture {}
            .offset(x: showSettings ? 0 : UIScreen.main.bounds.width)
    }
    
    func showInputView() {
        withAnimation(.easeInOut(duration: viewTransitionDuration)) {
            viewState = .input
        }
        DispatchQueue.main.async {
            isEditorFocused = true
        }
    }
    
    
    private func toIdleView() {
        isEditorFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + viewTransitionDelay) { //    If you prefer the keyboard to finish before the overlay starts fading
            withAnimation(.easeInOut(duration: viewTransitionDuration)) {
                viewState = .idle
            }
        }
    }
    let backgroundImages = [
        "bg1", "bg2", "bg3", "bg4", "bg5",
        "bg6", "bg7", "bg8", "bg9", "bg10",
        "bg11", "bg12", "bg13", "bg14", "bg15",
        "bg16", "bg17", "bg18", "bg19", "bg20",
        "bg21", "bg22", "bg23", "bg24", "bg25",
        "bg26", "bg27", "bg28", "bg29", "bg30",
        "bg31"
    ]
}


// MARK: - InputView

struct InputView: View {
    @EnvironmentObject var usageManager: ApiCallUsageManager
    @Binding var kViewState: KView.ViewState
    @Binding var text: String
    @FocusState var isEditorFocused: Bool
    var geometry: GeometryProxy
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var userIntentType: IntentType = .unknown
    @Binding var showPaywall: Bool
    @Binding var delay: Double
    @Binding var duration: Double
    @AppStorage("calendarPermissionGranted") var calendarPermissionGranted: Bool?
    @AppStorage("reminderPermissionGranted") var reminderPermissionGranted: Bool?
    @State private var userWantsReminderButNoPermission: Bool = false
    @State private var userWantsCalendarButNoPermission: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            KiokuBackgroundView()
            
            VStack {
                if kViewState == .response {
                    VStack(spacing: 24) {
                        ScrollView {
                            Text(text)
                                .font(.custom("New York", size: 20))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 30)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button("OK") {
                            withAnimation {
                                openAiManager.clearManager()
                                pineconeManager.clearManager()
                                text = ""
                            }
                            isEditorFocused = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.easeInOut(duration: duration)) {
                                    kViewState = .idle
                                }
                            }
                        }
                        .font(.custom("New York", size: 22))
                        .bold()
                        .foregroundColor(.black)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                else if userWantsReminderButNoPermission {
                    KErrorView(title: "Permission Required", message: "Seems that you requested to save a new Reminder but you haven;t granted permission yet. Please go to your device settings and grant permission to save Reminders.", ButtonText: "OK", retryAction: {
                        withAnimation { text = "" }
                        toinputStateFromState()
                    })
                } else if userWantsCalendarButNoPermission {
                    KErrorView(title: "Permission Required", message: "Seems that you requested to save a new Calendar Event but you haven;t granted permission yet. Please go to your device settings and grant permission to save to your Calendar.", ButtonText: "OK", retryAction: {
                        withAnimation { text = "" }
                        toinputStateFromState()
                    })
                }
                else {
                    textEditor
                        .transition(.opacity)
                    stateContent
                        .transition(.opacity)
                }
                Spacer()
            }.padding(.top, 15)
//                .frame(height: UIScreen.main.bounds.height)
        }
        .onChange(of: openAiManager.userIntent) { _, intent in
            debugLog("✅ Trigger received — handle intent")
            if let intent = intent {
                processIntent(intent)
            }
        }
        .onChangeHandlers(viewState: $kViewState, text: $text)
        .onChange(of: openAiManager.stringResponseOnQuestion) { _, newResponse in
            withAnimation {
                text = newResponse
                toResponseView()
            }
        }
        .fullScreenCover(item: $openAiManager.pendingReminder) { wrapper in
            NavigationStack {
                
                ReminderConfirmationView(wrapper: wrapper) {
                    Task {
                        let success = await openAiManager.savePendingReminder()
                        await MainActor.run {
                            openAiManager.pendingReminder = nil // always clear
                            
                            if success {
                                text = ""
                                toinputStateFromState()
                            } else {
                                if let error = openAiManager.reminderError {
                                    withAnimation {
                                        kViewState = .onError(AnyDisplayableError(error))
                                    }
                                } else {
                                    withAnimation {
                                        kViewState = .onError(AnyDisplayableError(OpenAIError.unknown(NSError(
                                            domain: "ReminderError",
                                            code: 0,
                                            userInfo: [NSLocalizedDescriptionKey: "Reminder could not be saved."]
                                        ))))
                                    }
                                }
                            }
                        }
                    }
                } onCancel: {
                    openAiManager.pendingReminder = nil
                    text = ""
                    toinputStateFromState()
                }
            }
        }.ignoresSafeArea(.keyboard, edges: .all)
        
        
        .fullScreenCover(item: $openAiManager.pendingCalendarEvent) { wrapper in
            NavigationStack {
            CalendarConfirmationView(wrapper: wrapper) {
                Task {
                    let success = await openAiManager.saveCalendarEvent()
                    
                    await MainActor.run {
                        openAiManager.pendingCalendarEvent = nil
                        
                        if success {
                            text = ""
                            toinputStateFromState()
                        } else {
                            if let error = openAiManager.calendarError {
                                withAnimation {
                                    kViewState = .onError(AnyDisplayableError(error))
                                }
                            } else {
                                withAnimation {
                                    kViewState = .onError(AnyDisplayableError(OpenAIError.unknown(
                                        NSError(domain: "CalendarError", code: 0, userInfo: [
                                            NSLocalizedDescriptionKey: "Sorry, something went wrong while saving your calendar event.\nPlease try again."
                                        ])
                                    )))
                                }
                            }
                        }
                    }
                }
            } onCancel: {
                openAiManager.pendingCalendarEvent = nil
                text = ""
                toinputStateFromState()
            }
        }
    }.ignoresSafeArea(.keyboard, edges: .all)
    }
    
    private var responseTextView: some View {
        Text(text)
            .font(.custom("New York", size: 20))
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .padding(.top, 45)
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var textEditor: some View {
        TextEditor(text: $text)
            .focused($isEditorFocused)
            .font(.custom(NewYorkFont.regular.rawValue, size: 20))
            .if(userIntentType == .saveInfo) { $0.italic() }
            .foregroundColor(.black)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .multilineTextAlignment(.leading)
            .lineSpacing(7)
            .padding(.top, 40)
            .padding(.leading, 30)
            .frame(width: geometry.size.width, height: 220)
    }
    
    @ViewBuilder
    private var stateContent: some View {
        switch kViewState {
        case .onApiCall:
            apiCallLabelView
        case .onError(let error):
            KErrorView(
                title: error.title,
                message: error.message, ButtonText: "Retry",
                retryAction: {
                   resetToInputState()
                }
            )
            .transition(.scale.combined(with: .opacity))
            .animation(.easeOut(duration: 0.2), value: error.title)
        case .onSuccess:
            successView
        case .response:
            responseOKButtonView
        case .input:
            saveButton
        default:
            EmptyView()
        }
    }
    private func resetToInputState() {
        withAnimation {
            kViewState = .input
            text = ""
        }
        openAiManager.clearManager()
        pineconeManager.clearManager()
        
        isEditorFocused = true
    }
    
    private var apiCallLabelView: some View {
        Text(apiCallLabel(for: userIntentType))
            .font(.custom("New York", size: 20))
            .foregroundColor(.black)
            .italic()
    }
    
    
    private var successView: some View {
        Group {
            
            Text(successLabel(for: userIntentType))
                .font(.custom("New York", size: 20))
                .foregroundColor(.black)
                .italic()
                .padding(.bottom, 20)
        }
        .onAppear {
            if isEditorFocused {
                isEditorFocused = false
            }
            withAnimation {
                text = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                toinputStateFromState()
            }
        }
    }
    
    private var responseOKButtonView: some View {
        Button {
            withAnimation {
                openAiManager.clearManager()
                pineconeManager.clearManager()
                text = ""
            }
            isEditorFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration)) {
                    kViewState = .idle
                }
            }
        } label: {
                Text("Ask or save something else?")
                .font(.custom(NewYorkFont.italic.rawValue, size: 20))
                    .bold()
                    .foregroundColor(.black)
                    .underline()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Confirm response")
        .accessibilityHint("Returns to the input screen so you can continue")
    }
    
    private var saveButton: some View {
        Button("Go") {
            
#if !DEBUG
            if !usageManager.canMakeApiCall() {
                showPaywall = true
                return
            }
#endif
            Task {
                let cleanText = clean(text: text)
                await openAiManager.getTranscriptAnalysis(transcrpit: cleanText)
            }
            withAnimation {
                kViewState = .onApiCall
            }
        }
        .buttonStyle(.plain)
        .underline()
        .font(.custom(NewYorkFont.regular.rawValue, size: 22))
        .bold()
        .foregroundColor(.black)
        .padding(.top, 20)
        .transition(.opacity)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityLabel("Submit your text")
        .accessibilityHint("Starts the process of saving or answering your request")
    }
    
    
    private func apiCallLabel(for type: IntentType) -> String {
        switch type {
        case .isQuestion: return "Searching..."
        case .saveInfo: return "Saving..."
        case .isReminder: return "Creating Reminder..."
        case .isCalendar: return "Adding Event..."
        default: return "Working..."
        }
    }
    private func successLabel(for type: IntentType) -> String {
        switch type {
        case .isQuestion: return "Done"
        case .saveInfo: return "Saved"
        case .isCalendar: return "Event Added"
        case .isReminder: return "Reminder Set"
        default:  return "Done"
            
        }
    }
    
    private func toIdleView() {
        isEditorFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: duration)) {
                kViewState = .idle
            }
        }
    }
    
    private func toResponseView() {
        isEditorFocused = false
        withAnimation(.easeInOut(duration: duration)) {
            kViewState = .response
        }
    }
    
    private func toinputStateFromState() {
        withAnimation(.easeInOut(duration: duration)) {
            kViewState = .input
        }
        isEditorFocused = true
    }
    
    private func toSuccessState() {
        withAnimation {
            kViewState = .onSuccess
        }
    }
    
    
    private func processIntent(_ intent: IntentClassificationResponse) {
        
        debugLog("Started processIntetn: \(intent.type)")
        
        //Check Permission for Calendard and Reminder
        if intent.type == .isCalendar && calendarPermissionGranted != true {
            userWantsCalendarButNoPermission = true
        }
        
        if intent.type == .isReminder && reminderPermissionGranted != true {
            userWantsReminderButNoPermission = true
        }
        
        
        userIntentType = intent.type
        
        debugLog(" processIntetn: about to call openAiManager.handleClassifiedIntent()")
        openAiManager.handleClassifiedIntent(intent)
    }
    
    private func handleQuestionEmbeddingsCompleted() {
        debugLog("handleQuestionEmbeddingsCompleted CALLED" )
        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
    }
    
    //  timestamp: metadata["timestamp"] ?? ISO8601DateFormatter().string(from: Date())
    
    //MARK: InputViewChangeHandler
    struct InputViewChangeHandler: ViewModifier {
        @Binding var kViewState: KView.ViewState
        @EnvironmentObject var openAiManager: OpenAIViewModel
        @EnvironmentObject var pineconeManager: PineconeViewModel
        @EnvironmentObject var networkManager: NetworkManager
        @EnvironmentObject var usageManager: ApiCallUsageManager
        @Environment(\.modelContext) private var modelContext
        @Binding var textEditorsText: String
        
        func body(content: Content) -> some View {
            content
            
                .onChange(of: openAiManager.embeddingsTrigger) {
                    if openAiManager.userIntent?.type == .isQuestion {
                        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
                    } else if openAiManager.userIntent?.type == .saveInfo {
                        let metadata = toDictionary(desc: textEditorsText)
                        let uniqueID = UUID().uuidString
                        debugLog("About to upsert To Pinecone: \(textEditorsText)")
                        Task {                // still fine to stay async
                            let ok = await pineconeManager.upsertData(
                                id: uniqueID,
                                vector: openAiManager.embeddings,
                                metadata: metadata,
                                from: .KView
                            )
                            
                            guard ok else { return }
                            
                            // All SwiftData work stays on MainActor
                            
                            let newVector = VectorEntity(
                                id: uniqueID,
                                descriptionText: metadata["description"] ?? "No description",
                                timestamp: metadata["timestamp"] ?? ISO8601DateFormatter().string(from: Date())
                            )
                            
                            await MainActor.run {
                                do {
                                    modelContext.insert(newVector)
                                    try modelContext.save()           // synchronous; no extra await
                                    debugLog("Saved VectorEntity to SwiftData: \(uniqueID)")
                                } catch {
                                    debugLog("Failed to save vector locally: \(error.localizedDescription)")
                                }
                                usageManager.trackApiCall()
                                withAnimation { kViewState = .onSuccess }
                            }
                        }
                    }
                }
                .onChange(of: pineconeManager.pineconeQueryResponse) { _, newValue in
                    if let pineconeResponse = newValue {
                        Task {
                            if openAiManager.userIntent?.type == .isQuestion {
                                let userQuestion = openAiManager.userIntent?.query ?? ""
                                debugLog("User question from Voice over: \(userQuestion), calling getGptResponse")
                                await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: userQuestion)
                            }
                        }
                    } else {
                        debugLog("⚠️ pineconeManager.pineconeQueryResponse was nil.")
                    }
                    usageManager.trackApiCall()
                }
                .onChange(of: pineconeManager.pineconeErrorFromAdd) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(AnyDisplayableError(error))
                        }
                    }
                }
                .onChange(of: pineconeManager.pineconeErrorFromQ) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(AnyDisplayableError(error))
                        }
                    }
                }
                .onChange(of: openAiManager.gptResponseError) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(AnyDisplayableError(error))
                        }
                    }
                }
                .onChange(of: openAiManager.transriptionError) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(AnyDisplayableError(error))
                        }
                    }
                }
                .onChange(of: openAiManager.openAIErrorFromQuestion) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(AnyDisplayableError(error))
                        }
                    }
                }
            
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        kViewState = .onError(AnyDisplayableError(PineconeError.networkUnavailable))
                    } else {
                        //When network is back
                        if case .onError = kViewState {
                            withAnimation {
                                kViewState = .input
                            }
                        }
                    }
                }
        }
    }
}

#Preview {
    
    
    let pineconeActor = PineconeActor()
    let openAIActor = OpenAIActor()
    
    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor)
    let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
    let networkManager = NetworkManager()
    KView(launchURL: .constant(nil), showVault: .constant(false))  // OR .constant(URL(string: "mnimi://add")) for the widget
        .environmentObject(openAIViewModel)
        .environmentObject(pineconeViewModel)
        .environmentObject(networkManager)
}

extension View {
    func onChangeHandlers(viewState: Binding<KView.ViewState>, text: Binding<String>) -> some View {
        modifier(InputView.InputViewChangeHandler(kViewState: viewState, textEditorsText: text))
    }
}

struct ReminderConfirmationView: View {
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var wrapper: ReminderWrapper
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Title", text: $wrapper.title)
                    .font(.custom("New York", size: 18))
                    .textInputAutocapitalization(.sentences)

                DatePicker(
                    "Date", selection: Binding(
                        get: { wrapper.dueDate ?? Date() },
                        set: { wrapper.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.custom("New York", size: 18))

                TextField("Notes", text: Binding(
                    get: { wrapper.notes ?? "" },
                    set: { wrapper.notes = $0 }
                ))
                .font(.custom("New York", size: 18))
                .textInputAutocapitalization(.sentences)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(maxWidth: 500)
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                let reminderImage = randomBackgroundName()
                Image(reminderImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.9)
                    .ignoresSafeArea()

                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.9), .clear, .clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            }
        }
        .navigationTitle("Confirm Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: onConfirm)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CalendarConfirmationView: View {
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var wrapper: EventWrapper
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // FORM
            Form {
                TextField("Title", text: Binding(
                    get: { wrapper.title },
                    set: { wrapper.title = $0 }
                ))
                .font(.custom("New York", size: 18))
                .textInputAutocapitalization(.sentences)

                DatePicker("Start", selection: Binding(
                    get: { wrapper.startDate },
                    set: { wrapper.startDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .font(.custom("New York", size: 18))

                DatePicker("End", selection: Binding(
                    get: { wrapper.endDate },
                    set: { wrapper.endDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .font(.custom("New York", size: 18))

                TextField("Location", text: Binding(
                    get: { wrapper.location ?? "" },
                    set: { wrapper.location = $0 }
                ))
                .font(.custom("New York", size: 18))
                .textInputAutocapitalization(.sentences)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .frame(maxWidth: 500)
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                let calendarImage = randomBackgroundName()
                Image(calendarImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .opacity(0.8)
                    .ignoresSafeArea()

                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.9), .clear, .clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            }
        }
        .navigationTitle("Confirm Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: onConfirm)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        
    }
}

func randomBackgroundName() -> String {
    let imageCount = 14  // adjust
    let index = Int.random(in: 1...imageCount)
    return "rm\(index)"
}

// FOR REMINDER sheet
//#Preview {
//    let mockEventStore = EKEventStore()
//    let mockReminder = EKReminder(eventStore: mockEventStore)
//    mockReminder.title = "Call Alice"
//    mockReminder.addAlarm(EKAlarm(absoluteDate: Date().addingTimeInterval(3600)))
//
//    let wrapper = ReminderWrapper(reminder: mockReminder)
//    let mockOpenAI = OpenAIViewModel(openAIActor: OpenAIActor())
//
//    return ReminderConfirmationView(wrapper: wrapper) {
//        print("Confirmed reminder")
//    }
//    .environmentObject(mockOpenAI)
//}


//#Preview {
//    do {
//        let container = try ModelContainer(for: VectorEntity.self)
//        let context = ModelContext(container)
//
//        let pineconeActor = PineconeActor()
//        let openAIActor = OpenAIActor()
//        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor)
//
//        let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
//        let networkManager = NetworkManager()
//
//        return KView()
//            .environmentObject(openAIViewModel)
//            .environmentObject(pineconeViewModel)
//            .environmentObject(networkManager)
//            .modelContainer(container)
//    } catch {
//        return Text("Preview failed: \(error.localizedDescription)")
//    }
//}

//For the Calendar Sheet
//#Preview {
//    let eventStore = EKEventStore()
//    let mockEvent = EKEvent(eventStore: eventStore)
//    mockEvent.title = "Lunch with Bethan!"
//    mockEvent.startDate = Date()
//    mockEvent.endDate = Date().addingTimeInterval(3600)
//    mockEvent.location = "Italian Café"
//
//    let wrapper = EventWrapper(event: mockEvent)
//    let mockOpenAI = OpenAIViewModel(openAIActor: OpenAIActor())
//
//    return CalendarConfirmationView(wrapper: wrapper) {
//        mockOpenAI.saveCalendarEvent()
//    } onCancel: {
//
//    }
//    .environmentObject(mockOpenAI)
//}
