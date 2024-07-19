//
//  QuestionView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.24.
//

import SwiftUI
import CloudKit

struct QuestionView: View {
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKitManager: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager

    @State private var question: String = ""
    @State private var thrownError: String = ""
    @State private var goButtonIsVisible: Bool = true
    @State private var selectedImageIndex: Int? = nil
    @State private var showNoInternet = false
    @State private var clearButtonIsVisible: Bool = false
    @State private var showFullImage: Bool = false
    @State private var showSettings: Bool = false
    @State private var fetchedImages: [UIImage] = []
    @State private var isLoading: Bool = false
    @State private var shake: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
        NavigationStack {
            ScrollView {
                
                HStack {
                    Image(systemName: "questionmark.bubble").bold()
                    Text("Question").bold()
                    Spacer()
                }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                    .navigationBarTitleView { LottieRepresentable(filename: "CloudDownload").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) }
                
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
                    VStack {
                    if self.thrownError != "" && openAiManager.stringResponseOnQuestion == "" {
                        
                        ErrorView(thrownError: thrownError)
                            .padding(.horizontal, 7)
                                .padding(.vertical)
                            ClearButton
                                .padding(.bottom)
                        
                    }
                    else if pineconeManager.receivedError != nil && openAiManager.stringResponseOnQuestion == "" {
                       
                        ErrorView(thrownError: thrownError)
                            .padding(.horizontal, 7)
                            .padding(.vertical)
                        ClearButton
                            .padding(.bottom)
                        
                    }
                    else if openAiManager.thrownError != "" && openAiManager.stringResponseOnQuestion == "" {
                        
                        ErrorView(thrownError: thrownError)
                            .padding(.horizontal, 7)
                            .padding(.vertical)
                        ClearButton
                            .padding(.bottom)
                        
                    }
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
                    withAnimation {
                        showFullImage = false }
                }
            }
//            .onChange(of: pineconeManager.receivedError) { _, receivedError in
//                if let unwrappedError = receivedError { withAnimation { self.thrownError = unwrappedError.localizedDescription } }
//            }
//            .onChange(of: openAiManager.thrownError) { _, errorMessage in
////                if errorMessage != "" {
//                withAnimation {
//                    self.thrownError = errorMessage }
////                }
//            }
            .onChange(of: shake) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            shake = false }
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
        .alert(isPresented: $showNoInternet) {
            Alert(
                title: Text("You are not connected to the Internet"),
                message: Text("Please check your connection"),
                dismissButton: .cancel(Text("OK"))
            )
        }
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
               showNoInternet = true
                if isLoading {
                    performClearTask()
                }
            }
        }
        .onDisappear {
            if thrownError != "" || openAiManager.thrownError != "" || pineconeManager.receivedError != nil {
                performClearTask()
            }
        }
    }

    }

    private var GoButton: some View {
        Button(action: performTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color("primaryAccent"))
                    .frame(height: buttonHeight)
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
                    .frame(height: buttonHeight)
                
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
            if isLoading { isLoading = false }
        }
            Task {
                await openAiManager.clearManager()
                await pineconeManager.clearManager()
            }
    }
    
    private func performTask() {

        guard !shake && !isLoading else { return }
        
        if question.count < 8 {
            withAnimation { shake = true }
            return
        }

        withAnimation {
            goButtonIsVisible = false
            hideKeyboard()
            isLoading = true
            progressTracker.reset()
        }

        Task {
            await openAiManager.requestEmbeddings(for: self.question, isQuestion: true)
            
            guard openAiManager.questionEmbeddingsCompleted else {
                isLoading = false
                return
            }

            do {
                progressTracker.setProgress(to: 0.35)
                try await pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion)
                
                if let pineconeResponse = pineconeManager.pineconeQueryResponse {
                    for match in pineconeResponse.matches {
                        let id = match.id
                        Task {
                            do {
                                if let image = try await cloudKitManager.fetchImageItem(uniqueID: id) {
                                    print("Successfully fetched image from iCloud with id: \(id)")
                                    await MainActor.run {
                                        fetchedImages.append(image)
                                    }
                                }
                            } catch let error as AppNetworkError {
                                await MainActor.run {
                                    self.thrownError = error.errorDescription
                                }
                            } catch let error as AppCKError {
                                await MainActor.run {
                                    self.thrownError = error.errorDescription
                                }
                            }
                            catch let error as CKError {
                                await MainActor.run {
                                    self.thrownError = error.customErrorDescription }
                            }
                            catch {
                                await MainActor.run {
                                    self.thrownError = error.localizedDescription
                                }
                            }
                        }
                    }
                    try await openAiManager.getGptResponse(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
                }
                
                await MainActor.run {
                    withAnimation {
                        isLoading = false
                        clearButtonIsVisible = true
                    }
                }
            } catch let error as AppNetworkError {
                await MainActor.run {
                    self.thrownError = error.errorDescription
                    self.isLoading = false
                    self.clearButtonIsVisible = true
                }
            } catch let error as AppCKError {
                await MainActor.run {
                    self.thrownError = error.errorDescription
                    self.isLoading = false
                    self.clearButtonIsVisible = true
                }
            } catch {
                await MainActor.run {
                    self.thrownError = error.localizedDescription
                    self.isLoading = false
                    self.clearButtonIsVisible = true
                }
            }
        }
    }
    
}


struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        let openAiManager = OpenAIManager()
        let pineconeManager = PineconeManager()
        let progressTracker = ProgressTracker()
        
        QuestionView()
            .environmentObject(openAiManager)
            .environmentObject(pineconeManager)
            .environmentObject(progressTracker)
    }
}
