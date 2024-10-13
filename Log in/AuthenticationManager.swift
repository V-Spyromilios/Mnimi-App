//
//  AuthenticationManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import Combine

@MainActor
class AuthenticationManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoggedOut: Bool = false
    
    func login()  {
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.isLoggedOut = false
        }
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.isLoggedOut = true
        }
    }
}
