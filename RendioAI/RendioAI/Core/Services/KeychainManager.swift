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

    // MARK: - Token Expiry Helpers

    /// Gets the expiry date of the stored access token
    /// - Returns: Expiry date from JWT "exp" claim, or nil if no token or parsing fails
    func getAccessTokenExpiry() -> Date? {
        guard let token = getAccessToken() else {
            return nil
        }
        return Self.parseJWTExpiry(token)
    }

    /// Parses JWT token to extract expiry date from "exp" claim
    /// - Parameter token: JWT token string (format: header.payload.signature)
    /// - Returns: Expiry date, or nil if token is invalid or missing "exp" claim
    ///
    /// Example:
    /// ```swift
    /// let token = "eyJhbGc...header.eyJleHAiOjE3MzE3ODk2MDB9...payload.signature"
    /// let expiry = KeychainManager.parseJWTExpiry(token)
    /// // Returns: Date(timeIntervalSince1970: 1731789600)
    /// ```
    static func parseJWTExpiry(_ token: String) -> Date? {
        // JWT format: header.payload.signature
        let parts = token.split(separator: ".")

        guard parts.count == 3 else {
            print("⚠️ KeychainManager: Invalid JWT format (expected 3 parts, got \(parts.count))")
            return nil
        }

        // Get payload (middle part)
        var payload = String(parts[1])

        // JWT uses base64url encoding - convert to standard base64
        // Replace URL-safe characters with standard base64 characters
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed (base64 requires length % 4 == 0)
        let paddingLength = (4 - payload.count % 4) % 4
        if paddingLength > 0 {
            payload += String(repeating: "=", count: paddingLength)
        }

        // Decode base64 to data
        guard let data = Data(base64Encoded: payload) else {
            print("⚠️ KeychainManager: Failed to decode base64 payload")
            return nil
        }

        // Parse JSON payload
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ KeychainManager: Failed to parse JSON from payload")
            return nil
        }

        // Extract "exp" claim (Unix timestamp as number)
        guard let exp = json["exp"] as? TimeInterval else {
            print("⚠️ KeychainManager: No 'exp' claim found in token")
            return nil
        }

        // Convert Unix timestamp to Date
        let expiryDate = Date(timeIntervalSince1970: exp)

        // Log expiry for debugging
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        print("✅ KeychainManager: Token expires at \(formatter.string(from: expiryDate))")

        return expiryDate
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

