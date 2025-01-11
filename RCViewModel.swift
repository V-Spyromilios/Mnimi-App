//
//  RCViewModel.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 24.08.24.
//

import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI

@MainActor
final class RCViewModel: ObservableObject, Sendable {
    static let shared = RCViewModel()

    @Published var isActiveSubscription: Bool = false
    @Published var customerInfo: CustomerInfo? {
        didSet {
            // Check the current subscription status
            let newSubscriptionStatus = customerInfo?.entitlements[Constants.entitlementID]?.isActive == true

            debugLog("customerInfo didSet: \(String(describing: newSubscriptionStatus))")
            
            // Update the isActiveSubscription and ensure view updates
            if isActiveSubscription != newSubscriptionStatus {
                isActiveSubscription = newSubscriptionStatus
            } else {
                // Manually trigger view update if the subscription status did not "change"
                objectWillChange.send()
            }
        }
    }
    
}
