//
//  NotificationViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 28.02.24.
//

import Foundation
import UserNotifications

struct CustomNotification: Identifiable {
    let id: String
    var title: String
    var notificationBody: String
    var date: Date?

}

class NotificationViewModel: ObservableObject {
    @Published var deliveredNotifications: [CustomNotification] = []
    @Published var scheduledNotifications: [CustomNotification] = []

    init() {
//        self.deliveredNotifications = deliveredNotifications
//        self.scheduledNotifications = scheduledNotifications
        
        fetchDeliveredNotifications()
        fetchScheduledNotifications()
    }

    func fetchDeliveredNotifications() {

        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
            DispatchQueue.main.async {
                self.deliveredNotifications = deliveredNotifications.map { notification in
                    CustomNotification(
                        id: notification.request.identifier,
                        title: notification.request.content.title,
                        notificationBody: notification.request.content.body
                    )
                }
            }
        }
    }
    
    func fetchScheduledNotifications() {

        UNUserNotificationCenter.current().getPendingNotificationRequests { scheduledNotifications in
            DispatchQueue.main.async {
                self.scheduledNotifications = scheduledNotifications.map { notification in

                                    let trigger = notification.trigger
                                    var date: Date?
                                    if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
                                        date = calendarTrigger.nextTriggerDate()
                                        
                                    } else if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
                                        date = timeIntervalTrigger.nextTriggerDate()
                                    }
                   return CustomNotification(
                        id: notification.identifier,
                        title: notification.content.title,
                        notificationBody: notification.content.body,
                        date: date
                    )
                }
                print(self.deliveredNotifications)
            }
        }
        print("Fetched \(scheduledNotifications.count) scheduled notifications")
    }

    
    func deleteNotification(with id: String) {
     
        scheduledNotifications.removeAll { $0.id == id }
        deliveredNotifications.removeAll { $0.id == id }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

}

