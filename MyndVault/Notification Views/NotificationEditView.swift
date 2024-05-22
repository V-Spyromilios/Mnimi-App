//
//  NotificationEditView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import SwiftUI
import UserNotifications

struct NotificationEditView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDate = Date()
    @State private var title: String = ""
    @State private var notificationBody: String = ""
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    var notification: CustomNotification
    
    var body: some View {
       
        VStack {
            HStack {
                Image(systemName: "pencil").bold()
                    .font(.callout)
                Text("Title").bold()
                
                Spacer()
            }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
            
            TextEditor(text: $title).frame(height: smallTextEditorHeight)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom)
                .padding(.horizontal, 7)
            
            
            HStack {
                Image(systemName: "pencil").bold()
                    .font(.callout)
                Text("Notification").bold()
                    .font(.callout)
                Spacer()
            }.font(.callout).padding(.horizontal, 7)
                .padding(.bottom, 8)
            
            TextEditor(text: $notificationBody).frame(height: textEditorHeight)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom)
                .padding(.horizontal, 7)
            
            
            HStack {
                Image(systemName: "clock").bold()
                    .font(.callout)
                Text("Select Date and Time").bold()
                    .font(.callout)
                Spacer()
            }.font(.callout).padding(.horizontal, 7)
                .padding(.bottom, 10)
            
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            ).padding(.bottom)
                .padding(.horizontal, 7)
            
            
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
                        .fill(Color.customDarkBlue)
                        .frame(height: 60)
                        .shadow(radius: 7)
                    Text("Reschedule").font(.title2).bold().foregroundColor(.white)
                } .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .shadow(radius: 7)
                    .accessibilityLabel("Save changes and reschedule")
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .padding(.bottom, keyboardResponder.currentHeight > 0 ? 10 : 0)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
            
            .onAppear {
                if let date = notification.date {
                    selectedDate = date
                }
                self.title = notification.title
                self.notificationBody = notification.notificationBody
            }
            .toolbar {
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }.accessibilityLabel("Cancel")
                }
            }.navigationTitle("Edit Notification")
            Spacer()
        }
    
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
