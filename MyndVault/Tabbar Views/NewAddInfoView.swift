//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI
//import KeyboardObserving

struct NewAddInfoView: View {
    @Binding var newInfo: String
//    @Binding var relevantFor: String
    @Binding var apiCallInProgress: Bool
    @State var thrownError: String = "" 
    @Binding var showAlert: Bool
    
    @State private var showPopUp: Bool = false
    @State private var popUpMessage: String = ""
    
    @State private var clearButtonIsVisible: Bool = false
    @State private var saveButtonIsVisible: Bool = true
    @State private var showSettings: Bool = false
    
    @State private var animateStep: Int = 0
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    var body: some View {
       
            GeometryReader { geometry in
                NavigationStack {
//                    ScrollView {
                    VStack {
                        HStack {
                            Image(systemName: "plus.bubble").bold()
                            Text("info").bold()
                            Spacer()
                        }.font(.callout).padding(.top,12).padding(.bottom, 8).padding(.horizontal, 7)
                            
                        HStack {
                            TextEditor(text: $newInfo)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                                .frame(height: textEditorHeight)
                                .frame(maxWidth: idealWidth(for: geometry.size.width))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10.0)
                                        .stroke(lineWidth: 1)
                                        .opacity(0.3)
                                        .foregroundColor(Color.gray)
                                )
                                .padding(.bottom)
                                .padding(.horizontal, 7)
                                .toolbar {
                                   
                                    ToolbarItemGroup(placement: .topBarTrailing) {
                                        if keyboardResponder.currentHeight > 0 {
                                            Button {
                                                hideKeyboard()
                                            } label: {
                                                HideKeyboardLabel()
                                            }
                                        }
                                        Button {
                                            showSettings.toggle()
                                        } label: {
                                            Circle()
                                                .foregroundStyle(.white)
                                                .frame(height: 30)
                                                .shadow(radius: toolbarButtonShadow)
                                                .overlay {
                                                    Text("⚙️")
                                                    .accessibilityLabel("Settings") }
                                        }
                                    }
                                    
                                }
                        }.popover(isPresented: $showPopUp, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                            
                            popOverView(animateStep: $animateStep, show: $showPopUp)
                            .presentationCompactAdaptation(.popover)
                           
                        }
                        
                        //MARK: Calls the addNewInfoAction. keeps track of apiCallInProgress
                        
                        
                        if self.thrownError != "" {
                            ErrorView(thrownError: thrownError)
                                .padding(.top)
                                .padding(.horizontal)
                            ClearButton
                                .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                        }
                        else if pineconeManager.receivedError != nil {
                            ErrorView(thrownError: pineconeManager.receivedError.debugDescription.description)
                                .padding(.top)
                                .padding(.horizontal)
                            ClearButton
                                .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                        }
                        else if openAiManager.thrownError != "" {
                            ErrorView(thrownError: openAiManager.thrownError)
                                .padding(.top)
                                .padding(.horizontal)
                            ClearButton
                                .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                        }
                        else if saveButtonIsVisible && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                            SaveButton
                               
                        }
                        if apiCallInProgress && progressTracker.progress < 0.99 && thrownError == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                            CircularProgressView(progressTracker: progressTracker).padding()
                        }
                        Spacer()
                        //                                .frame(height: keyboardResponder.currentHeight)
                            .navigationTitle("Add New 📝")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
            
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
    }
    
    private var SaveButton: some View {
        Button(action: addNewInfoAction) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.customDarkBlue)
                    .shadow(radius: 7)
                    .frame(height: 60)
                    
                Text("Save").font(.title2).bold().foregroundColor(.white)
                    .accessibilityLabel("save")
            }
            .contentShape(Rectangle())
            .shadow(radius: 7)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.horizontal)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
//        .id("SubmitButton")
//        .padding(.bottom, keyboardResponder.currentHeight > 0 ? 10 : 0)
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.customDarkBlue)
                    
                    .frame(height: 60)
                    
                Text("OK").font(.title2).bold().foregroundColor(.white)
                    .accessibilityLabel("clear") 
            }
            .contentShape(Rectangle())
            .shadow(radius: 7)
        }
        .padding(.top, 12)
        .padding(.horizontal)
//        .padding(.bottom, 10)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
        .frame(maxWidth: .infinity)
    }
    
    private func performClearTask() {
        
        withAnimation {
            progressTracker.reset()
            self.thrownError = ""
            self.clearButtonIsVisible = false
            Task {
                await openAiManager.clearManager()
                pineconeManager.clearManager()
            }
            self.apiCallInProgress = false
            self.saveButtonIsVisible = true
        }
    }
    
    private func addNewInfoAction() {
        
        if newInfo.count < 5 { return }

        hideKeyboard()
        self.saveButtonIsVisible = false
        self.apiCallInProgress = true
        progressTracker.reset()
        Task { await addInfoOperations() }
    }
    
    private func addInfoOperations() async {
        
        await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
        
        if openAiManager.embeddingsCompleted {
            let metadata = toDictionary(desc: self.newInfo)
            do {
                //MARK: TEST THROW
//                                let miaMalakia = AppCKError.UnableToGetNameSpace
//                                throw miaMalakia
                try await pineconeManager.upsertDataToPinecone(id: UUID().uuidString, vector: openAiManager.embeddings, metadata: metadata)
                if pineconeManager.upsertSuccesful {
                    await MainActor.run {
                        self.popUpMessage = "Info saved."
                        self.showPopUp = true
                        self.newInfo = ""
                    }
                }
            } catch(let error) {
                await MainActor.run {
                    //TODO: test if only one button appears after Error:
                    self.apiCallInProgress = false
                    self.thrownError = error.localizedDescription
                    self.showAlert = true
                    
                    print("Error while upserting catched by the View: \(error.localizedDescription)")
                }
            }
        } else { print("AddNewView :: ELSE blocked from openAiManager.EmbeddingsCompleted ")}
        
        await MainActor.run {
            self.apiCallInProgress = false
            self.newInfo = ""
//            self.relevantFor = ""
            self.saveButtonIsVisible = true
        }
    }
}

struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        let progress = ProgressTracker()
        let openAI = OpenAIManager()
        let pinecone = PineconeManager()
        NewAddInfoView(newInfo: .constant("Test string"),
                       apiCallInProgress: .constant(false),
                       showAlert: .constant(false))
        .environmentObject(pinecone)
        .environmentObject(openAI)
        .environmentObject(progress)
        .environmentObject(responder)
    }
}
