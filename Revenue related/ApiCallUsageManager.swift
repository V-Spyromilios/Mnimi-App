//
//  ApiCallUsageManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.05.25.
//

import Foundation

import Combine

import Foundation
import RevenueCat

@MainActor
final class ApiCallUsageManager: ObservableObject {
    
    private let store = NSUbiquitousKeyValueStore.default
    
    private let apiCallCountKey = "apiCallCount"
    private let lastResetDateKey = "lastResetDate"
    private let isProUserKey = "isProUser"

    @Published var apiCallCount: Int = 0
    @Published var isProUser: Bool = false

    init() {
        // Sync from iCloud when launched
        syncFromCloud()

        // Listen for external iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncFromCloud),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    // MARK: - API Tracking

    func canMakeApiCall(limit: Int = 20) -> Bool {
        resetMonthlyIfNeeded()
        return isProUser || apiCallCount < limit
    }

    func trackApiCall() {
        resetMonthlyIfNeeded()
        apiCallCount += 1
        store.set(apiCallCount, forKey: apiCallCountKey)
        store.synchronize()
    }

    func currentCount() -> Int {
        resetMonthlyIfNeeded()
        return apiCallCount
    }

    private func resetMonthlyIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())

        let lastReset = store.string(forKey: lastResetDateKey)
        if lastReset != currentMonth {
            apiCallCount = 0
            store.set(0, forKey: apiCallCountKey)
            store.set(currentMonth, forKey: lastResetDateKey)
            store.synchronize()
        }
    }
    
    func refresh() {
        Task {
            await refreshSubscriptionStatus()
        }
    }

    // MARK: - Subscription Check

    @MainActor
    func refreshSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let isActive = info.entitlements[Constants.entitlementID]?.isActive == true
            isProUser = isActive
            store.set(isActive, forKey: isProUserKey)
            store.synchronize()
        } catch {
            debugPrint("Failed to fetch customer info:", error)
            isProUser = false
        }
    }

    // MARK: - iCloud Sync

    @objc private func syncFromCloud() {
        DispatchQueue.main.async {
            self.apiCallCount = Int(self.store.longLong(forKey: self.apiCallCountKey))
            self.isProUser = self.store.bool(forKey: self.isProUserKey)
        }
    }
}
