//
//  AccountSection.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct AccountSection: View {
    let isGuest: Bool
    let onSignIn: () -> Void
    let onRestorePurchases: () -> Void
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            Text("profile.account_title".localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
                .padding(.horizontal, 16)

            // Account Actions
            VStack(spacing: 0) {
                if isGuest {
                    // Sign In Button (Guest State)
                    signInButton
                } else {
                    // Logged-In Actions
                    restorePurchasesButton

                    Divider()
                        .padding(.leading, 48)
                        .background(Color("SurfaceBase"))

                    signOutButton

                    Divider()
                        .padding(.leading, 48)
                        .background(Color("SurfaceBase"))

                    deleteAccountButton
                }
            }
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Subviews

    private var signInButton: some View {
        Button(action: onSignIn) {
            AccountActionRow(
                icon: "applelogo",
                text: "profile.sign_in".localized,
                textColor: .white,
                backgroundColor: Color("BrandPrimary")
            )
        }
        .accessibilityLabel("profile.sign_in".localized)
        .accessibilityHint("Sign in with your Apple ID to unlock purchases and sync")
    }

    private var restorePurchasesButton: some View {
        Button(action: onRestorePurchases) {
            AccountActionRow(
                icon: "arrow.clockwise",
                text: "profile.restore_purchases".localized,
                textColor: Color("TextPrimary")
            )
        }
        .accessibilityLabel("profile.restore_purchases".localized)
        .accessibilityHint("Restore previously purchased credits and subscriptions")
    }

    private var signOutButton: some View {
        Button(action: onSignOut) {
            AccountActionRow(
                icon: "rectangle.portrait.and.arrow.right",
                text: "profile.sign_out".localized,
                textColor: Color("TextPrimary")
            )
        }
        .accessibilityLabel("profile.sign_out".localized)
        .accessibilityHint("Sign out and return to guest mode")
    }

    private var deleteAccountButton: some View {
        Button(action: onDeleteAccount) {
            AccountActionRow(
                icon: "trash",
                text: "profile.delete_account".localized,
                textColor: .red
            )
        }
        .accessibilityLabel("profile.delete_account".localized)
        .accessibilityHint("Permanently delete your account and all data")
    }
}

// MARK: - Account Action Row Component

private struct AccountActionRow: View {
    let icon: String
    let text: String
    let textColor: Color
    var backgroundColor: Color? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 20)

            Text(text)
                .font(.body)

            Spacer()

            if backgroundColor == nil {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .foregroundColor(textColor)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(backgroundColor ?? Color.clear)
    }
}

// MARK: - Preview

#Preview("Guest User") {
    AccountSection(
        isGuest: true,
        onSignIn: { print("Sign In") },
        onRestorePurchases: {},
        onSignOut: {},
        onDeleteAccount: {}
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Logged-In User - Light") {
    AccountSection(
        isGuest: false,
        onSignIn: {},
        onRestorePurchases: { print("Restore") },
        onSignOut: { print("Sign Out") },
        onDeleteAccount: { print("Delete") }
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.light)
}

#Preview("Logged-In User - Dark") {
    AccountSection(
        isGuest: false,
        onSignIn: {},
        onRestorePurchases: { print("Restore") },
        onSignOut: { print("Sign Out") },
        onDeleteAccount: { print("Delete") }
    )
    .padding()
    .background(Color("SurfaceBase"))
    .preferredColorScheme(.dark)
}
