//
//  CountdownTimer.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.05.24.
//

import Foundation
import Combine
import SwiftUI

final class CountdownTimer: ObservableObject {
    @Published var timeRemaining: String = ""
    private var timer: AnyCancellable?

    init(targetDate: Date) {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime(to: targetDate)
            }
    }
    
    private func updateTime(to targetDate: Date) {
        let now = Date()
        let remainingSeconds = Int(targetDate.timeIntervalSince(now))
        
        if remainingSeconds > 0 {
            let days = remainingSeconds / 86400 // Total seconds in a day
            let hours = (remainingSeconds % 86400) / 3600 // Hours after days
            let minutes = (remainingSeconds % 3600) / 60 // Minutes after hours
            let seconds = (remainingSeconds % 3600) % 60 // Seconds after minutes
            if days > 0 {
                withAnimation {
                    timeRemaining = String(format: "%02d days & %02d:%02d:%02d", days, hours, minutes, seconds)
                }
            }
            else if days == 0 {
                withAnimation {
                    timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                }
            }
        } else {
            timeRemaining = "00 days 00:00:00"
            timer?.cancel()
        }
    }

    
    deinit {
        timer?.cancel()
    }
}
