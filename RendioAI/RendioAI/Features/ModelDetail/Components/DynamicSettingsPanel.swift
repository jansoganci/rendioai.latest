//
//  DynamicSettingsPanel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct DynamicSettingsPanel: View {
    @Binding var settings: VideoSettings
    let modelRequirements: ModelRequirements?
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        // Only show settings panel if model requires settings
        if let requirements = modelRequirements, requirements.needsSettings {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(spacing: 16) {
                        // Render settings dynamically based on model requirements
                        if let settingsConfig = requirements.settings {
                            // Duration setting
                            if let durationConfig = settingsConfig.duration {
                                durationSettingRow(config: durationConfig)
                            }
                            
                            // Resolution setting
                            if let resolutionConfig = settingsConfig.resolution {
                                resolutionSettingRow(config: resolutionConfig)
                            }
                            
                            // Aspect ratio setting
                            if let aspectRatioConfig = settingsConfig.aspectRatio {
                                aspectRatioSettingRow(config: aspectRatioConfig)
                            }
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text(NSLocalizedString("model_detail.settings_title", comment: "Settings title"))
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))
                }
            )
            .padding(16)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(NSLocalizedString("model_detail.settings_title", comment: "Settings panel"))
        }
    }
    
    // MARK: - Duration Setting Row
    
    @ViewBuilder
    private func durationSettingRow(config: FieldConfig<Int>) -> some View {
        // Only show if options are available
        if let options = config.options, !options.isEmpty {
            durationRowContent(options: options, config: config)
        }
    }
    
    private func durationRowContent(options: [Int], config: FieldConfig<Int>) -> some View {
        let currentDuration = settings.duration ?? config.default ?? options.first ?? 4
        let selectedIndex = options.firstIndex(of: currentDuration) 
            ?? config.default.flatMap { options.firstIndex(of: $0) } 
            ?? 0
        
        return SettingsRow(
            label: NSLocalizedString("model_detail.duration_label", comment: "Duration label"),
            value: "\(currentDuration)s",
            options: options.map { "\($0)s" },
            selectedIndex: selectedIndex
        ) { index in
            settings = VideoSettings(
                duration: options[index],
                resolution: settings.resolution,
                aspect_ratio: settings.aspect_ratio,
                fps: settings.fps
            )
        }
    }
    
    // MARK: - Resolution Setting Row
    
    @ViewBuilder
    private func resolutionSettingRow(config: FieldConfig<String>) -> some View {
        // Only show if options are available
        if let options = config.options, !options.isEmpty {
            resolutionRowContent(options: options, config: config)
        }
    }
    
    private func resolutionRowContent(options: [String], config: FieldConfig<String>) -> some View {
        let currentResolution = settings.resolution ?? config.default ?? options.first ?? "auto"
        let selectedIndex = options.firstIndex(of: currentResolution)
            ?? config.default.flatMap { options.firstIndex(of: $0) }
            ?? 0
        
        return SettingsRow(
            label: NSLocalizedString("model_detail.resolution_label", comment: "Resolution label"),
            value: currentResolution,
            options: options,
            selectedIndex: selectedIndex
        ) { index in
            settings = VideoSettings(
                duration: settings.duration,
                resolution: options[index],
                aspect_ratio: settings.aspect_ratio,
                fps: settings.fps
            )
        }
    }
    
    // MARK: - Aspect Ratio Setting Row
    
    @ViewBuilder
    private func aspectRatioSettingRow(config: FieldConfig<String>) -> some View {
        // Only show if options are available
        if let options = config.options, !options.isEmpty {
            aspectRatioRowContent(options: options, config: config)
        }
    }
    
    private func aspectRatioRowContent(options: [String], config: FieldConfig<String>) -> some View {
        let currentAspectRatio = settings.aspect_ratio ?? config.default ?? options.first ?? "auto"
        let selectedIndex = options.firstIndex(of: currentAspectRatio)
            ?? config.default.flatMap { options.firstIndex(of: $0) }
            ?? 0
        
        return SettingsRow(
            label: NSLocalizedString("model_detail.aspect_ratio_label", comment: "Aspect ratio label"),
            value: currentAspectRatio,
            options: options,
            selectedIndex: selectedIndex
        ) { index in
            settings = VideoSettings(
                duration: settings.duration,
                resolution: settings.resolution,
                aspect_ratio: options[index],
                fps: settings.fps
            )
        }
    }
}

// MARK: - Settings Row (Reused from SettingsPanel)

private struct SettingsRow: View {
    let label: String
    let value: String
    let options: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
            
            Spacer()
            
            Picker("", selection: Binding(
                get: { selectedIndex },
                set: { onSelect($0) }
            )) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Text(option).tag(index)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("BrandPrimary"))
        }
    }
}

// MARK: - Preview

#Preview("With Requirements") {
    DynamicSettingsPanel(
        settings: .constant(VideoSettings.default),
        modelRequirements: ModelRequirements.preview
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("No Requirements") {
    DynamicSettingsPanel(
        settings: .constant(VideoSettings.default),
        modelRequirements: nil
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

