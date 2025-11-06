//
//  QuotaWarningBanner.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct QuotaWarningBanner: View {
    let creditsRemaining: Int
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color("AccentWarning"))
                .font(.body)

            // Warning message
            Text(String(
                format: NSLocalizedString("home_quota_warning", comment: "Quota warning message"),
                creditsRemaining
            ))
            .font(.body)
            .foregroundColor(Color("TextPrimary"))

            Spacer()

            // Upgrade button
            Button(action: onUpgrade) {
                Text(NSLocalizedString("home_upgrade_button", comment: "Upgrade button"))
                    .font(.headline)
                    .foregroundColor(Color("BrandPrimary"))
            }
        }
        .padding(16)
        .background(Color("AccentWarning").opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AccentWarning").opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Light Mode") {
    VStack(spacing: 16) {
        QuotaWarningBanner(creditsRemaining: 5, onUpgrade: {})
        QuotaWarningBanner(creditsRemaining: 2, onUpgrade: {})
        QuotaWarningBanner(creditsRemaining: 0, onUpgrade: {})
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        QuotaWarningBanner(creditsRemaining: 5, onUpgrade: {})
        QuotaWarningBanner(creditsRemaining: 2, onUpgrade: {})
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}
