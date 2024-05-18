//
//  AuthenticationManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoggedOut: Bool = false
    
    func login() {
        isAuthenticated = true
        isLoggedOut = false
    }
    
    func logout() {
        isAuthenticated = false
        isLoggedOut = true
    }
}
