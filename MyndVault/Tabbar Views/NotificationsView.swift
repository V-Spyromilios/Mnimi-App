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

                        ForEach(manager.scheduledNotifications) {notification in
                            
                            NotificationCellView(notification: notification)
                                .padding(.bottom).padding(.horizontal, 9)
                        }
                    } else {
                        ContentUnavailableView("No Notifications yet!", systemImage: "bell.slash.fill", description: Text("Start by adding a new Notification.")).offset(y: contentUnaivalableOffset)
                    }
                }.padding(.top, 14)
            }
            .navigationTitle("Notifications 🔔")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showAddNotification.toggle() }
                    } label: {
                        Circle()
                        
                            .foregroundStyle(.buttonText)
                            .frame(height: 30)
                            .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                            .overlay {
                                Text("➕")}
                    }.padding().accessibilityLabel("Add new notification")
                }
            }
            .background { Color.primaryBackground.ignoresSafeArea() }
        }
       
        .sheet(isPresented: $showAddNotification) {
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


