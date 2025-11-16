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
        VStack(spacing: 12) {
            // Credit Display
            creditDisplayView

            // Action Buttons (Centered)
            HStack(spacing: 10) {
                // Buy Credits Button
                buyCreditsButton

                // View History Button
                viewHistoryButton
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal, 16)
    }

    // MARK: - Subviews

    private var creditDisplayView: some View {
        HStack(spacing: 10) {
            Image(systemName: "creditcard.fill")
                .font(.body)
                .foregroundColor(Color("BrandPrimary"))
                .frame(width: 20)

            if isLoadingCredits {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color("BrandPrimary"))
            } else {
                Text(creditsDisplay)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var buyCreditsButton: some View {
        Button(action: onBuyCredits) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                Text("profile.buy_credits".localized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(canBuyCredits ? .white : Color("TextSecondary"))
            .frame(width: 120)
            .padding(.vertical, 8)
            .background(
                canBuyCredits 
                    ? Color("BrandPrimary")
                    : Color("SurfaceCard").opacity(0.5)
            )
            .cornerRadius(8)
        }
        .disabled(!canBuyCredits)
        .accessibilityLabel("profile.buy_credits".localized)
        .accessibilityHint(canBuyCredits ? "Purchase additional credits" : "Sign in to purchase credits")
    }

    private var viewHistoryButton: some View {
        Button(action: onViewHistory) {
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text("profile.view_history".localized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color("TextPrimary"))
            .frame(width: 120)
            .padding(.vertical, 8)
            .background(Color("SurfaceBase"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("TextSecondary").opacity(0.2), lineWidth: 1)
            )
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
