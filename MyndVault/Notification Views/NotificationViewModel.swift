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
                  self.scheduledNotifications = scheduledNotifications.compactMap { notification in
                      let trigger = notification.trigger
                      var date: Date?
                      
                      if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
                          date = calendarTrigger.nextTriggerDate()
                      } else if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
                          date = timeIntervalTrigger.nextTriggerDate()
                      }
                      
                      guard let notificationDate = date else { return nil }
                      
                      return CustomNotification(
                          id: notification.identifier,
                          title: notification.content.title,
                          notificationBody: notification.content.body,
                          date: notificationDate
                      )
                  }.sorted(by: { $0.date < $1.date }) //most recent first
              }
          }
      }
    
    
    func deleteNotification(with id: String) {
        
        scheduledNotifications.removeAll { $0.id == id }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
}

