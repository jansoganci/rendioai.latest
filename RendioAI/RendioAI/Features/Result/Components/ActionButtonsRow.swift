//
//  ActionButtonsRow.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ActionButtonsRow: View {
    let canSave: Bool
    let canShare: Bool
    let isSaving: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary Actions Row
            HStack(spacing: 12) {
                // Save Button
                saveButton
                
                // Share Button
                shareButton
            }
            .frame(maxWidth: .infinity)
            
            // Regenerate Button
            regenerateButton
        }
    }
    
    // MARK: - Subviews
    
    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.headline)
                }
                
                Text(NSLocalizedString("result.save", comment: "Save to Library"))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSave && !isSaving ? Color("BrandPrimary") : Color("TextSecondary").opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canSave || isSaving)
        .opacity(canSave && !isSaving ? 1.0 : 0.6)
        .accessibilityLabel(NSLocalizedString("result.save", comment: "Save to Library"))
        .accessibilityHint(isSaving ? NSLocalizedString("result.saving", comment: "Saving video") : NSLocalizedString("result.save_hint", comment: "Double tap to save video to Photos library"))
    }
    
    private var shareButton: some View {
        Button(action: onShare) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.headline)
                
                Text(NSLocalizedString("result.share", comment: "Share"))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canShare ? Color("BrandPrimary").opacity(0.1) : Color("TextSecondary").opacity(0.1))
            .foregroundColor(canShare ? Color("BrandPrimary") : Color("TextSecondary"))
            .cornerRadius(12)
        }
        .disabled(!canShare)
        .opacity(canShare ? 1.0 : 0.6)
        .accessibilityLabel(NSLocalizedString("result.share", comment: "Share"))
        .accessibilityHint(NSLocalizedString("result.share_hint", comment: "Double tap to share video"))
    }
    
    private var regenerateButton: some View {
        Button(action: onRegenerate) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline)
                
                Text(NSLocalizedString("result.regenerate", comment: "Regenerate"))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color("SurfaceCard"))
            .foregroundColor(Color("TextPrimary"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("TextSecondary").opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityLabel(NSLocalizedString("result.regenerate", comment: "Regenerate"))
        .accessibilityHint(NSLocalizedString("result.regenerate_hint", comment: "Double tap to regenerate video with same prompt"))
    }
}

// MARK: - Preview

#Preview("Video Ready") {
    ActionButtonsRow(
        canSave: true,
        canShare: true,
        isSaving: false,
        onSave: {},
        onShare: {},
        onRegenerate: {}
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Processing (Buttons Disabled)") {
    ActionButtonsRow(
        canSave: false,
        canShare: false,
        isSaving: false,
        onSave: {},
        onShare: {},
        onRegenerate: {}
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Saving") {
    ActionButtonsRow(
        canSave: true,
        canShare: true,
        isSaving: true,
        onSave: {},
        onShare: {},
        onRegenerate: {}
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

