//
//  AppConfig.swift
//  RendioAI
//
//  Centralized application configuration
//  Reads values from Info.plist (which gets values from .xcconfig files)
//

import Foundation

/// Represents the current build environment
enum AppEnvironment: String {
    case development
    case staging
    case production
    
    /// Detects current environment from build settings or Info.plist
    static var current: AppEnvironment {
        // First, try to read from Info.plist (set by .xcconfig)
        if let envName = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT_NAME") as? String,
           let env = AppEnvironment(rawValue: envName.lowercased()) {
            return env
        }
        
        // Fallback: detect from build configuration
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

/// Centralized application configuration
struct AppConfig {
    
    // MARK: - Supabase Configuration
    
    /// Supabase project URL
    static var supabaseURL: String {
        // Try to read from Info.plist (set by .xcconfig)
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !url.isEmpty {
            return url
        }
        
        // Fallback to hardcoded value (for backward compatibility during migration)
        return "https://ojcnjxzctnwbmupggoxq.supabase.co"
    }
    
    /// Supabase anonymous (public) API key
    static var supabaseAnonKey: String {
        // Try to read from Info.plist (set by .xcconfig)
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !key.isEmpty {
            return key
        }
        
        // Fallback to hardcoded value (for backward compatibility during migration)
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY25qeHpjdG53Ym11cGdnb3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjkzNjIsImV4cCI6MjA3NzkwNTM2Mn0._bKw_0kYf65SxYC8ik3_SMdMgUYoxgVbisvCdRfYo08"
    }
    
    // MARK: - API Configuration
    
    /// API request timeout in seconds
    static var apiTimeout: TimeInterval {
        if let timeoutString = Bundle.main.object(forInfoDictionaryKey: "API_TIMEOUT") as? String,
           let timeout = TimeInterval(timeoutString) {
            return timeout
        }
        
        // Default timeouts by environment
        switch AppEnvironment.current {
        case .development:
            return 30.0
        case .staging:
            return 20.0
        case .production:
            return 15.0
        }
    }
    
    /// Maximum number of retry attempts for API calls
    static var maxRetryAttempts: Int {
        if let retriesString = Bundle.main.object(forInfoDictionaryKey: "API_MAX_RETRIES") as? String,
           let retries = Int(retriesString) {
            return retries
        }
        
        return 3
    }
    
    // MARK: - Feature Flags
    
    /// Whether logging is enabled
    static var enableLogging: Bool {
        if let loggingString = Bundle.main.object(forInfoDictionaryKey: "ENABLE_LOGGING") as? String {
            return loggingString == "YES"
        }
        
        // Default: enable logging in development
        return AppEnvironment.current == .development
    }
    
    /// Whether debug mode is enabled
    static var enableDebugMode: Bool {
        if let debugString = Bundle.main.object(forInfoDictionaryKey: "ENABLE_DEBUG_MODE") as? String {
            return debugString == "YES"
        }
        
        // Default: debug mode only in development
        return AppEnvironment.current == .development
    }
    
    // MARK: - Environment Info
    
    /// Current environment name
    static var environmentName: String {
        return AppEnvironment.current.rawValue
    }
    
    /// Whether running in development
    static var isDevelopment: Bool {
        return AppEnvironment.current == .development
    }
    
    /// Whether running in staging
    static var isStaging: Bool {
        return AppEnvironment.current == .staging
    }
    
    /// Whether running in production
    static var isProduction: Bool {
        return AppEnvironment.current == .production
    }
}

// MARK: - Validation

extension AppConfig {
    /// Validates that all required configuration values are present
    /// Call this at app startup to fail fast if configuration is missing
    static func validate() throws {
        let url = supabaseURL
        let key = supabaseAnonKey
        
        guard !url.isEmpty else {
            throw ConfigurationError.missingSupabaseURL
        }
        
        guard !key.isEmpty else {
            throw ConfigurationError.missingSupabaseAnonKey
        }
        
        guard url.hasPrefix("https://") else {
            throw ConfigurationError.invalidSupabaseURL
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case missingSupabaseURL
    case missingSupabaseAnonKey
    case invalidSupabaseURL
    
    var errorDescription: String? {
        switch self {
        case .missingSupabaseURL:
            return "Supabase URL is missing from configuration"
        case .missingSupabaseAnonKey:
            return "Supabase anonymous key is missing from configuration"
        case .invalidSupabaseURL:
            return "Supabase URL must start with https://"
        }
    }
}

