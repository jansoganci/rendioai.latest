//
//  KeychainManager.swift
//  RendioAI
//
//  Created by Rendio AI Team
//
//  Purpose: Secure storage for Supabase auth tokens (access_token, refresh_token)
//  Uses iOS Keychain for secure storage instead of UserDefaults
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.rendioai.supabase"
    
    private init() {}
    
    // MARK: - Access Token
    
    func saveAccessToken(_ token: String) {
        save(token, forKey: "access_token")
    }
    
    func getAccessToken() -> String? {
        return get(forKey: "access_token")
    }
    
    func deleteAccessToken() {
        delete(forKey: "access_token")
    }
    
    // MARK: - Refresh Token
    
    func saveRefreshToken(_ token: String) {
        save(token, forKey: "refresh_token")
    }
    
    func getRefreshToken() -> String? {
        return get(forKey: "refresh_token")
    }
    
    func deleteRefreshToken() {
        delete(forKey: "refresh_token")
    }
    
    // MARK: - Clear All Tokens
    
    func clearAllTokens() {
        deleteAccessToken()
        deleteRefreshToken()
        print("🗑️ KeychainManager: All tokens cleared")
    }
    
    // MARK: - Generic Keychain Operations
    
    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else {
            print("❌ KeychainManager: Failed to convert string to data for key: \(key)")
            return
        }
        
        // Delete existing item first
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ KeychainManager: Saved \(key) to Keychain")
        } else {
            print("❌ KeychainManager: Failed to save \(key) to Keychain. Status: \(status)")
        }
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        } else {
            if status != errSecItemNotFound {
                print("⚠️ KeychainManager: Failed to get \(key) from Keychain. Status: \(status)")
            }
            return nil
        }
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            // Success or item doesn't exist (both are fine)
        } else {
            print("⚠️ KeychainManager: Failed to delete \(key) from Keychain. Status: \(status)")
        }
    }
}

