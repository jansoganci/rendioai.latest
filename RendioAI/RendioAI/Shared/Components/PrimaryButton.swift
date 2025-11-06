//
//  PrimaryButton.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var icon: String? = nil
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let icon = icon {
                    Text(icon)
                        .font(.body)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(isEnabled && !isLoading ? Color("BrandPrimary") : Color("TextSecondary").opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview("Enabled") {
    VStack(spacing: 16) {
        PrimaryButton(
            title: "Generate Video",
            action: {},
            isEnabled: true,
            isLoading: false,
            icon: "🎥"
        )
        
        PrimaryButton(
            title: "Generate Video",
            action: {},
            isEnabled: true,
            isLoading: false
        )
    }
    .padding()
    .background(Color("SurfaceBase"))
}

#Preview("Disabled & Loading") {
    VStack(spacing: 16) {
        PrimaryButton(
            title: "Generate Video",
            action: {},
            isEnabled: false,
            isLoading: false
        )
        
        PrimaryButton(
            title: "Generating...",
            action: {},
            isEnabled: true,
            isLoading: true
        )
    }
    .padding()
    .background(Color("SurfaceBase"))
}
