//
//  KeychainManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import Security
import Foundation
import CloudKit

class KeychainManager {
    
    static let standard = KeychainManager()
    let service = "dev.chillvibes.MyndVault"
    private init() {}
    
    func save(service: String = "dev.chillvibes.MyndVault", account: String, data: Data) {
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
        self.save(service: service, account: username, data: passwordData)
        
        // Optionally, save username in a separate entry (if needed for retrieval or other logic)
        let usernameData = username.data(using: .utf8)!
        self.save(service: service, account: "savedUsername", data: usernameData)
    }
    
    func readUsername() -> String? {
        guard let usernameData = self.read(service: service, account: "savedUsername"),
              let username = String(data: usernameData, encoding: .utf8) else {
            return nil
        }
        return username
    }
}

extension KeychainManager {
    
    func readRecordID(service: String = "dev.chillvibes.MyndVault", account: String) -> CKRecord.ID? {
        // Read Data from Keychain
        guard let recordIDData = read(service: service, account: account) else { return nil }
        
        do {
            // Convert Data back to CKRecord.ID using NSKeyedUnarchiver
            if let recordID = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: recordIDData) {
                return recordID
            }
        } catch {
            print("Failed to unarchive CKRecord.ID: \(error.localizedDescription)")
        }
        return nil
    }
}
