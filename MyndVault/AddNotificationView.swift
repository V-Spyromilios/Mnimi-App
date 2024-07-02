//
//  AddNotificationView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.05.24.
//

import SwiftUI

struct AddNotificationView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    var dismissAction: () -> Void
    
    @State private var notificationBody: String = ""
    @State private var notificationTitle: String = ""
    @State private var date: Date = Date()
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @Environment(\.colorScheme) var colorScheme
    
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
                        .frame(height: smallTextEditorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .overlay{
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
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
                        .frame(height: textEditorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .overlay{
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
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
                                .fill(Color.primaryAccent)
                                .frame(height: 60)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)

                            Text("Save").font(.title2).bold()
                                .foregroundColor(Color.buttonText)
                        } .padding(.vertical, 8)
                            .contentShape(Rectangle())
                           
                    }.frame(maxWidth: .infinity).accessibilityLabel("save")
                    Spacer()
                }
                Spacer()
            }.padding()
                .toolbar {
                    if keyboardResponder.currentHeight > 0 {
                        Button {
                            hideKeyboard()
                        } label: {
                            Circle()
                                .foregroundStyle(Color.gray.opacity(0.6))
                                .frame(height: 30)
                                .shadow(radius: toolbarButtonShadow)
                                .overlay {
                                    HideKeyboardLabel()
                                }
                                }
                        }
                }
        }.background { Color.primaryBackground}
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
        
        if notificationTitle.isEmpty || notificationBody.isEmpty { return }

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



