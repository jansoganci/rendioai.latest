//
//  Theme.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct Theme: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let thumbnailURL: URL?
    let prompt: String
    let isFeatured: Bool
    let isAvailable: Bool
    let defaultSettings: [String: Any]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case thumbnailURL = "thumbnail_url"
        case prompt
        case isFeatured = "is_featured"
        case isAvailable = "is_available"
        case defaultSettings = "default_settings"
        case createdAt = "created_at"
    }
    
    // MARK: - Custom Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Decode thumbnail_url as URL
        if let urlString = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) {
            thumbnailURL = URL(string: urlString)
        } else {
            thumbnailURL = nil
        }
        
        prompt = try container.decode(String.self, forKey: .prompt)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        
        // Decode default_settings as JSONB (Dictionary)
        if let settingsData = try container.decodeIfPresent([String: AnyCodable].self, forKey: .defaultSettings) {
            defaultSettings = settingsData.mapValues { $0.value }
        } else {
            defaultSettings = nil
        }
        
        // Decode created_at with ISO8601 format
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            // Fallback to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
        }
    }
    
    // MARK: - Custom Encoding
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(thumbnailURL?.absoluteString, forKey: .thumbnailURL)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(isAvailable, forKey: .isAvailable)
        
        // Encode default_settings
        if let settings = defaultSettings {
            let codableSettings = settings.mapValues { AnyCodable($0) }
            try container.encode(codableSettings, forKey: .defaultSettings)
        }
        
        // Encode created_at
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
    
    // MARK: - Initializer
    
    init(
        id: String,
        name: String,
        description: String? = nil,
        thumbnailURL: URL? = nil,
        prompt: String,
        isFeatured: Bool = false,
        isAvailable: Bool = true,
        defaultSettings: [String: Any]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.prompt = prompt
        self.isFeatured = isFeatured
        self.isAvailable = isAvailable
        self.defaultSettings = defaultSettings
        self.createdAt = createdAt
    }
}

// MARK: - AnyCodable Helper

/// Helper type to encode/decode Any values in JSON
private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictionary as [String: Any]:
            let codableDict = dictionary.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"
                )
            )
        }
    }
}

// MARK: - Preview Data

extension Theme {
    static var preview: Theme {
        Theme(
            id: "preview-theme-1",
            name: "Christmas Magic",
            description: "Create festive holiday videos with warm, cozy Christmas scenes",
            thumbnailURL: nil,
            prompt: "A cozy Christmas scene with a decorated tree, warm fireplace, and snow falling outside the window",
            isFeatured: true,
            isAvailable: true,
            defaultSettings: [
                "duration": 8,
                "aspect_ratio": "16:9"
            ],
            createdAt: Date()
        )
    }
    
    static var previewThemes: [Theme] {
        [
            Theme(
                id: "1",
                name: "Christmas Magic",
                description: "Create festive holiday videos",
                prompt: "A cozy Christmas scene with decorations",
                isFeatured: true
            ),
            Theme(
                id: "2",
                name: "Thanksgiving Feast",
                description: "Capture Thanksgiving warmth",
                prompt: "A warm Thanksgiving dinner with family",
                isFeatured: true
            ),
            Theme(
                id: "3",
                name: "Halloween Spooky",
                description: "Create spooky Halloween videos",
                prompt: "A spooky Halloween night with pumpkins",
                isFeatured: true
            ),
            Theme(
                id: "4",
                name: "Summer Beach",
                description: "Relaxing beach vibes",
                prompt: "A beautiful beach at sunset with waves",
                isFeatured: false
            ),
            Theme(
                id: "5",
                name: "City Nightlife",
                description: "Urban city energy",
                prompt: "Neon city lights reflecting on wet streets",
                isFeatured: false
            )
        ]
    }
}

