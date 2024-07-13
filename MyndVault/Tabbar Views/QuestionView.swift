//
//  QuestionView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.24.
//

import SwiftUI

struct QuestionView: View {
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKitManager: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme

    @Binding var question: String
    @State var thrownError: String = ""
    @State var goButtonIsVisible: Bool = true
    @State var selectedImageIndex: Int? = nil
    @State private var clearButtonIsVisible: Bool = false
    @State private var showFullImage: Bool = false
    @State private var showSettings: Bool = false
    @State private var fetchedImages: [UIImage] = []
    @State private var isLoading: Bool = false
    @State private var shake: Bool = false
    
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
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(Color.gray)
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

                            LottieRepresentable(filename: "Ai Cloud",loopMode: .loop, speed: 0.8)
                                .frame(height: 300)
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
                                //.foregroundColor(Color.gray)
                            
                            Text(openAiManager.stringResponseOnQuestion)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity,minHeight: 100, alignment: .leading)
                                .padding(7)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(lineWidth: 1)
                                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                                        .foregroundColor(Color.gray)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .light ? Color.white:  Color.black)
                                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                )
                        }
                        .padding(.bottom)
                        .padding(.horizontal, 7)
                        LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
                            
                            ForEach(0..<fetchedImages.count, id: \.self) { index in
                                withAnimation {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: fetchedImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(lineWidth: 1)
                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                                    .foregroundColor(Color.gray)
                                            )
                                        Button(action: {
                                            
                                            self.selectedImageIndex = index
                                            withAnimation { showFullImage = true }
                                        }) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .foregroundColor(Color.white)
                                                .background(Color.black.opacity(0.6))
                                                .padding()
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            
                        }
                        ClearButton
                            .padding(.bottom)
                    }
                }
                
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if keyboardResponder.currentHeight > 0 {
                            Button {
                                hideKeyboard()
                            } label: {
                                Circle()
                                    .foregroundStyle(Color.gray.opacity(0.6))
                                    .frame(height: 30)
                                    .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                                    .overlay {
                                        HideKeyboardLabel()
                                    }
                            }
                        }
                        
                        
                        Button {
                            showSettings.toggle()
                        } label: {
                            Circle()
                                .foregroundStyle(Color.gray.opacity(0.6))
                                .frame(height: 30)
                                .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                                .overlay {
                                    Text("⚙️")
                                    .accessibilityLabel("settings") }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullImage) {
                if let selectedImageIndex = self.selectedImageIndex {
                               FullScreenImage(show: $showFullImage, image: fetchedImages[selectedImageIndex])
                           } else {
                               Text("No Image Selected").bold()
                           }
            }
            .onChange(of: selectedImageIndex) { oldValue, newValue in //to observe selectedIndex as remains null for the fullscreen cover.
                        if newValue == nil {
                            showFullImage = false
                        }
                    }
            .onChange(of: shake) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shake = false
                    }
                }
            }
            .background {
                Color.primaryBackground.ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
        
        
        
    }

    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color("primaryAccent"))
                    .frame(height: 60)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                Text("Go").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("Go")
            }
            .contentShape(Rectangle())
            
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.primaryAccent)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
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

        if shake || isLoading { return }
        if question.count < 8 {
            withAnimation { shake = true }
            return
        }

        isLoading = true
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
            await MainActor.run { isLoading = false } //TODO: Check if works ok protecting the Button during api call
        }
        if thrownError == "" {
            withAnimation { clearButtonIsVisible = true }
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
