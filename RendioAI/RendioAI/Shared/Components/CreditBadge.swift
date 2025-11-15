//
//  CreditBadge.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct CreditBadge: View {
    let creditsRemaining: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text("\(creditsRemaining)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("BrandPrimary"))

                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(Color("BrandPrimary"))
            }
        }
        .accessibilityLabel(String(format: NSLocalizedString("credits.accessibility.label", comment: "Credits remaining accessibility label"), creditsRemaining))
        .accessibilityHint(NSLocalizedString("credits.accessibility.hint", comment: "Tap to buy more credits"))
    }
}

// MARK: - Preview

#Preview("Credit Badge Variants") {
    VStack(spacing: 16) {
        CreditBadge(creditsRemaining: 45, onTap: {})
        CreditBadge(creditsRemaining: 10, onTap: {})
        CreditBadge(creditsRemaining: 5, onTap: {})
        CreditBadge(creditsRemaining: 0, onTap: {})
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        CreditBadge(creditsRemaining: 45, onTap: {})
        CreditBadge(creditsRemaining: 10, onTap: {})
        CreditBadge(creditsRemaining: 5, onTap: {})
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}
