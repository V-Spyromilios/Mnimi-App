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
    @EnvironmentObject var cloudKitManager: CloudKitViewModel
    @State private var showSettings: Bool = false
    @State private var fetchedImages: [UIImage] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                HStack {
                    Image(systemName: "questionmark.bubble").bold()
                    Text("Question").bold()
                    Spacer()
                }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                    .navigationTitle("Ask me")
                    .navigationBarTitleDisplayMode(.large)
                
                TextEditor(text: $question)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(height: textEditorHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(colorScheme == .light ? Color.gray : Color.blue)
                    )
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
                    }
                    
                    if openAiManager.stringResponseOnQuestion != "" {
                        HStack {
                            Image(systemName: "quote.bubble").bold()
                            Text("Reply").bold()
                            Spacer()
                        }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
                                .foregroundColor(colorScheme == .light ? Color.gray : Color.blue)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)

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
                        VStack {
                                // Display each image
                                ForEach(0..<fetchedImages.count, id: \.self) { index in
                                    withAnimation {
                                        Image(uiImage: fetchedImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(lineWidth: 1)
                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                                    .foregroundColor(colorScheme == .light ? Color.gray : Color.blue)
                                            )
                                    }
                                }
                            
                        }
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
                                    .foregroundStyle(Color.buttonText)
                                    .frame(height: 30)
                                    .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                                    .overlay {
                                        HideKeyboardLabel()
                                    }
                                    }
                            }
                            
                        
                        Button {
//                            print("Before toggling settings: \(showSettings)")
                                showSettings.toggle()
//                                print("After toggling settings: \(showSettings)")
                        } label: {
                            Circle()
                                .foregroundStyle(Color.buttonText)
                                .frame(height: 30)
                                .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                                .overlay {
                                    Text("⚙️")
                                    .accessibilityLabel("settings") }
                        }
                    }
                }
            }
            .background {
                Color.primaryBackground.ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(showSettings: $showSettings)
            }
        }
    }
    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color("primaryAccent"))
                    .frame(height: 60)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                Text("Go").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("Go")
            }
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
                    .fill(Color.primaryAccent)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                    .frame(height: 60)

                Text("OK").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("Clear and reset")
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
            fetchedImages = []
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
                        for match in pineconeResponse.matches {
                            let id = match.id
                            Task {
                                do {
                                    //TODO: fetc works ok, save does not work.
                                    if  let image = try await cloudKitManager.fetchImageItem(uniqueID: id) {
                                        print("Succesfully fetched image from icloud with id : \(id)")
                                        DispatchQueue.main.async {
                                            fetchedImages.append(image)
                                        }
                                        
                                    } else {
                                        print("Malakia, unable to fetch image from id: \(id)")
                                    }
                                }
                                catch {
                                    print("Failed to fetch image item: \(error.localizedDescription)")
                                }
                            }
                        }
                        try await openAiManager.getGptResponse(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
                        
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
