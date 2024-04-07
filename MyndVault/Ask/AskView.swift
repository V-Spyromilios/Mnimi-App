//
//  AskView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI
import AVFAudio

struct AskView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManger: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var progressTracker: ProgressTracker
    
    @State private var isRecording: Bool = false
    @State private var permissionGranted: Bool = false
    @State private var isAnimating: Bool = false
    @State private var showPlaybackControls: Bool = false
    @State private var showRecordButton: Bool = true
    @State private var recordingExists: Bool = false
    @State private var playButtonIsDisabled = true
    @State private var showProgressView: Bool = false
    @State private var showtextEditorsAndButtonView: Bool = false
    @State private var textEditorsHaveShown: Bool = false
    
    private let playbackButtonDiamension: CGFloat = 80
    private let mainButtonDiamension: CGFloat = 55
    
    @State private var elapsedTime: Double = 0.0
    @State private var timer: Timer? = nil
    
    @State private var type: String = ""
    @State private var description: String = ""
    @State private var relevantFor: String = ""
    private var roundedRectRadius: CGFloat = 9
    
    @ViewBuilder
    private func goBackButton() -> some View {

        HStack {
            Spacer()
            Button(action: {
                self.prepareForNewRecording()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 55, height: 55)
                        .foregroundStyle(LinearGradient.bluePurpleGradient())
                        .shadow(radius: 5)
                    //                                       Text("Cancel").foregroundStyle(.white)
                    //                                           .font(.system(size: 18))
                    //                                           .bold()
                    //                                           .fontDesign(.rounded)
                    Image(systemName: "gobackward")
                      
                        .font(.system(size: 29))
                        .foregroundColor(.white)
                }
            }
            .padding()
            
        }
    }

    var body: some View {
        ZStack {
        //   Color.gray.opacity(0.0).ignoresSafeArea()

            ScrollView {
                
                if permissionGranted {
                //   VStack() {
                    goBackButton()
                    
                    Spacer()
                    if showRecordButton {
//                        RecordButton().frame(width: 200, height: 200).padding(.top, 30).padding(.horizontal).transition(.opacity)
//                        NewTextEditorsView(showtextEditorsAndButtonView: .constant(true), showProgressView: .constant(false))
//                            .frame(height: 550)
                           
                    }
                    if isRecording {

                        Text(String(format: "%.1f", elapsedTime))
                            .contentTransition(.numericText(countsDown: false))
                            .font(.title)
                            .fontDesign(.rounded)
                            .foregroundColor(.red).padding(.vertical)
                            .transition(.opacity)
                    }
                    
                    playbackView()
                        .padding()
                        .transition(.opacity)
                    
                    if showProgressView {
                        CircularProgressView(progressTracker: progressTracker).padding()
                            .frame(width: 200, height: 200).padding(.top, 30).padding(.horizontal).transition(.opacity)
                    }
                    if showtextEditorsAndButtonView {
                        
                        textEditorsAndButton().padding(.top, 20)
                           
                            .offset(y: 40)
                            .transition(.opacity)
                        
                    }
                } else { permissionDeniedView().padding() }
            }.onAppear {
                checkPermission()
            }
            .onReceive(AudioManager.shared.$audioPlayCompleted) { completed in
                if completed {
                    prepareForNewRecording()
                    print("AskView :: Audio playback completed - prepareForNewRecording")
                }
            }
            .onReceive(openAiManager.$gptMetadataResponseOnQuestion) { response in
                
                if response != nil, !textEditorsHaveShown {
                    withAnimation {
                        showtextEditorsAndButtonView = true
                        print("The showtextEditorsAndButtonView changed to true")
                        textEditorsHaveShown = true
                    }
                }
            }
            .onReceive(progressTracker.$progress) { progress in
                if progress == 0.0 {
                    showProgressView = false
                }
            }
            Spacer()
        }
    }
    
    private func checkRecordingExists() {
        if let recordingURL = audioManager.questionFilePath {
            audioManager.recordingExistsAndHasContent(at: recordingURL) { exists in
                DispatchQueue.main.async {
                    self.recordingExists = exists
                }
            }
        }
    }
    
    @ViewBuilder
    private func RecordButton() -> some View {
        
        Button(action: {
            
            if isRecording {
                stopRecording()
            } else {
                startRecording()
                isAnimating.toggle()
            }
        }) {
            recordingButtonImage().onAppear {
                if audioManager.questionFilePath == nil {
                    prepareForNewRecording()
                }
            }
        }
    }
    
    @ViewBuilder
    private func textEditorsAndButton() -> some View {
        if let response = openAiManager.gptMetadataResponseOnQuestion, showtextEditorsAndButtonView {
            VStack {
                HStack {
                    Text("Correct?").font(.headline).fontDesign(.rounded)
                    Spacer() }
                .padding(.bottom)
                HStack {
                    Text("Type:").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextEditor(text: $type)
                    .padding(4)
                    .frame(minHeight: 40)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .padding(.bottom)
                HStack {
                    Text("Question:").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextEditor(text: $description)
                    .padding(4)
                    .frame(minHeight: 60)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .padding(.bottom)
                HStack {
                    Text("Relevant For:").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextEditor(text: $relevantFor)
                    .padding(4)
                    .frame(minHeight: 40)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .padding(.bottom)
                
            }.padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
            
            
            Button(action: {
                
                Task {
                    await openAiManager.updateMetadataResponse(type: type, description: description, relevantFor: relevantFor)
                    withAnimation {
                        showtextEditorsAndButtonView.toggle()
                    }
                    if let textToEmbeddings = openAiManager.gptMetadataResponseOnQuestion?.description {
                        withAnimation {
                            showProgressView = true
                        }
                        ProgressTracker.shared.setProgress(to: 0.05)
                        
                        await openAiManager.requestEmbeddings(for: textToEmbeddings, isQuestion: true)
                        
                        ProgressTracker.shared.setProgress(to: 0.2)
                        
                        if openAiManager.questionEmbeddingsCompleted {
                            if let metadata = openAiManager.gptMetadataResponseOnQuestion?.toDictionary() {
                                try await pineconeManger.queryPinecone(vector: openAiManager.embeddingsFromQuestion, metadata: metadata)
                                ProgressTracker.shared.setProgress(to: 0.4)
                            }
                        } else { print("AskView :: ELSE blocked from openAiManager.questionEmbeddingsCompleted ")}
                        
                        if let pineconeResponse = pineconeManger.pineconeQueryResponse, let question = openAiManager.gptMetadataResponseOnQuestion?.description {
                            
                            try await openAiManager.getGptResponseAndConvertTextToSpeech(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
                        } else {
                            print("AskView :: ELSE blocked from getGptResponseAndConvertTextToSpeech()")
                            print("\(String(describing: pineconeManger.pineconeQueryResponse))")
                            print("\(String(describing: openAiManager.gptMetadataResponseOnQuestion?.description))")
                        }
                    } else { print("Ask View ELSE textToEmbeddings") }
                    if let metadata = openAiManager.gptMetadataResponseOnQuestion, let fileUrl = metadata.fileUrl {
                        let model = ResponseModel(timestamp: Date(), id: UUID(), type: metadata.type, desc: metadata.description, relevantFor: metadata.relevantFor, recordingPath: fileUrl)
                        modelContext.insert(model)
                        
                    } else { print("ELSE on .insert: \(String(describing: openAiManager.gptMetadataResponseOnQuestion?.fileUrl))") }
                    
                }
            }) {
                Text("OK")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(roundedRectRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.blue, lineWidth: 4)
                    )
            }
            .onAppear {
                type = response.type
                description = response.description
                relevantFor = response.relevantFor
            }
            .sensoryFeedback(.start, trigger: showProgressView)
        }
    }
    
    @ViewBuilder
    private func playbackView() -> some View {
        if showPlaybackControls {
            HStack(spacing: 30) {
                
                Button {
                    prepareForNewRecording()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .shadow(color: colorScheme == .dark ? .white: .gray, radius: 8)
                        .frame(width: playbackButtonDiamension, height: playbackButtonDiamension)
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(audioManager.questionFilePath == nil ? .gray.opacity(0.7) : .red)
                }.disabled(audioManager.questionFilePath == nil)
                    .sensoryFeedback(trigger: showPlaybackControls) { oldValue, newValue  in
                        return .impact(flexibility: .solid)
                    }
                
                Button {
                    audioManager.playRecording(fromAskView: true)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.multicolor)
                        .shadow(color: colorScheme == .dark ? .white: .gray, radius: 8)
                        .frame(width: playbackButtonDiamension, height: playbackButtonDiamension)
                        .foregroundStyle(audioManager.questionFilePath == nil ? .gray.opacity(0.7) : .yellow)
                }.disabled(audioManager.questionFilePath == nil)
                
                Button {
                    if let audioPath = audioManager.questionFilePath {
                        withAnimation {
                            showPlaybackControls = false
                            showProgressView.toggle()
                        }
                        Task {
                            await openAiManager.performOpenAiOperations(filepath: audioPath, userAskingQuestion: true) // is ASk View !
                            withAnimation {
                                showProgressView = false
                            }
                            ProgressTracker.shared.reset()
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .shadow(color: colorScheme == .dark ? .white: .gray, radius: 8)
                        .frame(width: playbackButtonDiamension, height: playbackButtonDiamension)
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(audioManager.questionFilePath == nil ? .gray.opacity(0.7) : .blue)
                }.disabled(audioManager.questionFilePath == nil)
                    .sensoryFeedback(.start, trigger: showPlaybackControls)
            }
        }
    }
    
    private func prepareForNewRecording() {
        print("prepareForeNewRecording -- AskView")
        withAnimation {
            showPlaybackControls = false
        }
        Task {
            openAiManager.clearManager()
            if audioManager.questionFilePath != nil {
                await _ = audioManager.deleteCurrentAudioFile(fromAskView: true)
            }
            do {
                try audioManager.setupRecorder(fromAskView: true)
            } catch (let error) {
                print("Error prepareForNewRecording() -> \(error)")
            }
        }
        checkRecordingExists()
        isAnimating = false
        isRecording = false
        playButtonIsDisabled = false
        showProgressView = false
        showtextEditorsAndButtonView = false
        showRecordButton = true //TODO: Check if showRecordButton in 'prepareForNewRecording' is ok in all edge cases
    }
    
    @ViewBuilder
    private func recordingButtonImage()-> some View {
        
        if isRecording {
            CoolButtonView(isRecording: true)
        } else {
            CoolButtonView(isRecording: false)
        }
    }
    
    @ViewBuilder
    private func permissionDeniedView() -> some View {
        VStack {
            Image(systemName: "mic.slash.circle.fill")
                .resizable()
                .renderingMode(.template)
            
                .scaledToFit()
                .shadow(radius: 10)
                .frame(width: 150, height: 150)
                .padding(.vertical)
                .foregroundStyle(.red)
            
            Text("Need your permission to use the microphone. Check your Settings.")
                .font(.headline)
                .fontWeight(.semibold)
        }.offset(y: 50)
    }
    
    private func startRecording() {
        
        if audioManager.questionFilePath == nil {
            prepareForNewRecording()
        }
        elapsedTime = 0.0
        audioManager.startRecording()
        isRecording = true
        withAnimation {
            showPlaybackControls = false
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation() {
                elapsedTime += 0.5
            }
        }
    }
    
    
    private func stopRecording() {
        
        isAnimating = false
        audioManager.stopRecording()
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        if let recordingURL = audioManager.questionFilePath {
            audioManager.recordingExistsAndHasContent(at: recordingURL) { exists in
                if exists {
                    DispatchQueue.main.async {
                        withAnimation {
                            recordingExists = exists
                            playButtonIsDisabled = exists
                            showPlaybackControls = exists
                            showRecordButton = !exists
                        }
                    }
                } else { prepareForNewRecording() }
            }
        }
    }
    
    private func checkPermission() {
        
        let audioSession = AVAudioApplication.shared
        switch audioSession.recordPermission {
        case .granted:
            permissionGranted = true
            do {
                try audioManager.setupRecorder(fromAskView: true)
            } catch (let error) {
                print("Error setupRecorder() -> \(error)")
            }
        case .denied:
            permissionGranted = false
        case .undetermined:
            audioManager.requestRecordPermission { granted in
                permissionGranted = granted
            }
        @unknown default:
            break // for potential future cases
        }
    }
}




#Preview {
    AskView()
        //.modelContainer(for: ResponseModel.self)
}
