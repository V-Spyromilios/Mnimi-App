//
//  NotificationViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import Foundation
import UserNotifications

struct CustomNotification: Identifiable, Equatable {
    let id: String
    var title: String
    var notificationBody: String
    var date: Date
}

final class NotificationViewModel: ObservableObject {
    
    @Published var scheduledNotifications: [CustomNotification] = []
    
    init() { fetchScheduledNotifications() }
    
    func fetchScheduledNotifications() {
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { scheduledNotifications in
            DispatchQueue.main.async {
                self.scheduledNotifications = scheduledNotifications.map { notification in
                    
                    let trigger = notification.trigger
                    var date1: Date
                    if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
                        date1 = calendarTrigger.nextTriggerDate() ?? Date()
                        
                    } else if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
                        date1 = timeIntervalTrigger.nextTriggerDate() ?? Date()
                    }
                    else { date1 = Date() }
                    return CustomNotification(
                        id: notification.identifier,
                        title: notification.content.title,
                        notificationBody: notification.content.body,
                        date: date1
                    )
                }
            }
        }
        print("Fetched \(scheduledNotifications.count) scheduled notifications")
    }
    
    
    func deleteNotification(with id: String) {
        
        scheduledNotifications.removeAll { $0.id == id }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
}

