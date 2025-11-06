//
//  ModelRequirements.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

/// Model requirements structure matching the `required_fields` JSONB from database
struct ModelRequirements: Codable {
    let requiresPrompt: Bool?
    let requiresImage: Bool?
    let requiresSettings: Bool?
    let settings: SettingsConfig?
    
    enum CodingKeys: String, CodingKey {
        case requiresPrompt = "requires_prompt"
        case requiresImage = "requires_image"
        case requiresSettings = "requires_settings"
        case settings
    }
    
    init(
        requiresPrompt: Bool? = nil,
        requiresImage: Bool? = nil,
        requiresSettings: Bool? = nil,
        settings: SettingsConfig? = nil
    ) {
        self.requiresPrompt = requiresPrompt
        self.requiresImage = requiresImage
        self.requiresSettings = requiresSettings
        self.settings = settings
    }
}

/// Settings configuration containing field-specific configs
struct SettingsConfig: Codable {
    let resolution: FieldConfig<String>?
    let aspectRatio: FieldConfig<String>?
    let duration: FieldConfig<Int>?
    
    enum CodingKeys: String, CodingKey {
        case resolution
        case aspectRatio = "aspect_ratio"
        case duration
    }
    
    init(
        resolution: FieldConfig<String>? = nil,
        aspectRatio: FieldConfig<String>? = nil,
        duration: FieldConfig<Int>? = nil
    ) {
        self.resolution = resolution
        self.aspectRatio = aspectRatio
        self.duration = duration
    }
}

/// Generic field configuration for settings
/// Supports both String-based fields (resolution, aspect_ratio) and Int-based fields (duration)
struct FieldConfig<T: Codable>: Codable {
    let required: Bool?
    let `default`: T?
    let options: [T]?
    
    enum CodingKeys: String, CodingKey {
        case required
        case `default`
        case options
    }
    
    init(
        required: Bool? = nil,
        default: T? = nil,
        options: [T]? = nil
    ) {
        self.required = required
        self.default = `default`
        self.options = options
    }
}

// MARK: - Convenience Extensions

extension ModelRequirements {
    /// Check if prompt is required
    var needsPrompt: Bool {
        requiresPrompt ?? false
    }
    
    /// Check if image is required
    var needsImage: Bool {
        requiresImage ?? false
    }
    
    /// Check if settings are required
    var needsSettings: Bool {
        requiresSettings ?? false
    }
}

extension SettingsConfig {
    /// Get default duration value
    var defaultDuration: Int {
        duration?.default ?? 4
    }
    
    /// Get default resolution value
    var defaultResolution: String {
        resolution?.default ?? "auto"
    }
    
    /// Get default aspect ratio value
    var defaultAspectRatio: String {
        aspectRatio?.default ?? "auto"
    }
    
    /// Get allowed duration options
    var allowedDurations: [Int] {
        duration?.options ?? [4, 8, 12]
    }
    
    /// Get allowed resolution options
    var allowedResolutions: [String] {
        resolution?.options ?? ["auto", "720p"]
    }
    
    /// Get allowed aspect ratio options
    var allowedAspectRatios: [String] {
        aspectRatio?.options ?? ["auto", "9:16", "16:9"]
    }
}

// MARK: - Preview Data

extension ModelRequirements {
    static var preview: ModelRequirements {
        ModelRequirements(
            requiresPrompt: true,
            requiresImage: true,
            requiresSettings: true,
            settings: SettingsConfig(
                resolution: FieldConfig<String>(
                    required: false,
                    default: "auto",
                    options: ["auto", "720p"]
                ),
                aspectRatio: FieldConfig<String>(
                    required: false,
                    default: "auto",
                    options: ["auto", "9:16", "16:9"]
                ),
                duration: FieldConfig<Int>(
                    required: false,
                    default: 4,
                    options: [4, 8, 12]
                )
            )
        )
    }
    
    static var empty: ModelRequirements {
        ModelRequirements()
    }
}

