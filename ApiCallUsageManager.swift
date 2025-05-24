//
//  ApiCallUsageManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.05.25.
//

import Foundation
import SwiftUI
import Combine

final class ApiCallUsageManager: ObservableObject {
    @AppStorage(UsageTrackingKeys.apiCallCount) private var apiCallCount: Int = 0
    @AppStorage(UsageTrackingKeys.lastResetDate) private var lastResetDate: String = ""

    func resetMonthlyIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())

        if lastResetDate != currentMonth {
            apiCallCount = 0
            lastResetDate = currentMonth
        }
    }

    func canMakeApiCall(limit: Int = 25) -> Bool {
        resetMonthlyIfNeeded()
        return apiCallCount < limit
    }

    func trackApiCall() {
        resetMonthlyIfNeeded()
        apiCallCount += 1
    }

    var currentCount: Int {
        resetMonthlyIfNeeded()
        return apiCallCount
    }
}
