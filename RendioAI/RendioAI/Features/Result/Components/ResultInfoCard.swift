//
//  ResultInfoCard.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ResultInfoCard: View {
    let prompt: String
    let modelName: String
    let creditsUsed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prompt
            promptSection
            
            // Model and Credits
            infoRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Subviews
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                
                Text(NSLocalizedString("result.prompt_label", comment: "Prompt"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("TextSecondary"))
            }
            
            Text(prompt)
                .font(.body)
                .foregroundColor(Color("TextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var infoRow: some View {
        HStack(spacing: 16) {
            // Model
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                
                Text(modelName)
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            
            // Credits
            HStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
                
                Text("\(creditsUsed) \(NSLocalizedString("credits_short", comment: "credits"))")
                    .font(.subheadline)
                    .foregroundColor(Color("TextSecondary"))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let promptLabel = NSLocalizedString("result.prompt_label", comment: "Prompt")
        let modelLabel = NSLocalizedString("result.accessibility.model", comment: "Model")
        let creditsLabel = NSLocalizedString("result.accessibility.credits", comment: "Credits used")
        
        return "\(promptLabel): \(prompt). \(modelLabel): \(modelName). \(creditsLabel): \(creditsUsed)"
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    ResultInfoCard(
        prompt: "A beautiful sunset over the ocean with waves crashing on the shore",
        modelName: "FalAI Veo 3.1",
        creditsUsed: 4
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ResultInfoCard(
        prompt: "Neon city lights reflecting on wet streets at night, cinematic style",
        modelName: "Sora 2",
        creditsUsed: 6
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

