//
//  QuestionView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.24.
//

import SwiftUI

struct QuestionView: View {
    
    @Binding var question: String
    @State var thrownError: String = ""
    @State var goButtonIsVisible: Bool = true
    @State private var clearButtonIsVisible: Bool = false
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @State private var showSettings: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                HStack {
                    Image(systemName: "questionmark.bubble").bold()
                    Text("Question").bold()
                    Spacer()
                }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                    .navigationTitle("Search 🔍")
                    .navigationBarTitleDisplayMode(.inline)
                
                TextEditor(text: $question)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(height: textEditorHeight)
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
                            .padding(.bottom)
                    }
                    else if pineconeManager.receivedError != nil && openAiManager.stringResponseOnQuestion == "" {
                        ErrorView(thrownError: pineconeManager.receivedError.debugDescription.description)
                            .padding(.top)
                            .padding(.horizontal)
                        ClearButton
                            .padding(.bottom)
                    }
                    else if openAiManager.thrownError != "" && openAiManager.stringResponseOnQuestion == "" {
                        ErrorView(thrownError:  openAiManager.thrownError)
                            .padding(.top)
                            .padding(.horizontal)
                        ClearButton
                            .padding(.bottom)
                    }
                    VStack {
                        if goButtonIsVisible && openAiManager.stringResponseOnQuestion == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                            GoButton
                                .padding(.bottom)
                        }
                        else if !goButtonIsVisible && progressTracker.progress < 0.99 && thrownError == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                            CircularProgressView(progressTracker: progressTracker).padding()
                        }
//                        Text("GoButton: \(goButtonIsVisible) :: Progress: \(progressTracker.progress) \n Errors: \(thrownError), \(openAiManager.thrownError), \(String(describing: pineconeManager.receivedError?.localizedDescription))")
                    }
                    
                    if openAiManager.stringResponseOnQuestion != "" {
                        HStack {
                            Image(systemName: "quote.bubble").bold()
                            Text("Reply").bold()
                            Spacer()
                        }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white)) // Assuming a white background
                                .shadow(radius: 5)

                            Text(openAiManager.stringResponseOnQuestion)
                                .padding(5)
                                .font(.title2)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.leading)
                                .frame(minHeight: textEditorHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.bottom)
                        .padding(.horizontal, 7)
                        ClearButton
                            .padding(.bottom)
                    }

                }
                
                .toolbar {
//                    ToolbarItemGroup(placement: .keyboard) {
//                        HStack {
//                            Spacer()
//                            Button {
//                                hideKeyboard()
//                            } label: {
//                                Image(systemName: "keyboard.chevron.compact.down")
//                                    .accessibilityLabel("hide keyboard")
//                            }
//                        }
//                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if keyboardResponder.currentHeight > 0 {
                            Button {
                                hideKeyboard()
                            } label: {
                                Circle()
                                    .foregroundStyle(.white)
                                    .frame(height: 30)
                                    .shadow(radius: toolbarButtonShadow)
                                    .overlay {
                                        HideKeyboardLabel()
                                    }
                                    }
                            }
                            
                        
                        Button {
                            print("Before toggling settings: \(showSettings)")
                                showSettings.toggle()
                                print("After toggling settings: \(showSettings)")
                        } label: {
                            Circle()
                                .foregroundStyle(.white)
                                .frame(height: 30)
                                .shadow(radius: toolbarButtonShadow)
                                .overlay {
                                    Text("⚙️")
                                    .accessibilityLabel("settings") }
                        }
                    }
                }
            }.fullScreenCover(isPresented: $showSettings) {
                SettingsView(showSettings: $showSettings)
            }
        }
    }
    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color("customDarkBlue"))
                    .shadow(radius: 7)
//
                    .frame(height: 60)
                Text("Go").font(.title2).bold().foregroundColor(.white)
                    .accessibilityLabel("Go")
            }
            .shadow(radius: 7)
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.customDarkBlue)
                    .shadow(radius: 7)
                    .frame(height: 60)
                    .shadow(radius: 7)
                Text("OK").font(.title2).bold().foregroundColor(.white)
                    .accessibilityLabel("Clear and reset")
            }
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .shadow(radius: 7)
    }
    
    private func performClearTask() {
        
        withAnimation {
            self.question = ""
            self.thrownError = ""
            self.clearButtonIsVisible = false
            self.goButtonIsVisible = true
            progressTracker.reset()
            Task {
                await openAiManager.clearManager()
                pineconeManager.clearManager()
            }
        }
    }
    
    private func performTask() {

        if question.count < 8 { return }

        hideKeyboard()
        progressTracker.reset()
        withAnimation { goButtonIsVisible = false }

        Task {
            await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
            if openAiManager.questionEmbeddingsCompleted {
                
                do {
                    progressTracker.setProgress(to: 0.35)
                    try await pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
                } catch {
                    thrownError = error.localizedDescription
                    clearButtonIsVisible = true
                }
                if let pineconeResponse = pineconeManager.pineconeQueryResponse {
                    do {
                        try await openAiManager.getGptResponse(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
//                        ProgressTracker.shared.setProgress(to: 0.97)
//                        ProgressTracker.shared.setProgress(to: 0.99)
                        
                    } catch {
                        thrownError = error.localizedDescription
                        withAnimation {
                            clearButtonIsVisible = true }
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
        
        QuestionView(question: .constant("What is the name of my manager ?"))
        .environmentObject(openAiManager)
        .environmentObject(pineconeManager)
        .environmentObject(progressTracker)
    }
}
