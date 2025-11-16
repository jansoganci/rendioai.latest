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
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("profile.settings".localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            // Settings Options
            VStack(spacing: 0) {
                // Language Dropdown
                SettingsDropdown<UserSettings.Language>(
                    label: "profile.language".localized,
                    selection: $selectedLanguage
                )
                .onChange(of: selectedLanguage) { newValue in
                    onLanguageChange?(newValue)
                }

                Divider()
                    .padding(.leading, 48)
                    .background(Color("SurfaceBase"))

                // Theme Dropdown
                SettingsDropdown<UserSettings.Theme>(
                    label: "profile.theme".localized,
                    selection: $selectedTheme
                )
                .onChange(of: selectedTheme) { newValue in
                    onThemeChange?(newValue)
                }
            }
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .padding(.horizontal, 16)

            // Legal Links
            legalLinksSection

            // App Version
            appVersionView
        }
    }

    // MARK: - Subviews

    private var legalLinksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("Legal")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            // Links Container
            VStack(spacing: 0) {
                // Privacy Policy
                Button(action: {
                    if let url = URL(string: "https://jansoganci.github.io/rendioai.latest/Legal-Documents/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.body)
                            .foregroundColor(Color("TextSecondary"))

                        Text("Privacy Policy")
                            .font(.body)
                            .foregroundColor(Color("TextPrimary"))

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }

                Divider()
                    .padding(.leading, 48)
                    .background(Color("SurfaceBase"))

                // Terms of Service
                Button(action: {
                    if let url = URL(string: "https://jansoganci.github.io/rendioai.latest/Legal-Documents/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.body)
                            .foregroundColor(Color("TextSecondary"))

                        Text("Terms of Service")
                            .font(.body)
                            .foregroundColor(Color("TextPrimary"))

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }

                Divider()
                    .padding(.leading, 48)
                    .background(Color("SurfaceBase"))

                // Support
                Button(action: {
                    if let url = URL(string: "https://jansoganci.github.io/rendioai.latest/Legal-Documents/support.html") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.body)
                            .foregroundColor(Color("TextSecondary"))

                        Text("Support & Help")
                            .font(.body)
                            .foregroundColor(Color("TextPrimary"))

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
    }

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
