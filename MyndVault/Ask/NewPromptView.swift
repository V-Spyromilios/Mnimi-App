//
//  NewPromptView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 15.03.24.
//

import SwiftUI
import NotificationCenter
import Network


struct NewPromptView: View {
    
    @ObservedObject var viewModel = SpeechRecognitionViewModel()
    @State var showNetworkError = false
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var notificationManager: NotificationViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
//    @Environment(\.modelContext) var modelContext
    
    @State var selectedType: typeOptions = .question
    @State var question: String = ""
    @State var relevantFor: String = ""
    @State var newInfo: String = ""
    @State var reminderText: String = ""
    @State var reminderDate: Date = Date()
    @State var replyText: String = ""
    @State var thrownError: String = ""
    @State var apiCallInProgress: Bool = false
    
    @FocusState private var focusField: Field?

    private enum Field {
        case addNew
        case question
        case relevantFor
        case reminder
    }
    
    enum typeOptions: String, CaseIterable, Identifiable {
        case question = "Query "
        case addNew = "Add New Info "
        case reminder = "Reminder "
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .addNew:
                return "plus.message"
            case .question:
                return "questionmark.circle"
            case .reminder:
                return "lightbulb.min.badge.exclamationmark"
            }
        }
        var title: String {
            switch self {
            case .addNew:
                return "Add new knowledge:"
            case .question:
                return "Ask me something:"
            case .reminder:
                return "Set a reminder:"
            }
        }
    }
    
    var body: some View {

        ScrollView {
                Picker("", selection: $selectedType) {
                    ForEach(typeOptions.allCases) { type in
                        Text(type.rawValue.capitalized)
                    }
                }.pickerStyle(.segmented)
                    .padding(.bottom, 20)
                    .padding(.top, 2)
                HStack {
                    Image(systemName: selectedType.icon).bold()
                    Text(selectedType.title).bold()
                    Spacer()
                }.font(.callout)
                    .transition(.opacity)
                    .padding(.bottom, 12)
                
                if selectedType == .addNew {
                    
                    addNewInfo()
                        .transition(.opacity)
                }
                
                if selectedType == .question {
                    questionView()
                        .transition(.opacity)
                }
                if selectedType == .reminder {
                    reminderView()
                        .transition(.opacity)
                }
                
            }
            .animation(.default, value: selectedType)
            .padding()
            .alert(isPresented: $showNetworkError) {
                Alert(
                    title: Text("No Internet Connection"),
                    message: Text("Please check your internet connection and try again."),
                    dismissButton: .cancel(Text("OK")) {
                        openAiManager.clearManager()
                        pineconeManager.clearManager()
                    }
                )
            }
        
    }

    //MARK: addNewInfo
    @ViewBuilder
    private func addNewInfo() -> some View {
        
        HStack {
            TextEditor(text: $newInfo)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }

                .frame(minHeight: 100)
                .padding(.bottom)
                .onAppear { }
                .onSubmit { focusField = .relevantFor }
                .focused($focusField, equals: .addNew)
        }
        HStack {
            Image(systemName: "person.bubble").bold()
            Text("Relevant For:").bold()
            Spacer()
        }.font(.callout)
            .padding(.bottom, 12)

        TextEditor(text: $relevantFor)
                .frame(minHeight: 40)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom, 50)
                .onSubmit {
                    focusField = nil //TODO: test if dismisses the keyboard
                }
                .focused($focusField, equals: .relevantFor)
                
        HStack {
        Button(action: {
            self.apiCallInProgress = true
            Task {

                await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
               
                if openAiManager.embeddingsCompleted {
                    await MainActor.run {
                        openAiManager.progressText = ""
                    }
                    let metadata = toDictionary(type: "GeneralKnowledge", desc: self.newInfo, relevantFor: self.relevantFor)
                        do {
                            
                            try await pineconeManager.upsertDataToPinecone(id: UUID().uuidString, vector: openAiManager.embeddings, metadata: metadata)

                        } catch(let error) {
                            print("Error while upserting catched by the View: \(error.localizedDescription)")
                            thrownError = error.localizedDescription
                        }
                    
                } else { print("AddNewView :: ELSE blocked from openAiManager.EmbeddingsCompleted ")}
            }
            focusField = nil
            self.apiCallInProgress = false
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 70)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                Text("Add").font(.title2).bold().foregroundColor(.white)
            }
        }.frame(maxWidth: .infinity) // to get all 'safe' width, in all possible screens
                .padding(.bottom, keyboardResponder.currentHeight > 0 ? 25: 0) //Check if correct
            Spacer()
            
            if progressTracker.progress < 0.99 && (openAiManager.progressText != "" || pineconeManager.progressText != "") && thrownError == "" {
                CircularProgressView(progressTracker: progressTracker).padding(.horizontal)
            }
            if thrownError != "" {
                Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(.yellow).font(.largeTitle).frame(width: 60, height: 60)
                    .animation(.easeInOut, value: thrownError)
            }
            if thrownError == "" && pineconeManager.upsertSuccesful {
                Image(systemName: "checkmark.icloud.fill").foregroundStyle(.green).font(.largeTitle).frame(width: 60, height: 60)
                    .animation(.easeInOut, value: pineconeManager.upsertSuccesful)
            }
           
        }.frame(height: 68)
        HStack {
                if openAiManager.progressText != "" && thrownError == "" {
                    Text(openAiManager.progressText).font(.caption2).padding(.top, 12)
                        .animation(.easeInOut, value: openAiManager.progressText)
                }
                if pineconeManager.progressText != "" && thrownError == "" {
                    Text(pineconeManager.progressText).font(.caption2).padding(.top, 12)
                        .animation(.easeInOut, value: pineconeManager.progressText)
                }
                else if thrownError != "" || pineconeManager.upsertSuccesful {
              
                    if thrownError != "" {
                        Text(thrownError).font(.caption2).bold().padding(.top, 12)
                            .animation(.easeInOut, value: thrownError)
                    } else {
                        Text("Info Saved!").font(.caption2).bold().padding(.top, 12)
                            .animation(.easeInOut, value: pineconeManager.upsertSuccesful)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                            progressTracker.progress = 0.0 //check if ok
                            openAiManager.clearManager()
                            pineconeManager.clearManager()
                            self.newInfo = ""
                            self.relevantFor = ""
                            self.thrownError = ""
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: rectCornerRad)
                                .fill(thrownError == "" ? greenGradient : yellowGradient)
                                .frame(height: 60)
                                .shadow(color: thrownError == "" ? .green : .yellow.opacity(0.9), radius: 3, x: 3, y: 3)
                            Text(thrownError == "" ? "OK" : "Reset").font(.title2).bold().foregroundColor(.white)
                        }
                    }).frame(width: 70, height: 60).padding(.trailing, 8)
            }
        }.frame(maxWidth: .infinity)
            .padding(.bottom, max(0, keyboardResponder.currentHeight))// Ensure non-negative padding
        .animation(.easeInOut, value: pineconeManager.upsertSuccesful)
        
    }

    //MARK: questionView()
    @ViewBuilder
    private func questionView() -> some View {
        
        TextEditor(text: $question)
            .multilineTextAlignment(.leading)
            .frame(minHeight: 100)
            .overlay{
                RoundedRectangle(cornerRadius: 10.0)
                    .stroke(lineWidth: 1)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
            }
            .padding(.bottom)
            .onSubmit {
              focusField = nil
            }
            .focused($focusField, equals: .question)
            
        HStack {
           
            Button(action: {
                Task {
                    await openAiManager.requestEmbeddings(for: self.question ,isQuestion: true)
                    if openAiManager.questionEmbeddingsCompleted {
                        print("View if openAiManager.embeddingsCompleted OK")
                        let metadata = toDictionary(type: "question", desc: self.question, relevantFor: self.relevantFor)
                        await MainActor.run {
                            openAiManager.progressText = ""
                        }
                        do {
                            ProgressTracker.shared.setProgress(to: 0.35)
                            
                            try await pineconeManager.queryPinecone(vector: openAiManager.embeddingsFromQuestion, metadata: metadata)
                        } catch {
                            print("try await pineconeManger.queryPinecone: \(error)")
                            thrownError = error.localizedDescription
                            
                        }
                        
                        print("returned from queryPinecone")
                    }
                    if let pineconeResponse = pineconeManager.pineconeQueryResponse {
                        let question = self.question
                        print("returned from gptMetadataResponseOnQuestion?.description")
                        do {
                            try await openAiManager.getGptResponseAndConvertTextToSpeech(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
                        } catch {
                            thrownError = error.localizedDescription
                           
                        }
                        await MainActor.run {
                            openAiManager.progressText = ""
                            pineconeManager.progressText = ""
                        }
                    }
                }
                focusField = nil
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: rectCornerRad)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                        .frame(height: 70)
                        .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                    Text("Go").font(.title2).bold().foregroundColor(.white)
                }
                .contentShape(Rectangle())
            }.frame(maxWidth: .infinity)
            
        .padding(.vertical, 8)
            Spacer()
            if thrownError != "" {
                Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(.yellow).font(.largeTitle).frame(width: 60, height: 60).animation(.easeInOut, value: thrownError)
            }
            if progressTracker.progress < 0.99 && (openAiManager.progressText != "" || pineconeManager.progressText != "") && thrownError == "" {
                CircularProgressView(progressTracker: progressTracker).padding(.trailing, 8)
                   
            }
            else if thrownError == "" && openAiManager.stringResponseOnQuestion != "" && progressTracker.progress >= 0.99 {
                Image(systemName: "checkmark.icloud.fill").foregroundStyle(.green).font(.largeTitle).frame(width: 60, height: 60).animation(.easeInOut, value: openAiManager.stringResponseOnQuestion)
            }
           
        }.frame(height: 68)

        if openAiManager.progressText != "" && thrownError == "" {
            Text(openAiManager.progressText).font(.caption2)
                .animation(.easeInOut, value: openAiManager.progressText)
        }
        if pineconeManager.progressText != "" && thrownError == "" {
            Text(pineconeManager.progressText).font(.caption2)
                .animation(.easeInOut, value: pineconeManager.progressText)
        }
        else if thrownError != "" || (openAiManager.stringResponseOnQuestion != "" && progressTracker.progress >= 0.99) {
            VStack {
                if thrownError != "" {
                        Text(thrownError).font(.caption2).bold()
                            .animation(.easeInOut, value: thrownError)
                    
                } else if openAiManager.stringResponseOnQuestion != "" {
                    Text("\"\(openAiManager.stringResponseOnQuestion)\"").font(.caption).fontDesign(.rounded).multilineTextAlignment(.leading)
                }
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            progressTracker.progress = 0.0 //check if ok
                            openAiManager.clearManager()
                            pineconeManager.clearManager()
                            self.question = ""
                            self.thrownError = ""
                            
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(thrownError == "" ? greenGradient : yellowGradient)
                                .frame(height: 70)
                                .shadow(color: thrownError == "" ? .green : .yellow.opacity(0.9), radius: 3, x: 3, y: 3) // subtle shadow for a lifted effect
                            Text(thrownError == "" ? "OK" : "Reset").font(.title2).bold().foregroundColor(.white)
                        }
                    }).frame(maxWidth: .infinity)
                }
            }.animation(.easeInOut, value: openAiManager.stringResponseOnQuestion)
        }
    }

    //MARK: reminderView()
    @ViewBuilder
    private func reminderView() -> some View {
        HStack {
            TextEditor(text: $reminderText)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .frame(minHeight: 100)
                .onAppear { }
            
        }

        HStack {
            
                Image(systemName: "clock").bold()
                .font(.callout)
                Text("When?").bold()
            .font(.callout)
               
            DatePicker(
                "",
                selection: $reminderDate,
                displayedComponents: [.date, .hourAndMinute]
            ).padding(.vertical, 8)
        }
        HStack {
            Button(action: {
                Task { scheduleNotification() }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: rectCornerRad)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                        .frame(height: 70)
                        .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                    Text("Save").font(.title2).bold().foregroundColor(.white)
                } .padding(.vertical, 8)
                .contentShape(Rectangle())
            }.frame(maxWidth: .infinity)
            Spacer()
        }
    }

    //MARK: scheduleNotifications()
    private func scheduleNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder !"
        content.body = self.reminderText
        content.sound = UNNotificationSound.defaultCritical
        
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: self.reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    //TODO: Show Error pop-up
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
            else if error == nil {
                DispatchQueue.main.async {
                    //TODO: Show Confirmation pop-up
                    print("Notification scheduled for (date): \(self.reminderDate)")
                    notificationManager.fetchScheduledNotifications()
                    //MARK: HERE
                }
            }
        }
    }

}

#Preview {
    NewPromptView()
        .environmentObject(OpenAIManager())
        .environmentObject(PineconeManager())
        .environmentObject(AudioManager())
        .environmentObject(ProgressTracker())
        .environmentObject(NotificationViewModel())
        .environmentObject(KeyboardResponder())
}

