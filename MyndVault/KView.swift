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

struct KView: View {
    enum ViewState: Equatable {
        case idle
           case input // user is typing
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
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geo in
                if viewState != .input {
                
                    Image(selectedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack {
                        if viewState == .input {
                            InputView(
                                kViewState: $viewState, text: $text,
                                isEditorFocused: _isEditorFocused,
                                geometry: geo
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
        default:     fromInputToIdle()
        }
    }
    
    private func showInputView() {
        withAnimation(.easeInOut(duration: 0.4)) {
            viewState = .input
        }
        DispatchQueue.main.async {
            isEditorFocused = true
        }
    }
    
    
    func fromInputToIdle() {
        isEditorFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //    If you prefer the keyboard to finish before the overlay starts fading
            withAnimation(.easeInOut(duration: 0.4)) {
                viewState = .idle
            }
        }
    }
}


// MARK: - InputView

struct InputView: View {
    @Binding var kViewState: KView.ViewState   // we pass down the parent's state
    @Binding var text: String
    @FocusState var isEditorFocused: Bool
    var geometry: GeometryProxy
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var userIntentType: IntentType = .unknown
    
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
                TextEditor(text: $text)
                    .focused($isEditorFocused)
                    .font(.custom("New York", size: 20))
                    .font(userIntentType == .saveInfo
                           ? .custom("New York", size: 20).italic()
                           : .custom("New York", size: 20))
                    .foregroundColor(.black)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 40)
                    .padding(.leading, 30)
                    .frame(width: geometry.size.width, height: 220)
                
                switch kViewState {
                case .onApiCall:
                    // "Saving..." label (disabled button or no button)
                    Text(apiCallLabel(for: userIntentType))
                        .font(.custom("New York", size: 20))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                    
                case .onError(let errorMessage):
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                        Button("Retry") {
                            withAnimation {
                                kViewState = .input
                            }
                        }
                    }
                    .font(.headline)
                    .underline()
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                    
                case .onSuccess, .response:
                    Button("Done") {
                        withAnimation {
                            text = ""
                            userIntentType = .unknown
                        }
                        isEditorFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //    If you prefer the keyboard to finish before the overlay starts fading
                            withAnimation(.easeInOut(duration: 0.4)) {
                                kViewState = .idle
                            }
                        }
                    }
                    .font(.headline)
                    .underline()
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                    
                case .input:
                    // Normal “Save” button
                    Button("Save") {
                        print("Saving...")
                        Task {
                            await openAiManager.getTranscriptAnalysis(transcrpit: text)
                        }
                        withAnimation {
                            kViewState = .onApiCall
                        }
                    }
                    .font(.custom("New York", size: 22))
                    .bold()
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .transition(.opacity)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                default:
                    EmptyView()
                }
            }
            .padding(.top, 15)
        }
        .onChange(of: openAiManager.intentResponse) {_, response in
            
            guard let response = response else { return }
            guard response.type != .unknown else {
                debugLog("⚠️ openAiManager.intentResponse.type was nil. Aborting flow.")
                return
            }
            processIntent(response)
        }
        .onChange(of: openAiManager.questionEmbeddingTrigger) {
            if userIntentType == .isQuestion {
                handleQuestionEmbeddingsCompleted()
            }
            else if userIntentType == .saveInfo {
                saveToPinecone()
            }
        }
        .onChange(of: pineconeManager.pineconeQueryResponse) { _, newValue in
            if let pineconeResponse = newValue {
                handlePineconeResponse(pineconeResponse)
            } else { debugLog("⚠️ pineconeManager.pineconeQueryResponse was nil.") }
        }
        .onChange(of: openAiManager.stringResponseOnQuestion) { _, newResponse in
                text = newResponse
            
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
    private func handlePineconeResponse(_ pineconeResponse: PineconeQueryResponse) {
        debugLog("📌 Intent type at pinecone response: \(String(describing: openAiManager.intentResponse?.type))")
        for match in pineconeResponse.matches {
          
            Task {
                if openAiManager.intentResponse?.type == .isQuestion {
                    let userQuestion = openAiManager.intentResponse?.query ?? ""
                debugLog("User question from Voice over: \(userQuestion), calling getGptResponse")
                    await openAiManager.getGptResponse(queryMatches: pineconeResponse.matches, question: userQuestion)
                }
               
                else {
                    debugLog("type: \(String(describing: openAiManager.intentResponse?.type))\nquery: \(openAiManager.intentResponse?.query ?? "Default")")
                }
            }
        }
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
