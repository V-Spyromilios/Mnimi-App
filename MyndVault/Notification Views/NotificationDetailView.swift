//
//  NotificationDetailView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import SwiftUI

struct NotificationDetailView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    @State private var popUpOptions: [String] = [
        "Delete",
        "Edit..."
    ]
    
    @State private var showPopover: Bool = false
    @GestureState private var isLongPressing = false
    
    var notification: CustomNotification
    @StateObject var viewModel: CountdownTimer
    @State var scale: CGFloat = 1.0
    @State var shadowRadius: CGFloat = 10
    
    @State var showAddNotificationSheet = false
    @State private var showNotificationEdit: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    init(notification: CustomNotification) {

        self.notification = notification
        _viewModel = StateObject(wrappedValue: CountdownTimer(targetDate: notification.date ?? .now + 2))
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            Text(notification.title)
                .font(.title)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .padding(.bottom, 2)
                .padding(.top, 5)
            
            Text(notification.notificationBody)
                .italic()
                .padding(.bottom, 20)
            
            
            Text(formatDate(notification.date))
                .font(.title2)
                .fontDesign(.rounded)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                
            
            Text(viewModel.timeRemaining)
                .font(.caption)
                .contentTransition(.numericText())
                .padding(.bottom, 18)

        }.frame(maxWidth: .infinity)
        
            .padding(.horizontal)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
            .scaleEffect(scale)
            .onTapGesture {
                showPopover = true
            }
            .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), content: {
                popOverContent()
            })
        
        
            .sheet(isPresented: $showNotificationEdit) {
                NotificationEditView(notification: notification)
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
                        Text(option).font(.body).foregroundStyle(Color.britishRacingGreen)
                    }
                }).padding(.horizontal)
                
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
