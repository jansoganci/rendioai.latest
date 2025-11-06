//
//  UserSettings.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct UserSettings: Codable {
    var language: String
    var themePreference: String

    // MARK: - Language Options

    enum Language: String, CaseIterable {
        case english = "en"
        case turkish = "tr"
        case spanish = "es"

        var displayName: String {
            switch self {
            case .english: return "profile.language_english".localized
            case .turkish: return "profile.language_turkish".localized
            case .spanish: return "profile.language_spanish".localized
            }
        }

        var localeIdentifier: String {
            rawValue
        }
    }

    // MARK: - Theme Options

    enum Theme: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var displayName: String {
            switch self {
            case .system: return "profile.theme_system".localized
            case .light: return "profile.theme_light".localized
            case .dark: return "profile.theme_dark".localized
            }
        }
    }

    // MARK: - Initialization

    init(language: String = "en", themePreference: String = "system") {
        self.language = language
        self.themePreference = themePreference
    }

    // MARK: - Default Settings

    static var `default`: UserSettings {
        UserSettings(language: "en", themePreference: "system")
    }

    // MARK: - Preview Data

    static var preview: UserSettings {
        UserSettings(language: "en", themePreference: "system")
    }

    static var darkPreview: UserSettings {
        UserSettings(language: "en", themePreference: "dark")
    }

    static var turkishPreview: UserSettings {
        UserSettings(language: "tr", themePreference: "system")
    }
}
