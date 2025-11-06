//
//  SettingsPanel.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct SettingsPanel: View {
    @Binding var settings: VideoSettings
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(spacing: 16) {
                    // Duration Picker
                    SettingsRow(
                        label: NSLocalizedString("model_detail.duration_label", comment: "Duration label"),
                        value: durationDisplay,
                        options: ["8s", "15s", "30s"],
                        selectedIndex: durationIndex
                    ) { index in
                        let durations = [8, 15, 30]
                        settings = VideoSettings(
                            duration: durations[index],
                            resolution: settings.resolution,
                            aspect_ratio: settings.aspect_ratio,
                            fps: settings.fps
                        )
                    }
                    
                    // Resolution Picker
                    SettingsRow(
                        label: NSLocalizedString("model_detail.resolution_label", comment: "Resolution label"),
                        value: settings.resolution ?? "720p",
                        options: ["720p", "1080p"],
                        selectedIndex: resolutionIndex
                    ) { index in
                        let resolutions = ["720p", "1080p"]
                        settings = VideoSettings(
                            duration: settings.duration,
                            resolution: resolutions[index],
                            aspect_ratio: settings.aspect_ratio,
                            fps: settings.fps
                        )
                    }
                    
                    // FPS Picker
                    SettingsRow(
                        label: NSLocalizedString("model_detail.fps_label", comment: "FPS label"),
                        value: fpsDisplay,
                        options: ["24", "30", "60"],
                        selectedIndex: fpsIndex
                    ) { index in
                        let fpsValues = [24, 30, 60]
                        settings = VideoSettings(
                            duration: settings.duration,
                            resolution: settings.resolution,
                            aspect_ratio: settings.aspect_ratio,
                            fps: fpsValues[index]
                        )
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
    
    // MARK: - Computed Properties
    
    private var durationDisplay: String {
        if let duration = settings.duration {
            return "\(duration)s"
        }
        return "15s"
    }
    
    private var durationIndex: Int {
        let durations = [8, 15, 30]
        guard let duration = settings.duration,
              let index = durations.firstIndex(of: duration) else {
            return 1 // Default to 15s
        }
        return index
    }
    
    private var resolutionIndex: Int {
        let resolutions = ["720p", "1080p"]
        guard let resolution = settings.resolution,
              let index = resolutions.firstIndex(of: resolution) else {
            return 0 // Default to 720p
        }
        return index
    }
    
    private var fpsDisplay: String {
        if let fps = settings.fps {
            return "\(fps)"
        }
        return "30"
    }
    
    private var fpsIndex: Int {
        let fpsValues = [24, 30, 60]
        guard let fps = settings.fps,
              let index = fpsValues.firstIndex(of: fps) else {
            return 1 // Default to 30
        }
        return index
    }
}

// MARK: - Settings Row

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

#Preview("Collapsed") {
    SettingsPanel(settings: .constant(VideoSettings.default))
        .padding()
        .background(Color("SurfaceBase"))
        .preferredColorScheme(.light)
}

#Preview("Expanded") {
    SettingsPanel(settings: .constant(VideoSettings.default))
        .padding()
        .background(Color("SurfaceBase"))
        .preferredColorScheme(.dark)
}
