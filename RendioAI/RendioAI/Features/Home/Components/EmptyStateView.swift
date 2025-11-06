//
//  EmptyStateView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(
        icon: String = "magnifyingglass",
        title: String,
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(Color("TextSecondary"))
                .accessibilityHidden(true)
            
            Text(title)
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ". \(subtitle)"
        }
        return label
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: NSLocalizedString("home_no_models_found", comment: "No models found message")
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("With Subtitle") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: NSLocalizedString("home_no_models_found", comment: "No models found message"),
        subtitle: "Try adjusting your search query"
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}
