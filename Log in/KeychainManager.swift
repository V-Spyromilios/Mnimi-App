//
//  KeychainManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import Security
import Foundation

class KeychainManager {
    
    static let standard = KeychainManager()
    private init() {}
    
    func save(service: String, account: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // Enables iCloud Keychain synchronization
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
    
    func delete(service: String, account: String) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess
        }
}


extension KeychainManager {
    
    func saveUsernameAndPassword(username: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        
        // Save password
        self.save(service: "dev.chillvibes.MyndVault", account: username, data: passwordData)
        
        // Optionally, save username in a separate entry (if needed for retrieval or other logic)
        let usernameData = username.data(using: .utf8)!
        self.save(service: "dev.chillvibes.MyndVault", account: "savedUsername", data: usernameData)
    }
    
    func readUsername() -> String? {
        guard let usernameData = self.read(service: "dev.chillvibes.MyndVault", account: "savedUsername"),
              let username = String(data: usernameData, encoding: .utf8) else {
            return nil
        }
        return username
    }
}
