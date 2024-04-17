//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 17.04.24.
//

import SwiftUI

import SwiftUI

struct NewAddInfoView: View {
    @Binding var newInfo: String
    @Binding var relevantFor: String
    @Binding var apiCallInProgress: Bool
    @Binding var thrownError: String
    @Binding var showAlert: Bool
    @State private var showTopBar = false
    @State private var topBarMessage = ""
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    TextEditor(text: $newInfo)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(0.3)
                                .foregroundColor(Color.gray)
                        )
                        .frame(minHeight: 100)
                        .padding(.bottom)
                }
                HStack {
                    Image(systemName: "person.bubble").bold()
                    Text("Relevant For:").bold()
                    Spacer()
                }.font(.callout)
                    .padding(.bottom, 12)
                
                TextEditor(text: $relevantFor)
                    .frame(minHeight: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                    )
                    .padding(.bottom)
                
                if !apiCallInProgress && thrownError == "" {
                    
                    Button(action: addNewInfoAction) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                                .frame(height: 70)
                                .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                            Text("Add").font(.title2).bold().foregroundColor(.white)
                        }
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.bottom, keyboardResponder.currentHeight > 0 ? 75 : 0)
                }
                else if apiCallInProgress && thrownError == "" {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.6), Color.gray]), startPoint: .top, endPoint: .bottom))
                            .frame(height: 70)
                            .padding(.horizontal)
                            .padding(.bottom, keyboardResponder.currentHeight > 0 ? 35 : 0)
                            .shadow(color: .gray.opacity(0.9), radius: 3, x: 3, y: 3)
                        Text(openAiManager.progressText).font(.title2).bold().foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            
                           
                    }
                }
                
                if apiCallInProgress && progressTracker.progress < 0.99 && thrownError == "" {
                    CircularProgressView(progressTracker: progressTracker).padding(.horizontal)
                }
                Text("Error: \(thrownError)")
                Text(showAlert.description)
                
            }
            if showTopBar {
                TopNotificationBar(message: topBarMessage, show: $showTopBar)
                    .transition(.move(edge: .top))
                    .onDisappear {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            topBarMessage = ""
                        }
                    }
            }
            
        }
        //        .alert(isPresented: $showAlert) {
//            Alert(title: Text("Simple Error"), message: Text("An error occurred: \(thrownError)"), dismissButton: .default(Text("OK")))
//        }

    }

    private func addNewInfoAction() {
        
        self.apiCallInProgress = true
        Task { await performNetworkOperations() }
    }
    
    private func performNetworkOperations() async {
        
        await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
        
        if openAiManager.embeddingsCompleted {
            await MainActor.run {
                openAiManager.progressText = ""
            }
            let metadata = toDictionary(type: "GeneralKnowledge", desc: self.newInfo, relevantFor: self.relevantFor)
            do {
                //MARK: TEST THROW
//                let err = AppCKError.UnableToGetNameSpace
//                throw err
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
        }
    }
}

struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        let progress = ProgressTracker()
        let openAI = OpenAIManager()
        let pinecone = PineconeManager()
        NewAddInfoView(newInfo: .constant("Test string"), relevantFor: .constant("Tester"), apiCallInProgress: .constant(false), thrownError: .constant(""), showAlert: .constant(false))
            .environmentObject(pinecone)
            .environmentObject(openAI)
            .environmentObject(progress)
            .environmentObject(responder)
    }
}

