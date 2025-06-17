
//
//  RevenueCatManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.05.25.
//

import Foundation
import RevenueCat

@MainActor
final class RevenueCatManager: ObservableObject {
    @Published var isProUser: Bool = false

    init() {
        checkStatus()
    }

    func checkStatus() {
        Purchases.shared.getCustomerInfo { info, error in
            DispatchQueue.main.async {
                self.isProUser = info?.entitlements["manager"]?.isActive == true
            }
        }
    }
}
