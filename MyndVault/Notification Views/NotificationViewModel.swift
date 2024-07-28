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
    var repeats: Bool
    var repeatInterval: RepeatInterval?
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
                    var repeats = false
                    var repeatInterval: RepeatInterval = .none
                    
                    if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
                        date = calendarTrigger.nextTriggerDate()
                        repeats = calendarTrigger.repeats
                        repeatInterval = self.determineRepeatInterval(from: calendarTrigger.dateComponents)
                    } else if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
                        date = timeIntervalTrigger.nextTriggerDate()
                        repeats = timeIntervalTrigger.repeats
                        repeatInterval = .none // Time interval triggers typically don't support custom repeat intervals in the same way
                    }
                    
                    guard let notificationDate = date else { return nil }
                    
                    return CustomNotification(
                        id: notification.identifier,
                        title: notification.content.title,
                        notificationBody: notification.content.body,
                        date: notificationDate,
                        repeats: repeats,
                        repeatInterval: repeatInterval
                    )
                }.sorted(by: { $0.date < $1.date })
            }
        }
    }

    private func determineRepeatInterval(from dateComponents: DateComponents) -> RepeatInterval {

        if dateComponents.weekday != nil {
            let weekdays = Set([2, 3, 4, 5, 6])
            let weekends = Set([1, 7])
            
            if weekdays.contains(dateComponents.weekday!) {
                return .weekdays
            } else if weekends.contains(dateComponents.weekday!) {
                return .weekends
            } else {
                return .weekly
            }
        } else if dateComponents.hour != nil && dateComponents.minute != nil {
            return .daily
        } else {
            return .none
        }
    }
    
    func deleteNotification(with id: String) {
        
        scheduledNotifications.removeAll { $0.id == id }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func refreshNotifications() {
        fetchScheduledNotifications()
    }
    
}

