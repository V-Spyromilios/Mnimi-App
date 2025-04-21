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
 
 */

import SwiftUI
import EventKit

struct KView: View {
    enum ViewState: Equatable {
        case idle
        case input // user is typing or about to type
        case response // GPT answered something ONLY for Q&A
        case onApiCall
        case onSuccess
        case onError(String)
    }
    
    @State private var viewState: ViewState = .idle
    @State private var selectedImage: String = ""
    @State private var text: String = ""
    @State private var recordingURL: URL?
    @FocusState private var isEditorFocused: Bool
    @StateObject private var audioRecorder: AudioRecorder = AudioRecorder()
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @State private var micColor: Color = .white
    @State private var viewTransitionDelay: Double = 0.4
    @State private var viewTransitionDuration: Double = 0.4
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geo in
                if viewState == .idle  {
                    
                    Image(selectedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack {
                        if viewState != .idle {
                            InputView(
                                kViewState: $viewState, text: $text,
                                isEditorFocused: _isEditorFocused,
                                geometry: geo,
                                delay: $viewTransitionDelay,
                                duration: $viewTransitionDuration
                            )
                            .ignoresSafeArea(.keyboard, edges: .all)
                            .transition(.opacity)
                            .frame(height: geo.size.height)
                        }
                    } .frame(width: geo.size.width, height: geo.size.height)
                    Spacer()
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
            .onAppear {
                selectedImage = imageForToday()
                if let uiImage = UIImage(named: selectedImage) {
                    let brightness = averageBrightness(of: uiImage)
                    micColor = brightness > 0.7 ? .black : .white // Tune threshold if needed
                }
            }
            KRecordButton(recordingURL: $recordingURL, audioRecorder: audioRecorder, micColor: $micColor)
                .onChange(of: recordingURL) { _, url in
                    if let url {
                        Task {
                            await openAiManager.processAudio(fileURL: url, fromQuestion: true)
                        }
                    }
                }
                .onChange(of: openAiManager.transcriptionForQuestion) { _, newTranscript in
                    guard !newTranscript.isEmpty else { return }
                    
                    text = newTranscript
                    showInputView()
                    
                    // Clean up audio
                    audioRecorder.deleteAudioAndUrl()
                    recordingURL = nil
                }
                .padding(.trailing, 20)
                .padding(.bottom, 140)
        }
        .ignoresSafeArea()
        .onTapGesture { handleTap() }
        .statusBar(hidden: true)
    }
    
    private func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
    
    private func handleTap() {
        switch viewState {
        case .idle:  showInputView()
        default:     toIdleView()
        }
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
    @Binding var kViewState: KView.ViewState
    @Binding var text: String
    @FocusState var isEditorFocused: Bool
    var geometry: GeometryProxy
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var userIntentType: IntentType = .unknown
    @Binding var delay: Double
    @Binding var duration: Double
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(0.9)
                .blur(radius: 1)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            
            VStack {
                textEditor
                stateContent
            }
            .padding(.top, 15)
            .onChange(of: openAiManager.userIntent) { _, intent in
                debugLog("✅ Trigger received — handle intent")
                if let intent = intent {
                    openAiManager.handleClassifiedIntent(intent)
                }
            }
        }
        .onChangeHandlers(viewState: $kViewState)
        .onChange(of: openAiManager.stringResponseOnQuestion) { _, newResponse in
            withAnimation {
                text = newResponse
            }
        }
        .onChange(of: openAiManager.reminderCreated) { _, cuccess in
                if cuccess {
                    withAnimation {
                        text = "" }
                    toinputStateFromState()
                } else {
                    kViewState = .onError("Error saving reminder. Please try again.")
                }
        }
        .sheet(item: $openAiManager.pendingReminder) { wrapper in
            ReminderConfirmationView(wrapper: wrapper) {
                openAiManager.savePendingReminder()
            }
        }

    }
    
    private var textEditor: some View {
        TextEditor(text: $text)
            .focused($isEditorFocused)
            .font(.custom("New York", size: 20))
            .if(userIntentType == .saveInfo) { $0.italic() }
            .foregroundColor(.black)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .multilineTextAlignment(.leading)
            .padding(.top, 40)
            .padding(.leading, 30)
            .frame(width: geometry.size.width, height: 220)
    }
    
    @ViewBuilder
    private var stateContent: some View {
        switch kViewState {
        case .onApiCall:
            apiCallLabelView
        case .onError(let errorMessage):
            errorView(errorMessage)
        case .onSuccess:
            successView
        case .response:
            responseView
        case .input:
            saveButton
        default:
            EmptyView()
        }
    }
    
    private var apiCallLabelView: some View {
        Text(apiCallLabel(for: userIntentType))
            .font(.custom("New York", size: 20))
            .foregroundColor(.black)
            .italic()
            .padding(.bottom, 20)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack {
            Text(message)
            Button("Cancel") {
                withAnimation { kViewState = .input }
            }.underline()
        }
        .font(.custom("New York", size: 20))
        .foregroundColor(.black)
        .padding(.bottom, 20)
    }
    
    private var successView: some View {
        Group {
            if userIntentType == .saveInfo {
                Text(apiCallLabel(for: userIntentType))
                    .font(.custom("New York", size: 20))
                    .foregroundColor(.black)
                    .italic()
                    .padding(.bottom, 20)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if kViewState != .idle {
                                self.toIdleView()
                            }
                        }
                    }
            }
        }
    }
    
    private var responseView: some View {
        Button("OK") {
            withAnimation {
                text = ""
            }
            isEditorFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration)) {
                    kViewState = .idle
                }
            }
        }
        .underline()
        .font(.custom("New York", size: 22))
        .bold()
        .foregroundColor(.black)
        .padding(.bottom, 20)
    }
    
    private var saveButton: some View {
        Button("Go") {
            Task {
                await openAiManager.getTranscriptAnalysis(transcrpit: text)
            }
            withAnimation {
                kViewState = .onApiCall
            }
        }
        .underline()
        .font(.custom("New York", size: 22))
        .bold()
        .foregroundColor(.black)
        .padding(.top, 20)
        .transition(.opacity)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    
    private func toIdleView() {
        isEditorFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: duration)) {
                kViewState = .idle
            }
        }
    }
    
    private func toinputStateFromState() {
        isEditorFocused = true
            withAnimation(.easeInOut(duration: duration)) {
                kViewState = .input
            }
    }
    
    private func toSuccessState() {
        withAnimation {
            kViewState = .onSuccess
        }
    }
    
    private func saveToPinecone() {
        let metadata = toDictionary(desc: self.text)
        let uniqueID = UUID().uuidString
        
        pineconeManager.upsertData(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata, from: .KView)
    }
    
    private func processIntent(_ intent: IntentClassificationResponse) {
        
        debugLog("Started processIntetn: \(intent.type)")
        userIntentType = intent.type
        debugLog("is on main thread: \(Thread.isMainThread)")
        debugLog(" processIntetn: about to call openAiManager.handleClassifiedIntent()")
        openAiManager.handleClassifiedIntent(intent)
    }
    
    private func handleQuestionEmbeddingsCompleted() {
        debugLog("handleQuestionEmbeddingsCompleted CALLED" )
        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
    }
    
    //    private func handleUserIntention(_ pineconeResponse: PineconeQueryResponse) {
    //        debugLog("📌 Intent type at pinecone response: \(String(describing: openAiManager.intentResponse?.type))")
    //        for match in pineconeResponse.matches {
    //
    //            Task {
    //                if openAiManager.intentResponse?.type == .isQuestion {
    //                    let userQuestion = openAiManager.intentResponse?.query ?? ""
    //                    debugLog("User question from Voice over: \(userQuestion), calling getGptResponse")
    //                    await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: userQuestion)
    //                }
    //
    //                else {
    //                    debugLog("type: \(String(describing: openAiManager.intentResponse?.type))\nquery: \(openAiManager.intentResponse?.query ?? "Default")")
    //                }
    //            }
    //        }
    //    }
    
    struct InputViewChangeHandler: ViewModifier {
        @Binding var kViewState: KView.ViewState
        @EnvironmentObject var openAiManager: OpenAIViewModel
        @EnvironmentObject var pineconeManager: PineconeViewModel
        
        func body(content: Content) -> some View {
            content
                .onChange(of: openAiManager.pendingReminder?.reminder) { _, pendingReminder in
                    if pendingReminder != nil {
                        kViewState = .onSuccess
                    }
                }
                .onChange(of: openAiManager.questionEmbeddingTrigger) {
                    if openAiManager.userIntent?.type == .isQuestion {
                        pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
                    } else if openAiManager.userIntent?.type == .saveInfo {
                        let metadata = toDictionary(desc: openAiManager.transcription)
                        let uniqueID = UUID().uuidString
                        pineconeManager.upsertData(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata, from: .KView)
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
                }
                .onChange(of: pineconeManager.pineconeErrorFromAdd) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(error.localizedDescription)
                        }
                    }
                }
                .onChange(of: pineconeManager.upsertSuccessful) { _, success in
                    if success {
                        debugLog("✅ Successfully saved to Pinecone")
                        withAnimation {
                            kViewState = .onSuccess
                        }
                    }
                }
                .onChange(of: pineconeManager.pineconeErrorFromQ) { _, error in
                    if let error = error {
                        withAnimation {
                            kViewState = .onError(error.localizedDescription)
                        }
                    }
                }
        }
    }
}

#Preview {
    
    let cloudKit = CloudKitViewModel.shared
    let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
    let openAIActor = OpenAIActor()
    let languageSettings = LanguageSettings.shared
    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
    let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
    let networkManager = NetworkManager()
    KView()
        .environmentObject(openAIViewModel)
        .environmentObject(pineconeViewModel)
}

extension View {
    func onChangeHandlers(viewState: Binding<KView.ViewState>) -> some View {
        modifier(InputView.InputViewChangeHandler(kViewState: viewState))
    }
}

struct ReminderConfirmationView: View {
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var wrapper: ReminderWrapper
    var onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: Binding(
                    get: { wrapper.reminder.title },
                    set: { wrapper.reminder.title = $0 }
                ))
                
                DatePicker("Alarm Time", selection: Binding(
                    get: {
                        wrapper.reminder.alarms?.first?.absoluteDate ?? Date()
                    },
                    set: { newDate in
                        wrapper.reminder.alarms?.removeAll()
                        wrapper.reminder.addAlarm(EKAlarm(absoluteDate: newDate))
                    }
                ), displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Confirm Reminder")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onConfirm)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        wrapper.reminder.title = ""
                        openAiManager.pendingReminder = nil // or use a dismiss closure
                    }
                }
            }
        }
    }
}
