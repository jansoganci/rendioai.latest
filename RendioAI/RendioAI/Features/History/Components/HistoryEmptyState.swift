//
//  HistoryEmptyState.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct HistoryEmptyState: View {
    let onGenerateVideo: (() -> Void)?
    
    init(onGenerateVideo: (() -> Void)? = nil) {
        self.onGenerateVideo = onGenerateVideo
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.badge.waveform")
                .font(.system(size: 64))
                .foregroundColor(Color("TextSecondary"))
                .accessibilityHidden(true)
            
            Text(NSLocalizedString("history.empty", comment: "Empty state message"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("history.empty_subtitle", comment: "Empty state subtitle"))
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let onGenerateVideo = onGenerateVideo {
                PrimaryButton(
                    title: NSLocalizedString("history.empty_cta", comment: "Generate first video"),
                    action: onGenerateVideo,
                    icon: "🎥"
                )
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .accessibilityLabel(NSLocalizedString("history.empty_cta", comment: "Generate first video"))
                .accessibilityHint(NSLocalizedString("history.accessibility.generate_first", comment: "Double tap to generate your first video"))
            }
        }
        .padding(.vertical, 64)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = NSLocalizedString("history.empty", comment: "")
        label += ". "
        label += NSLocalizedString("history.empty_subtitle", comment: "")
        return label
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()
        
        HistoryEmptyState(onGenerateVideo: {})
    }
}
