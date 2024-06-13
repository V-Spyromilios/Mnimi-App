//
//  ToDoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    @State private var showAddNotification: Bool = false
    
    @State var selectedNotification: CustomNotification?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if !manager.scheduledNotifications.isEmpty {
//                        Text("Scheduled")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .textCase(.uppercase)
//                            .padding(.bottom)
//                            .padding(.leading, 9)
                        ForEach(manager.scheduledNotifications) {notification in
                            
                            NotificationCellView(notification: notification)
                                .padding(.bottom).padding(.horizontal, 9)
                        }
                    } else {
                        ContentUnavailableView("No Notifications yet!", systemImage: "bell.slash.fill", description: Text("Start by adding a new Notification.")).offset(y: contentUnaivalableOffset)
                    }
                }
            }
            .navigationTitle("Notifications 🔔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showAddNotification.toggle() }
                    } label: {
                        Circle()
                        
                            .foregroundStyle(.white)
                            .frame(height: 30)
                            .shadow(radius: toolbarButtonShadow)
                            .overlay {
                                Text("➕")}
                    }.padding().accessibilityLabel("Add new notification")
                }
            }
        }.sheet(isPresented: $showAddNotification) {
            AddNotificationView(dismissAction: {
                showAddNotification = false
            })
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = NotificationViewModel()
       
        
        return NotificationsView()
            .environmentObject(manager)
    }
}


