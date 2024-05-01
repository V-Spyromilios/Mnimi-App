//
//  AddNotificationView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.05.24.
//

import SwiftUI

struct AddNotificationView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    var dismissAction: () -> Void
    
    @State private var notificationBody: String = ""
    @State private var notificationTitle: String = ""
    @State private var date: Date = Date()
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "pencil").bold()
                        .font(.callout)
                    Text("Title").bold()
                        .font(.callout)
                    Spacer()
                }
                HStack {
                    TextEditor(text: $notificationTitle)
                        .fontDesign(.rounded)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 50)
//                        .onAppear { focus = .notificationTitle }
//                        .focused($focus, equals: .notificationTitle)
//                        .onSubmit {
//                            focus = .notificationBody
//                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
                        .overlay{
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(0.3)
                                .foregroundColor(Color.gray)
                        }
                        .padding(.bottom)
                }
                HStack {
                    Image(systemName: "pencil").bold()
                        .font(.callout)
                    Text("Notification").bold()
                        .font(.callout)
                    Spacer()
                }
                HStack {
                    TextEditor(text: $notificationBody)
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
                    
                    
                    
                }
                
                
                HStack {
                    
                    Image(systemName: "clock").bold()
                        .font(.callout)
                    Text("When?").bold()
                        .font(.callout)
                    
                    DatePicker(
                        "",
                        selection: $date,
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
                Spacer()
                    
            }.padding()
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("\(alertTitle)"),
                            message: Text(""),
                dismissButton: .cancel(Text("OK")) {
                    dismissAction()
                }
            )
        }
    }
    
    
    
    private func scheduleNotification() {
        
        let content = UNMutableNotificationContent()
        content.title = self.notificationTitle != "" ? self.notificationTitle : "Mynd Vault Notification!"
        content.body = self.notificationBody
        content.sound = UNNotificationSound.defaultCritical
        
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: self.date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    //TODO: Show Error pop-up
                    alertTitle = "Oops! \nError saving the Notification, please try again."
                    showAlert = true
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
            else if error == nil {
                DispatchQueue.main.async {
                    //TODO: Show Confirmation pop-up
                    alertTitle = "Notification Saved!"
                   showAlert = true
                    manager.fetchScheduledNotifications()
                   
                }
            }
        }
    }
}

#Preview {
    AddNotificationView(dismissAction: {print("Dismissed from Preview")})
}



