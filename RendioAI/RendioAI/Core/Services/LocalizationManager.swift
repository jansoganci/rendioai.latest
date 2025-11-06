//
//  LocalizationManager.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String
    
    private let defaults = UserDefaultsManager.shared
    
    private init() {
        self.currentLanguage = defaults.language
        applyLanguage(defaults.language)
        
        // Observe language changes
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let newLanguage = notification.object as? String else { return }
            self.currentLanguage = newLanguage
            self.applyLanguage(newLanguage)
        }
    }
    
    // MARK: - Apply Language
    
    private func applyLanguage(_ language: String) {
        // Set AppleLanguages to override system language
        // This affects NSLocalizedString on next app launch
        UserDefaults.standard.set([language, "en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // For immediate effect, we need to notify views to refresh
        // Note: NSLocalizedString will still use system language until app restart
        // But our custom localizedString() method will work immediately
    }
    
    // MARK: - Localized String
    
    func localizedString(for key: String, comment: String = "") -> String {
        let language = defaults.language
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to system language or English
            return NSLocalizedString(key, comment: comment)
        }
        
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    // MARK: - Bundle
    
    var bundle: Bundle {
        let language = defaults.language
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        
        return bundle
    }
}

// MARK: - Bundle Extension

extension Bundle {
    static var localized: Bundle {
        LocalizationManager.shared.bundle
    }
}

// MARK: - String Extension

extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(comment: String = "") -> String {
        LocalizationManager.shared.localizedString(for: self, comment: comment)
    }
}

