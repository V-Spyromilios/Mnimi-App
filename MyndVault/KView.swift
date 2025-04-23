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
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var micColor: Color = .white
    @State private var viewTransitionDelay: Double = 0.4
    @State private var viewTransitionDuration: Double = 0.4
    @State private var showVault: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geo in
                if viewState == .idle {
                    
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
                .opacity(viewState == .idle ? 1 : 0)
                .allowsHitTesting(viewState == .idle)
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
                    
                    // Clean up audio
                    audioRecorder.deleteAudioAndUrl()
                    recordingURL = nil
                }
                .padding(.trailing, 20)
                .padding(.bottom, 140)
            
            //MARK: For drag gestures
            vaultSwipeGestureLayer
            settingsSwipeGestureLayer
            
            // MARK: - Overlays
            // This layer blocks interaction below
                if showSettings  || showVault {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {} // eat taps
                        .zIndex(2)
                }

                // Actual overlay on top
                if showSettings {
                    KSettings()
                        .transition(.move(edge: .trailing))
                        .zIndex(3)
                }
            if showVault {
                KVault()
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }
            //MARK: End of gestures
        }
        .zIndex(0)
        .ignoresSafeArea()
        .onTapGesture {
            if !showSettings || !showVault {
                handleTap()
            }
        }
        .statusBar(hidden: true)
        .allowsHitTesting(!showSettings || !showVault)
        .gesture(
            showSettings ? nil : DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.startLocation.x < 20 && value.translation.width > 100 {
                        withAnimation { showVault = true }
                    } else if value.startLocation.x > UIScreen.main.bounds.width - 20 && value.translation.width < -100 {
                        withAnimation { showSettings = true }
                    }
                }
        )
    }
    
    func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
    
    private func handleTap() {
        switch viewState {
        case .idle:  showInputView()
        default:     toIdleView()
        }
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
                if kViewState == .response {
                    responseTextView
                        .transition(.opacity)
                } else {
                    textEditor
                        .transition(.opacity)
                }
                stateContent
                    .transition(.opacity)
            }.padding(.top, 15)
        }
        .onChange(of: openAiManager.userIntent) { _, intent in
            debugLog("✅ Trigger received — handle intent")
            if let intent = intent {
                openAiManager.handleClassifiedIntent(intent)
            }
        }
        .onChangeHandlers(viewState: $kViewState)
        .onChange(of: openAiManager.stringResponseOnQuestion) { _, newResponse in
            withAnimation {
                text = newResponse
                toResponseView()
            }
        }
        .onChange(of: openAiManager.reminderCreated) { _, cuccess in
            if cuccess {
                withAnimation { text = "" }
                toSuccessState()
            }
//            else {
//                kViewState = .onError("Error saving reminder. Please try again.")
//            } //TODO: Observe the Error instead!
        }
        .onChange(of: openAiManager.calendarEventCreated) {_, success in
            if success {
                withAnimation {
                    text = "" }
                toSuccessState()
            }
            
        }
        .sheet(item: $openAiManager.pendingReminder) { wrapper in
            ReminderConfirmationView(wrapper: wrapper) {
                openAiManager.savePendingReminder()
            }
        }
        .sheet(item: $openAiManager.pendingCalendarEvent) { wrapper in
            CalendarConfirmationView(wrapper: wrapper) {
                openAiManager.saveCalendarEvent()
            }
        }
    }
    
    private var responseTextView: some View {
        ScrollView {
            Text(text)
                .font(.custom("New York", size: 20))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .padding(.top, 40)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
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
    }
    
    private func errorView(_ message: String) -> some View {
        VStack {
            Text(message).multilineTextAlignment(.leading) .padding(.top, 40)
                .padding(.leading, 30)
            Button("Cancel") {
                withAnimation { kViewState = .input }
            }.underline().padding(.top, 20)
        }
        .buttonStyle(.plain)
        .underline()
        .font(.custom("New York", size: 20))
        .foregroundColor(.black)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                toinputStateFromState()
            }
        }
    }
    
    private var responseView: some View {
        Button("OK") {
            withAnimation {
                text = ""
                openAiManager.clearManager()
                pineconeManager.clearManager()
            }
            isEditorFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration)) {
                    kViewState = .idle
                }
            }
        }
        .buttonStyle(.plain)
        .underline()
        .font(.custom("New York", size: 22))
        .bold()
        .foregroundColor(.black)
        .padding(.top, 20)
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
        .buttonStyle(.plain)
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
    
//    private func saveToPinecone() {
//        let metadata = toDictionary(desc: self.text)
//        let uniqueID = UUID().uuidString
//        pineconeManager.upsertData(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata, from: .KView)
//    }
    
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
        @EnvironmentObject var networkManager: NetworkManager
        
        func body(content: Content) -> some View {
            content
            
                .onChange(of: openAiManager.embeddingsTrigger) {
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
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        withAnimation {
                            kViewState = .onError("Check your Connection")
                        }
                    }
                }
        }
    }
}

//#Preview {
//
//    let cloudKit = CloudKitViewModel.shared
//    let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
//    let openAIActor = OpenAIActor()
//    let languageSettings = LanguageSettings.shared
//    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
//    let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
//    let networkManager = NetworkManager()
//    KView()
//        .environmentObject(openAIViewModel)
//        .environmentObject(pineconeViewModel)
//}

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
            ZStack {
                // Background behind the form
                let reminderImage = randomBackgroundName()
                Image(reminderImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                // The form
                VStack {
                    Form {
                        TextField("Title", text: Binding(
                            get: { wrapper.reminder.title },
                            set: { wrapper.reminder.title = $0 }
                        )) .font(.custom("New York", size: 18))
                        
                        DatePicker("Alarm Time", selection: Binding(
                            get: {
                                wrapper.reminder.alarms?.first?.absoluteDate ?? Date()
                            },
                            set: { newDate in
                                wrapper.reminder.alarms?.removeAll()
                                wrapper.reminder.addAlarm(EKAlarm(absoluteDate: newDate))
                            }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .font(.custom("New York", size: 18))
                    }.formStyle(.automatic)
                }.frame(maxWidth: 500)

                .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .shadow(radius: 4)
                    .padding(.horizontal, 42)
            }
            .navigationTitle(Text("Confirm Reminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onConfirm)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        wrapper.reminder.title = ""
                        openAiManager.pendingReminder = nil
                    }
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                }
            }
        }
    }

}

struct CalendarConfirmationView: View {
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var wrapper: EventWrapper
    var onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background behind the form
                let calendarImage = randomBackgroundName()
                Image(calendarImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                // The form
                VStack {
                    Form {
                        TextField("Title", text: Binding(
                            get: { wrapper.event.title ?? "" },
                            set: { wrapper.event.title = $0 }
                        ))
                        .font(.custom("New York", size: 18))
                        
                        DatePicker("Start", selection: Binding(
                            get: { wrapper.event.startDate ?? Date() },
                            set: { wrapper.event.startDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .font(.custom("New York", size: 18))
                        
                        DatePicker("End", selection: Binding(
                            get: { wrapper.event.endDate ?? Date().addingTimeInterval(3600) },
                            set: { wrapper.event.endDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .font(.custom("New York", size: 18))
                        
                        TextField("Location", text: Binding(
                            get: { wrapper.event.location ?? "" },
                            set: { wrapper.event.location = $0 }
                        ))
                        .font(.custom("New York", size: 18))
                    }
                    .formStyle(.automatic)
                }
                .frame(maxWidth: 500)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .shadow(radius: 4)
                .padding(.horizontal, 42)
            }
            .navigationTitle(Text("Confirm Event"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onConfirm)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        openAiManager.pendingCalendarEvent = nil
                    }
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                }
            }
        }
    }

}

func randomBackgroundName() -> String {
    let imageCount = 14  // adjust if you have more
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


// For the KView!
//#Preview {
//
//    let cloudKit = CloudKitViewModel.shared
//    let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
//    let openAIActor = OpenAIActor()
//    let languageSettings = LanguageSettings.shared
//    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
//    let openAIViewModel = OpenAIViewModel(openAIActor: openAIActor)
//    let networkManager = NetworkManager()
//    let networkManager = NetworkManager()
//    KView()
//        .environmentObject(openAIViewModel)
//        .environmentObject(pineconeViewModel)
//          .environmentObject(networkManager)
//}

//For the Calendar Sheet
#Preview {
    let eventStore = EKEventStore()
    let mockEvent = EKEvent(eventStore: eventStore)
    mockEvent.title = "Lunch with Bethan!"
    mockEvent.startDate = Date()
    mockEvent.endDate = Date().addingTimeInterval(3600)
    mockEvent.location = "Italian Café"
    
    let wrapper = EventWrapper(event: mockEvent)
    let mockOpenAI = OpenAIViewModel(openAIActor: OpenAIActor())

    return CalendarConfirmationView(wrapper: wrapper) {
        mockOpenAI.saveCalendarEvent()
    }
    .environmentObject(mockOpenAI)
}
