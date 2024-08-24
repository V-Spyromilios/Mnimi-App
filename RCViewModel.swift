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

class RCViewModel: ObservableObject {
    static let shared = RCViewModel()

    @Published var customerInfo: CustomerInfo? {
        didSet {
            // Check the current subscription status
            let newSubscriptionStatus = customerInfo?.entitlements[Constants.entitlementID]?.isActive == true
            print("customerInfo didSet: \(String(describing: newSubscriptionStatus))")
            
            // Update the isActiveSubscription and ensure view updates
            if isActiveSubscription != newSubscriptionStatus {
                isActiveSubscription = newSubscriptionStatus
            } else {
                // Manually trigger view update if the subscription status did not "change"
                objectWillChange.send()
            }
        }
    }
    
    @Published var isActiveSubscription: Bool = false {
        didSet {
            print("isActiveSubscription didSet: \(isActiveSubscription)")
        }
    }
}
