import SwiftUI
import UserNotifications

struct NotificationEditView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDate = Date()
    @State private var title: String = ""
    @State private var notificationBody: String = ""
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @Environment(\.colorScheme) var colorScheme
    var notification: CustomNotification
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "pencil").bold()
                            .font(.callout)
                        Text("Title").bold()
                        Spacer()
                    }
                    .font(.callout)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    VStack {
                    TextEditor(text: $title)
                        .fontDesign(.rounded)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 150) // Adjust height as needed
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
                                .foregroundColor(Color.gray)
                        )
                       
                }
                        .padding(.bottom)
                    
                    HStack {
                        Image(systemName: "pencil").bold()
                            .font(.callout)
                        Text("Notification").bold()
                            .font(.callout)
                        Spacer()
                    }
                    .font(.callout)
                    .padding(.bottom, 8)
                    .padding(.top, 12)
                    
                    TextEditor(text: $notificationBody)
                        .fontDesign(.rounded)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 150) // Adjust height as needed
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
                                .foregroundColor(Color.gray)
                        )
                        .padding(.bottom)
                    
                    HStack {
                        Image(systemName: "clock").bold()
                            .font(.callout)
                        Text("Select\nDate and Time").bold()
                            .font(.callout)
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    .font(.callout)
                    .padding(.bottom, 10)
                    .padding(.top, 12)
                    
                    Button(action: {
                        Task {
                            let id = notification.id
                            let newDate = selectedDate
                            let newTitle = title
                            let notificationBody = notification.notificationBody
                            Task {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
                                await MainActor.run {
                                    rescheduleNotification(identifier: id, title: "Mynd Vault: \(newTitle)", body: notificationBody, date: newDate)
                                    print("Rescheduled for \(newDate)")
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: rectCornerRad)
                                .fill(Color.primaryAccent)
                                .frame(height: 60)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                            Text("Reschedule").font(.title2).bold().foregroundColor(Color.buttonText)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        
                        .accessibilityLabel("Save changes and reschedule")
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 7)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .onAppear {
                    if let date = notification.date {
                        selectedDate = date
                    }
                    self.title = notification.title
                    self.notificationBody = notification.notificationBody
                }
            }
            .navigationTitle("Edit Notification")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
                if keyboardResponder.currentHeight > 0 {
                    ToolbarItemGroup(placement: .topBarTrailing) {
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
                    }
             
            }.background { Color.primaryBackground.ignoresSafeArea() }
        }
        .statusBar(hidden: true)
    }
}

private func rescheduleNotification(identifier: String, title: String, body: String, date: Date) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
    
    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error RESCHEDULING notification: \(error.localizedDescription)")
        }
    }
}

struct NotificationEditView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        
        NotificationEditView(notification: CustomNotification(id: "2Sf3GT", title: "Custom Notification", notificationBody: "Remind me tomorrow to watch Big Bang Theory", date: Date()))
            .environmentObject(responder)
    }
}
