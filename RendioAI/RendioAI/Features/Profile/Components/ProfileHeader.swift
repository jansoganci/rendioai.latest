//
//  ProfileHeader.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ProfileHeader: View {
    let userName: String
    let email: String
    let tier: String
    let isGuest: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            avatarView

            // User Info
            VStack(spacing: 4) {
                // Name
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))

                // Email
                Text(email)
                    .font(.body)
                    .foregroundColor(Color("TextSecondary"))

                // Tier Badge
                tierBadge
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("SurfaceCard"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color("BrandPrimary").opacity(0.1))
                .frame(width: 96, height: 96)

            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("BrandPrimary"))
        }
        .accessibilityLabel("User avatar")
    }

    private var tierBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: isGuest ? "gift.fill" : (tier == "Premium Tier" ? "crown.fill" : "gift.fill"))
                .font(.caption)
                .foregroundColor(badgeColor)

            Text(tier)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(badgeColor.opacity(0.1))
        .cornerRadius(12)
        .accessibilityLabel("\(tier) badge")
    }

    private var badgeColor: Color {
        if tier.contains("Premium") {
            return Color("BrandPrimary")
        } else {
            return Color("TextSecondary")
        }
    }
}

// MARK: - Preview

#Preview("Guest User") {
    ProfileHeader(
        userName: "Guest User",
        email: "—",
        tier: "Free Tier",
        isGuest: true
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Registered User") {
    ProfileHeader(
        userName: "John Doe",
        email: "john.doe@privaterelay.appleid.com",
        tier: "Free Tier",
        isGuest: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}

#Preview("Premium User") {
    ProfileHeader(
        userName: "Jane Smith",
        email: "jane.smith@example.com",
        tier: "Premium Tier",
        isGuest: false
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}
