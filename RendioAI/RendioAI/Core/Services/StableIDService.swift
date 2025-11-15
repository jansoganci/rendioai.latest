//
//  StableIDService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//
//  Purpose: Wrapper for StableID package to provide persistent device identifier
//  that survives app reinstalls and simulator resets
//

import Foundation
import StableID

/// Service for managing stable device identifier
/// Uses StableID package which stores ID in iCloud Key-Value Store
class StableIDService {
    static let shared = StableIDService()
    
    private var isConfigured = false
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure StableID at app startup
    /// Should be called once in app initialization
    func configure() {
        guard !isConfigured else {
            print("✅ StableIDService: Already configured")
            return
        }
        
        // Check if StableID already has a stored ID (from iCloud or previous launch)
        if StableID.hasStoredID {
            // Use existing stored ID
            StableID.configure()
            print("✅ StableIDService: Configured with existing stored ID: \(StableID.id)")
        } else {
            // Generate new ID and store it
            StableID.configure()
            print("✅ StableIDService: Configured with new ID: \(StableID.id)")
        }
        
        isConfigured = true
    }
    
    /// Configure StableID with App Store Transaction ID (iOS 16.0+)
    /// This provides the most stable identifier tied to user's Apple Account
    func configureWithAppTransactionID() async {
        guard !isConfigured else {
            print("✅ StableIDService: Already configured")
            return
        }
        
        do {
            // Try to fetch App Store Transaction ID
            let appTransactionID = try await StableID.fetchAppTransactionID()
            
            // Configure with preferStored policy to maintain consistency across devices
            StableID.configure(id: appTransactionID, policy: .preferStored)
            print("✅ StableIDService: Configured with App Transaction ID: \(appTransactionID)")
            print("   StableID: \(StableID.id)")
        } catch {
            // Fallback to auto-generated ID if App Transaction ID fails
            print("⚠️ StableIDService: Failed to fetch App Transaction ID: \(error)")
            print("   Falling back to auto-generated ID")
            configure()
        }
        
        isConfigured = true
    }
    
    // MARK: - ID Access
    
    /// Get the current stable device identifier
    /// - Returns: Stable device ID (UUID string format)
    func getStableID() -> String {
        // Ensure StableID is configured
        if !isConfigured {
            configure()
        }
        
        return StableID.id
    }
    
    /// Check if StableID has been configured
    var isStableIDConfigured: Bool {
        return StableID.isConfigured
    }
    
    /// Check if StableID has a stored ID (from iCloud or previous launch)
    var hasStoredID: Bool {
        return StableID.hasStoredID
    }
}

