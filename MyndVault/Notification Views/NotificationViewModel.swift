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
    var body: String
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
    
    func fetchMockNotifications() {
        self.scheduledNotifications = [
            CustomNotification(id: "1234", title: "Meeting", body: "Team meeting at 3 PM"),
            CustomNotification(id: "49403", title: "Dinner", body: "Dinner with family at 7 PM"),
            CustomNotification(id: "1234", title: "Meeting", body: "Team meeting at 3 PM"),
            CustomNotification(id: "49403", title: "Dinner", body: "Dinner with family at 7 PM"),
            CustomNotification(id: "1234", title: "Meeting", body: "Team meeting at 3 PM"),
            CustomNotification(id: "49403", title: "Dinner", body: "Dinner with family at 7 PM"),
            CustomNotification(id: "1234", title: "Meeting", body: "Team meeting at 3 PM"),
            CustomNotification(id: "49403", title: "Dinner", body: "Dinner with family at 7 PM")
            ]
    }
    
    func fetchDeliveredNotifications() {

        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
            DispatchQueue.main.async {
                self.deliveredNotifications = deliveredNotifications.map { notification in
                    CustomNotification(
                        id: notification.request.identifier,
                        title: notification.request.content.title,
                        body: notification.request.content.body
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
                        body: notification.content.body,
                        date: date
                    )
                }
                print(self.deliveredNotifications)
            }
        }
        print("Fetched \(scheduledNotifications.count) scheduled notifications")
    }
    
    func removeDeliveredNotification(at indexSet: IndexSet) {

        let identifiersToRemove = indexSet.map { deliveredNotifications[$0].id }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)

        deliveredNotifications.remove(atOffsets: indexSet)
    }
    
    func removeScheduledNotification(at indexSet: IndexSet) {

        let identifiersToRemove = indexSet.map { scheduledNotifications[$0].id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)

        scheduledNotifications.remove(atOffsets: indexSet)
    }

}

