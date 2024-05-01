//
//  QuestionView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.24.
//

import SwiftUI

struct QuestionView: View {

    @Binding var question: String
    @Binding var thrownError: String
    @State var goButtonIsVisible: Bool = true
    @State private var clearButtonIsVisible: Bool = false
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    
    var body: some View {
        NavigationStack {
        ScrollView {
            //        VStack {
            HStack {
                Image(systemName: "questionmark.bubble").bold()
                Text("Query").bold()
                Spacer()
            }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                .navigationTitle("Search 🔍")
            //                .transition(.opacity)
//                .padding(.bottom, 12)
            TextEditor(text: $question)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay {
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom)
                .padding(.horizontal, 7)
            VStack {
                if self.thrownError != "" && openAiManager.stringResponseOnQuestion == "" {
                    ErrorView(thrownError: thrownError)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                else if pineconeManager.receivedError != nil && openAiManager.stringResponseOnQuestion == "" {
                    ErrorView(thrownError: pineconeManager.receivedError.debugDescription.description)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                else if openAiManager.thrownError != "" && openAiManager.stringResponseOnQuestion == "" {
                    ErrorView(thrownError:  openAiManager.thrownError)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                if progressTracker.progress < 0.99 && (openAiManager.progressText != "" || pineconeManager.progressText != "") && thrownError == "" && openAiManager.thrownError == "" && (pineconeManager.receivedError == nil) {
                    CircularProgressView(progressTracker: progressTracker).padding()
                }
                else if goButtonIsVisible && openAiManager.stringResponseOnQuestion == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                    GoButton
                }
                if openAiManager.stringResponseOnQuestion != "" {
                    Text(openAiManager.stringResponseOnQuestion)
                        .fontDesign(.rounded)
                        .fontWidth(.expanded)
                        .font(.title2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .shadow(radius: 7)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(0.3)
                                .foregroundColor(Color.gray)
                        }
                    ClearButton
                }
            }
            
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button {
                            hideKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                }
            }
        }
    }
    }
    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                Text("Go").font(.title2).bold().foregroundColor(.white)
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                Text("OK").font(.title2).bold().foregroundColor(.white)
            }
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    private func performClearTask() {
        
        withAnimation {
            self.question = ""
            self.thrownError = ""
            self.clearButtonIsVisible = false
            self.goButtonIsVisible = true
            Task {
                await openAiManager.clearManager()
                pineconeManager.clearManager()
            }
        }
    }
    
    private func performTask() {
        hideKeyboard()
        withAnimation {
            goButtonIsVisible = false }
        Task {
            await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
            if openAiManager.questionEmbeddingsCompleted {
                let metadata = toDictionary(type: "question", desc: self.question, relevantFor: "")
                await MainActor.run {
                    openAiManager.progressText = ""
                }
                do {
                    ProgressTracker.shared.setProgress(to: 0.35)
                    try await pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion, metadata: metadata)
                } catch {
                    thrownError = error.localizedDescription
                    clearButtonIsVisible = true
                }
                if let pineconeResponse = pineconeManager.pineconeQueryResponse {
                    do {
                        try await openAiManager.getGptResponseAndConvertTextToSpeech(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
                    } catch {
                        thrownError = error.localizedDescription
                        withAnimation {
                            clearButtonIsVisible = true }
                    }
                    await MainActor.run {
                        openAiManager.progressText = ""
                        pineconeManager.progressText = ""
                    }
                }
            }
        }
        if thrownError == "" {
            withAnimation {
                clearButtonIsVisible = true
            }
        }
    }
    
}


struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        let openAiManager = OpenAIManager()
        let pineconeManager = PineconeManager()
        let progressTracker = ProgressTracker()
        
        QuestionView(question: .constant("What is the name of my manager?"),
                     thrownError: .constant(""))
        .environmentObject(openAiManager)
        .environmentObject(pineconeManager)
        .environmentObject(progressTracker)
    }
}
