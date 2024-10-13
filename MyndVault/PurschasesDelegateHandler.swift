//
//  PurschasesDelegateHandler.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 24.08.24.
//

import Foundation
import RevenueCat
import RevenueCatUI

@MainActor
class PurchasesDelegateHandler:NSObject, ObservableObject {
    
    static let shared =  PurchasesDelegateHandler()

}

@MainActor
extension PurchasesDelegateHandler: @preconcurrency PurchasesDelegate {

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print("Received updated customer info: \(customerInfo)")
        RCViewModel.shared.customerInfo = customerInfo
    }
}
