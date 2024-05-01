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
    @State var showAddNotificationSheet = false
    
    let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if !manager.scheduledNotifications.isEmpty {
                        Text("Scheduled")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(.uppercase)
                            .padding(.bottom)
                        
                        ForEach(manager.scheduledNotifications) { notification in
                            NavigationLink(destination: NotificationDetailView(notification: notification)) {
                                NotificationsListCell(notification: notification)
                                    .padding(.bottom)
                            }
                        }
                        .onDelete(perform: manager.removeScheduledNotification)
                    }
                    
                    if !manager.deliveredNotifications.isEmpty {
                        Text("Delivered")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textCase(.uppercase)
                            .padding(.vertical)
                        
                        ForEach(manager.deliveredNotifications) { notification in
                            NotificationsListCell(notification: notification)
                                .padding(.bottom)
                                .foregroundStyle(.gray)
                        }
                        .onDelete(perform: manager.removeDeliveredNotification)
                    }
                }
                .padding()
            }
            .navigationTitle("Notifications 🔔")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddNotificationSheet.toggle()
                        
                    }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .accessibilityLabel("Add new reminder")
                    }
                }
            }
            .sheet(isPresented: $showAddNotificationSheet) {
                AddNotificationView(dismissAction: {
                    showAddNotificationSheet = false
                })
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = NotificationViewModel()
        manager.fetchMockNotifications()
        
        return NotificationsView()
            .environmentObject(manager)
    }
}


