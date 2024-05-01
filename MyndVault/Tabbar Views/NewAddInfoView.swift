//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI

struct NewAddInfoView: View {
    @Binding var newInfo: String
    @Binding var relevantFor: String
    @Binding var apiCallInProgress: Bool
    @Binding var thrownError: String
    @Binding var showAlert: Bool
    @Binding var showTopBar: Bool
    @Binding var topBarMessage: String
    @State private var clearButtonIsVisible: Bool = false
    @State private var saveButtonIsVisible: Bool = true
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    var body: some View {
        NavigationStack {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: "plus.bubble").bold()
                    Text("info").bold()
                    Spacer()
                }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                HStack {
                    TextEditor(text: $newInfo)
                        .fontDesign(.rounded)
                        .font(.title2)
                        .frame(height: 110)
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
                }
                HStack {
                    Image(systemName: "person.bubble").bold()
                    Text("Relevant For:").bold()
                    Spacer()
                }.font(.callout).padding(.horizontal, 7)
                    .padding(.bottom, 8)
                
                TextEditor(text: $relevantFor)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .frame(minHeight: 40, maxHeight: 50)
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
                
                
                //MARK: Calls the addNewInfoAction. keeps track of apiCallInProgress
                
                
                if self.thrownError != "" {
                    ErrorView(thrownError: thrownError)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                else if pineconeManager.receivedError != nil {
                    ErrorView(thrownError: pineconeManager.receivedError.debugDescription.description)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                else if openAiManager.thrownError != "" {
                    ErrorView(thrownError: openAiManager.thrownError)
                        .padding(.top)
                        .padding(.horizontal)
                    ClearButton
                }
                if progressTracker.progress < 0.99 && thrownError == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                    CircularProgressView(progressTracker: progressTracker).padding()
                }
                
                else if saveButtonIsVisible && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                    SaveButton
                }
            }.navigationTitle("Add New 📝")
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
    
    private var SaveButton: some View {
        Button(action: addNewInfoAction) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                Text("Save").font(.title2).bold().foregroundColor(.white)
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
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 60)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                Text("OK").font(.title2).bold().foregroundColor(.white)
            }
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    private func performClearTask() {
        
        withAnimation {
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
        hideKeyboard()
        self.saveButtonIsVisible = false
        self.apiCallInProgress = true
        Task { await performNetworkOperations() }
    }
    
    private func performNetworkOperations() async {
        
        await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
        
        if openAiManager.embeddingsCompleted {
            let metadata = toDictionary(type: "GeneralKnowledge", desc: self.newInfo, relevantFor: self.relevantFor)
            do {
                //MARK: TEST THROW
                //                let malakia = AppCKError.UnableToGetNameSpace
                //                throw malakia
                try await pineconeManager.upsertDataToPinecone(id: UUID().uuidString, vector: openAiManager.embeddings, metadata: metadata)
                if pineconeManager.upsertSuccesful {
                    await MainActor.run {
                        self.topBarMessage = "Info saved."
                        self.showTopBar = true
                        self.relevantFor = ""
                        self.newInfo = ""
                    }
                }
            } catch(let error) {
                await MainActor.run {
                    self.thrownError = error.localizedDescription
                    self.showAlert = true
                    
                    print("Error while upserting catched by the View: \(error.localizedDescription)")
                }
            }
        } else { print("AddNewView :: ELSE blocked from openAiManager.EmbeddingsCompleted ")}
        
        await MainActor.run {
            self.apiCallInProgress = false
            self.newInfo = ""
            self.relevantFor = ""
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
                       relevantFor: .constant("Tester"), apiCallInProgress: .constant(false),
                       thrownError: .constant(""),
                       showAlert: .constant(false),
                       showTopBar: .constant(false),
                       topBarMessage: .constant(""))
        .environmentObject(pinecone)
        .environmentObject(openAI)
        .environmentObject(progress)
        .environmentObject(responder)
    }
}
