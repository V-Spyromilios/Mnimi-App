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

    @State var selectedDate = Date()
    @State var description: String = ""
    var notification: CustomNotification
    
    var body: some View {

        Form {
            TextEditor(text: $description).frame(height: 100)

            DatePicker(
                "Select Date and Time",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
//            .datePickerStyle(GraphicalDatePickerStyle())
            .frame(maxHeight: 400)
          
            Button(action: {
                let id = notification.id
                let newDate = selectedDate
                let newDescription = description
                Task {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
                    await MainActor.run {
                        rescheduleNotification(identifier: id, title: "Memory Notification", body: newDescription, date: newDate)
                        print("Rescheduled for \(newDate)")
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    
                }
            }, label: {
                Text("Reschedule").font(.title2).bold()
            })
            
        }
        .onAppear {
            if let date = notification.date {
                selectedDate = date
            }
            self.description = notification.body
        }
        .toolbar {
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }.navigationTitle("Edit Notification")
    }
}

private func rescheduleNotification(identifier: String, title: String, body: String, date: Date) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default

    let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error RESCHEDULING notification: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NotificationEditView(notification: CustomNotification(id: "2Sf3GT", title: "Custom Notification", body: "Remind me tomorrow to watch Big Bang Theory", date: Date()))
}
