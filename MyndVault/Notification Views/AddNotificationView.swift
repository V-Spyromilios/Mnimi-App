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
    @State private var showAlert = false
    @State private var notificationBody: String = ""
    @State private var notificationTitle: String = ""
    @State private var date: Date = Date()
    @State private var alertTitle: String = ""
    @State private var shake: Bool = false
    @State private var repeatInterval: RepeatInterval = .none
    @Binding var show: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
        ZStack {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            ScrollView {
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 10.0)
                                    .stroke(lineWidth: 1)
                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                    .foregroundColor(Color.gray)
                            )
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
                        //                        .foregroundColor(.white)
                        //                        .background(Color.black)
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
                    
                    
                    VStack {
                        HStack {
                            Image(systemName: "repeat").bold()
                                .font(.callout)
                            Text("Repeat").bold()
                                .font(.callout)
                            Spacer()
                        }.padding(.bottom, 7)
                        
                        Picker("", selection: $repeatInterval) {
                            ForEach(RepeatInterval.allCases) { interval in
                                Text(interval.description).tag(interval)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical)
                    
                    
                    
                    HStack {
                        Button(action: {
                            
                            if shake { return }
                            if notificationBody.isEmpty || notificationTitle.isEmpty {
                                withAnimation { shake = true }
                                return
                            }
                            
                            Task { scheduleNotification() }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: rectCornerRad)
                                    .fill(Color.customLightBlue)
                                    .frame(height: buttonHeight)
                                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                
                                Text("Save").font(.title2).bold()
                                    .foregroundColor(Color.buttonText)
                            } .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .accessibilityLabel("save")
                        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
                        .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
                        .animation(.easeInOut, value: keyboardResponder.currentHeight)
                      
                    }
                    Spacer()
                }.padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    if keyboardResponder.currentHeight > 0 {
                        Button {
                            hideKeyboard()
                        } label: {
                            
                            HideKeyboardLabel()
                            
                        }.accessibilityLabel("Hide Keyboard")
                    }
                    Button {
                        show = false
                    } label: {
                        LottieRepresentable(filename: "CancelButton").frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
                    }.padding(.leading)

                   
                }
            }
        }
        .navigationBarTitleView {
            
            HStack {
                Text("Add New Notification").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                //                    LottieRepresentable(filename: "").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
            }
            
        }
    }
       
        
        
        .statusBar(hidden: true)
        //        .background(Color.primaryBackground)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("\(alertTitle)"),
                message: Text(""),
                dismissButton: .cancel(Text("OK")) {
                   show = false
                }
            )
        }
        .onChange(of: shake) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                }
            }
        }
    }
    
    //    private func scheduleNotification() {
    //
    //        if notificationTitle.isEmpty || notificationBody.isEmpty { return }
    //
    //        let content = UNMutableNotificationContent()
    //        content.title = self.notificationTitle != "" ? self.notificationTitle : "Mynd Vault Notification!"
    //        content.body = self.notificationBody
    //        content.sound = UNNotificationSound.defaultCritical
    //
    //        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: self.date)
    //
    //        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    //
    //        let identifier = UUID().uuidString
    //
    //        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    //
    //        UNUserNotificationCenter.current().add(request) { error in
    //            if let error = error {
    //                DispatchQueue.main.async {
    //                    //TODO: Show Error pop-up
    //                    alertTitle = "Oops! \nError saving the Notification, please try again."
    //                    showAlert = true
    //                    print("Error scheduling notification: \(error.localizedDescription)")
    //                }
    //            }
    //            else if error == nil {
    //                DispatchQueue.main.async {
    //                    //TODO: Show Confirmation pop-up
    //                    alertTitle = "Notification Saved!"
    //                    showAlert = true
    //                    manager.fetchScheduledNotifications()
    //
    //                }
    //            }
    //        }
    //    }
    
    
    
    private func scheduleNotification() {

        if notificationTitle.isEmpty || notificationBody.isEmpty { return }
        
        let content = UNMutableNotificationContent()
        content.title = self.notificationTitle
        content.body = self.notificationBody
        content.sound = UNNotificationSound.default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: self.date)
        var triggers: [UNNotificationTrigger] = []
        
        switch repeatInterval {
        case .none:
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            triggers.append(trigger)
        case .daily:
            dateComponents = Calendar.current.dateComponents([.hour, .minute], from: self.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            triggers.append(trigger)
        case .weekly:
            dateComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: self.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            triggers.append(trigger)
        case .weekdays:
            let weekdays = [2, 3, 4, 5, 6] // Monday to Friday (2 to 6)
            for weekday in weekdays {
                dateComponents.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                triggers.append(trigger)
            }
        case .weekends:
            let weekends = [1, 7] // Sunday and Saturday (1 and 7)
            for weekend in weekends {
                dateComponents.weekday = weekend
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                triggers.append(trigger)
            }
        }
        
        for trigger in triggers {
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        alertTitle = "Oops! \nError saving the Notification, please try again."
                        showAlert = true
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                } else {
                    DispatchQueue.main.async {
                        alertTitle = "Notification Saved!"
                        showAlert = true
                        manager.fetchScheduledNotifications()
                    }
                }
            }
        }
    }
}

#Preview {
    AddNotificationView(show: .constant(true))
}



