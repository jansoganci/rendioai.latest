//
//  CreditInfoSection.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct CreditInfoSection: View {
    let creditsDisplay: String
    let onBuyCredits: () -> Void
    let onViewHistory: () -> Void
    let canBuyCredits: Bool
    var isLoadingCredits: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Credit Display
            creditDisplayView

            // Action Buttons
            HStack(spacing: 12) {
                // Buy Credits Button
                buyCreditsButton

                // View History Button
                viewHistoryButton
            }
        }
        .padding(16)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Subviews

    private var creditDisplayView: some View {
        HStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .font(.title3)
                .foregroundColor(Color("BrandPrimary"))

            if isLoadingCredits {
                // Show subtle loading indicator while credits are being fetched
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color("BrandPrimary"))
            } else {
                Text(creditsDisplay)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var buyCreditsButton: some View {
        Button(action: onBuyCredits) {
            Label(
                "profile.buy_credits".localized,
                systemImage: "bolt.fill"
            )
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(canBuyCredits ? Color("BrandPrimary") : Color("TextSecondary").opacity(0.3))
            .cornerRadius(8)
        }
        .disabled(!canBuyCredits)
        .opacity(canBuyCredits ? 1.0 : 0.6)
        .accessibilityLabel("profile.buy_credits".localized)
        .accessibilityHint(canBuyCredits ? "Purchase additional credits" : "Sign in to purchase credits")
    }

    private var viewHistoryButton: some View {
        Button(action: onViewHistory) {
            Label(
                "profile.view_history".localized,
                systemImage: "clock.fill"
            )
            .font(.headline)
            .foregroundColor(Color("BrandPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color("BrandPrimary").opacity(0.1))
            .cornerRadius(8)
        }
        .accessibilityLabel("profile.view_history".localized)
        .accessibilityHint("View your video generation history")
    }
}

// MARK: - Preview

#Preview("Can Buy Credits") {
    VStack(spacing: 16) {
        // Use actual User model data - credits fetched from database
        CreditInfoSection(
            creditsDisplay: User.registeredPreview.creditsDisplay,
            onBuyCredits: {},
            onViewHistory: {},
            canBuyCredits: true,
            isLoadingCredits: false
        )

        CreditInfoSection(
            creditsDisplay: User.premiumPreview.creditsDisplay,
            onBuyCredits: {},
            onViewHistory: {},
            canBuyCredits: true,
            isLoadingCredits: false
        )
    }
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Guest User (Cannot Buy)") {
    // Use actual User model data - credits fetched from database
    CreditInfoSection(
        creditsDisplay: User.guestPreview.creditsDisplay,
        onBuyCredits: {},
        onViewHistory: {},
        canBuyCredits: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Low Credits") {
    // Create preview user with low credits from User model structure
    let lowCreditUser = User(
        id: "preview-low-credits",
        email: "low@example.com",
        deviceId: "device-123",
        appleSub: nil,
        isGuest: false,
        tier: .free,
        creditsRemaining: 2, // Low credits from database structure
        creditsTotal: 10,
        initialGrantClaimed: true,
        language: "en",
        themePreference: "system",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    CreditInfoSection(
        creditsDisplay: lowCreditUser.creditsDisplay, // Uses creditsRemaining from User model
        onBuyCredits: {},
        onViewHistory: {},
        canBuyCredits: true
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}
