//
//  ToDoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import SwiftUI
import UserNotifications

struct ToDoView: View {
    
    @EnvironmentObject var manager: NotificationViewModel
    
    let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
    }
    
    var body: some View {
        VStack {
            Text("Notifications").font(.title).bold().padding()
            
            // Directly using condition to decide between List and alternative view
            if !manager.scheduledNotifications.isEmpty || !manager.deliveredNotifications.isEmpty {
                List {
                    Section(header: Text("Scheduled Notifications")) {
                        ForEach(manager.scheduledNotifications) { notification in
                            NavigationLink(destination: NotificationDetailView(notification: notification)) {
                                VStack(alignment: .leading) {
                                    Text(notification.title).font(.headline)
                                    Text(notification.body).font(.subheadline)
                                }
                            }
                        }.onDelete(perform: manager.removeScheduledNotification)
                    }

                    Section(header: Text("Delivered Notifications")) {
                        ForEach(manager.deliveredNotifications) { notification in
                            VStack(alignment: .leading) {
                                Text(notification.title).font(.headline)
                                Text(notification.body).font(.subheadline)
                            }
                            .foregroundStyle(.gray)
                        }.onDelete(perform: manager.removeDeliveredNotification)
                    }
                }.listStyle(InsetGroupedListStyle())
            } else {
                ContentUnavailableView("Notifications will appear here", systemImage: "bell.slash.fill")

            }
        }
        .onAppear {
            manager.fetchDeliveredNotifications()
            manager.fetchScheduledNotifications()
        }
    }

}


#Preview {
    ToDoView()

}
