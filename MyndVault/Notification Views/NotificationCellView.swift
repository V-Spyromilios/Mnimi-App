//
//  NotificationCellView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import SwiftUI

struct NotificationCellView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var manager: NotificationViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var popUpOptions: [String] = [
        "Delete",
        "Edit..."
    ]
    
    @State private var showPopover: Bool = false
    @GestureState private var isLongPressing = false
    
    @Binding var edited: Bool
    var notification: CustomNotification
    var shadowRadius: CGFloat = 10
    @StateObject var viewModel: CountdownTimer
    
    @State var showAddNotificationSheet = false
    @State private var showNotificationEdit: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    init(notification: CustomNotification, edited: Binding<Bool>) {

        self.notification = notification
        self._edited = edited
        _viewModel = StateObject(wrappedValue: CountdownTimer(targetDate: notification.date))
    }
    
    var body: some View {
       
            VStack {
                
                HStack {
                    Text(notification.title)
                        .font(.title)
                        .foregroundStyle(.notificationsTitle)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .padding(.bottom, 2)
                        .padding(.top, 5)
                        .padding(.leading)
                    Spacer()
                }
                HStack {
                    Text(notification.notificationBody)
                        .foregroundStyle(colorScheme == .light ? .black : .white.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .padding(.bottom, 10)
                        .padding(.leading)
                    Spacer()
                }
            
            Text(formatDate(notification.date))
                .font(.title2)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            
            Text(viewModel.timeRemaining)
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .padding(.bottom, 18)
            
        }.frame(maxWidth: .infinity)
            .overlay {
                Button(action: {
                    showPopover.toggle()
                }) {
                    LottieRepresentable(filename: "Vertical Dot Menu", loopMode: .playOnce)
                        .frame(width: 55, height: 55)
                        .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                        .offset(x: 100, y: -100)
                }
                .popover(isPresented: $showPopover, attachmentAnchor: .point(.topLeading), content: {
                    popOverContent()
                })
            }
           
            .padding(.top)
            .background(Color.cardBackground)
            .cornerRadius(10)
            .shadow(radius: shadowRadius)
//            .onTapGesture {
//                showPopover = true
//            }
           
            .fullScreenCover(isPresented: $showNotificationEdit) {
                NotificationEditView(notification: notification, edited: $edited)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }.accessibilityLabel("Cancel")
                        }
                    }
            }
            
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "No date provided" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    private func popOverContent() -> some View  {
        VStack(alignment: .leading, spacing: 7, content: {
            ForEach(popUpOptions, id: \.self) { option in
                Button(action: {
                    
                    if option == "Delete" {
                        Task {
                            
                            manager.deleteNotification(with: notification.id)
                        }
                    } else {
                        self.showNotificationEdit.toggle()
                    }
                    
                }, label: {
                    if option == popUpOptions.first {
                        Text(option).font(.body).foregroundStyle(.red)
                    }
                    else {
                        Text(option).font(.body).foregroundStyle(Color.secondary)
                    }
                }).padding(.horizontal)
                    .accessibilityLabel(option == "Delete" ? "Delete" : "Edit")
                
                if option != popUpOptions.last {
                    Divider()
                }
            }
        }).presentationCompactAdaptation(.popover)
    }
}


//struct NotificationDetailView_Previews: PreviewProvider {
//
//    var model: CountdownTimer = CountdownTimer(targetDate: .now + 10)
//
//    static var previews: some View {
//        NotificationDetailView(notification: CustomNotification(
//            id: "notif_001", title: "Meeting Reminder",
//            notificationBody: "Don't forget to attend the weekly meeting",
//            date: Date().addingTimeInterval(3600)
//
//        ), viewModel: model,  )
//    }
//}


// _viewModel = StateObject(wrappedValue: CountdownTimer(targetDate: notification.date ?? .now + 2)
