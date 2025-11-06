//
//  SettingsSection.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct SettingsSection: View {
    @Binding var selectedLanguage: String
    @Binding var selectedTheme: String
    let appVersion: String
    let onLanguageChange: ((String) -> Void)?
    let onThemeChange: ((String) -> Void)?

    init(
        selectedLanguage: Binding<String>,
        selectedTheme: Binding<String>,
        appVersion: String,
        onLanguageChange: ((String) -> Void)? = nil,
        onThemeChange: ((String) -> Void)? = nil
    ) {
        self._selectedLanguage = selectedLanguage
        self._selectedTheme = selectedTheme
        self.appVersion = appVersion
        self.onLanguageChange = onLanguageChange
        self.onThemeChange = onThemeChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("profile.settings".localized)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal, 16)

            // Settings Options
            VStack(spacing: 0) {
                // Language Dropdown
                SettingsDropdown<UserSettings.Language>(
                    label: "profile.language".localized,
                    selection: $selectedLanguage
                )
                .onChange(of: selectedLanguage) { _, newValue in
                    onLanguageChange?(newValue)
                }

                Divider()
                    .background(Color("SurfaceBase"))

                // Theme Dropdown
                SettingsDropdown<UserSettings.Theme>(
                    label: "profile.theme".localized,
                    selection: $selectedTheme
                )
                .onChange(of: selectedTheme) { _, newValue in
                    onThemeChange?(newValue)
                }
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)

            // App Version
            appVersionView
        }
    }

    // MARK: - Subviews

    private var appVersionView: some View {
        HStack {
            Text("profile.app_version".localized)
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))

            Spacer()

            Text(appVersion)
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("English - System Theme - Light") {
    SettingsSection(
        selectedLanguage: .constant("en"),
        selectedTheme: .constant("system"),
        appVersion: "1.0.0 (42)"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Turkish - Dark Theme - Dark") {
    SettingsSection(
        selectedLanguage: .constant("tr"),
        selectedTheme: .constant("dark"),
        appVersion: "1.0.0 (42)"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Spanish - Light Theme") {
    SettingsSection(
        selectedLanguage: .constant("es"),
        selectedTheme: .constant("light"),
        appVersion: "1.0.0 (42)"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}
