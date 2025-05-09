//
//  RevenueCatManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.05.25.
//

import Foundation
import RevenueCat

final class RevenueCatManager: ObservableObject {
    @Published var isProUser: Bool = false

    init() {
        Purchases.shared.getCustomerInfo { info, error in
            self.isProUser = info?.entitlements["manager"]?.isActive == true
        }
    }

    func checkStatus() {
        Purchases.shared.getCustomerInfo { info, error in
            self.isProUser = info?.entitlements["manager"]?.isActive == true
        }
    }
}
