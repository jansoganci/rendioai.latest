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
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("profile.account_title".localized)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
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
                        .background(Color("SurfaceBase"))

                    signOutButton

                    Divider()
                        .background(Color("SurfaceBase"))

                    deleteAccountButton
                }
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Subviews

    private var signInButton: some View {
        Button(action: onSignIn) {
            AccountActionRow(
                icon: "applelogo",
                text: "profile.sign_in".localized,
                textColor: Color("TextPrimary")
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

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)

            Text(text)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
        }
        .foregroundColor(textColor)
        .padding(16)
        .background(Color("SurfaceCard"))
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
