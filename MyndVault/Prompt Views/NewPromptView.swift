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
    @State var showAlert = false
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var notificationManager: NotificationViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var selectedType: typeOptions = .question
    @State var question: String = ""
    @State var relevantFor: String = ""
    @State var newInfo: String = ""
    @State var reminderText: String = ""
    @State var reminderDate: Date = Date()
    @State var replyText: String = ""
    @State var thrownError: String = ""
    @State var apiCallInProgress: Bool = false
    @State var showTopBar: Bool = false
    @State var topBarMessage: String = ""
    
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
        ZStack {
            
        VStack {
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
            //                .transition(.opacity)
                .padding(.bottom, 12)
            ScrollView {
                if selectedType == .addNew {
                    
                    NewAddInfoView(newInfo: $newInfo, relevantFor: $relevantFor, apiCallInProgress: $apiCallInProgress, thrownError: $thrownError, showAlert: $showAlert, showTopBar: $showTopBar, topBarMessage: $topBarMessage)
                    //                    .transition(.opacity)
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeManager)
                        .environmentObject(progressTracker)
                        .environmentObject(keyboardResponder)
                    
                }
                
                if selectedType == .question {
                    QuestionView(question: $question, thrownError: $thrownError)
                    
                }
                if selectedType == .reminder {
                    reminderView()
                    
                }
            }
            Spacer()
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
//        .animation(.default, value: selectedType)
        .padding()
        .alert(isPresented: $showNetworkError) {
            Alert(
                title: Text("No Internet Connection"),
                message: Text("Please check your internet connection and try again."),
                dismissButton: .cancel(Text("OK")) {
                    self.question = ""
                    self.relevantFor = ""
                    
                    Task {
                        await openAiManager.clearManager()
                        pineconeManager.clearManager()
                    }
                }
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error while saving."),
                message: Text(thrownError.description),
                dismissButton: .default(Text("OK")) {
                    Task {
                        pineconeManager.clearManager()
                        await openAiManager.clearManager()
                        
                    }
                    thrownError = ""
                }
            )
        }
    }
    
    
    //MARK: reminderView()
    @ViewBuilder
    private func reminderView() -> some View {
        HStack {
            TextEditor(text: $reminderText)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 80, maxHeight: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom)
                .padding(.horizontal, 6)
                .padding(.top, 7)
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
                        .frame(height: 60)
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

