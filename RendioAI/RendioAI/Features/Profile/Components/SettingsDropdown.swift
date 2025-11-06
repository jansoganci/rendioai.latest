//
//  SettingsDropdown.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct SettingsDropdown<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let icon: String
    let label: String
    @Binding var selection: String
    let options: [T]
    let displayName: (T) -> String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color("BrandPrimary"))

            Text(label)
                .font(.body)
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option))
                        .tag(option.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("BrandPrimary"))
            .animation(.easeInOut(duration: 0.3), value: selection)
        }
        .padding(16)
        .background(Color("SurfaceCard"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(currentDisplayName)")
        .accessibilityHint("Select \(label.lowercased())")
    }

    private var currentDisplayName: String {
        if let current = options.first(where: { $0.rawValue == selection }) {
            return displayName(current)
        }
        return selection
    }
}

// MARK: - Convenience Initializers

extension SettingsDropdown where T == UserSettings.Language {
    init(
        icon: String = "globe",
        label: String,
        selection: Binding<String>
    ) {
        self.icon = icon
        self.label = label
        self._selection = selection
        self.options = UserSettings.Language.allCases
        self.displayName = { $0.displayName }
    }
}

extension SettingsDropdown where T == UserSettings.Theme {
    init(
        icon: String = "paintbrush.fill",
        label: String,
        selection: Binding<String>
    ) {
        self.icon = icon
        self.label = label
        self._selection = selection
        self.options = UserSettings.Theme.allCases
        self.displayName = { $0.displayName }
    }
}

// MARK: - Preview

#Preview("Language Dropdown - Light") {
    VStack(spacing: 16) {
        SettingsDropdown<UserSettings.Language>(
            label: NSLocalizedString("profile.language", comment: ""),
            selection: .constant("en")
        )

        SettingsDropdown<UserSettings.Language>(
            label: NSLocalizedString("profile.language", comment: ""),
            selection: .constant("tr")
        )

        SettingsDropdown<UserSettings.Language>(
            label: NSLocalizedString("profile.language", comment: ""),
            selection: .constant("es")
        )
    }
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Theme Dropdown - Dark") {
    VStack(spacing: 16) {
        SettingsDropdown<UserSettings.Theme>(
            label: NSLocalizedString("profile.theme", comment: ""),
            selection: .constant("system")
        )

        SettingsDropdown<UserSettings.Theme>(
            label: NSLocalizedString("profile.theme", comment: ""),
            selection: .constant("light")
        )

        SettingsDropdown<UserSettings.Theme>(
            label: NSLocalizedString("profile.theme", comment: ""),
            selection: .constant("dark")
        )
    }
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Combined Settings") {
    VStack(spacing: 0) {
        SettingsDropdown<UserSettings.Language>(
            label: NSLocalizedString("profile.language", comment: ""),
            selection: .constant("en")
        )

        Divider()
            .background(Color("SurfaceBase"))

        SettingsDropdown<UserSettings.Theme>(
            label: NSLocalizedString("profile.theme", comment: ""),
            selection: .constant("system")
        )
    }
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    .padding(16)
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}
