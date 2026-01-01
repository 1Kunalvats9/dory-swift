//
//  KeychainService.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation
import Security

class KeychainService{
    static func save(token: String, key: String = Constants.KeychainKeys.jwtToken) -> Bool{
        guard let data = token.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
                ]
                
                // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
        
    }
    static func load(key: String = Constants.KeychainKeys.jwtToken) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            guard status == errSecSuccess,
                  let data = result as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            return token
        }
    
    static func delete(key: String = Constants.KeychainKeys.jwtToken) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            
            return status == errSecSuccess || status == errSecItemNotFound
        }
        
        // MARK: - Clear All
        static func clearAll() {
            delete(key: Constants.KeychainKeys.jwtToken)
            delete(key: Constants.KeychainKeys.userId)
        }
    
}
