//
//  LowCreditBanner.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct LowCreditBanner: View {
    let creditsRemaining: Int
    let onBuyCredits: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color("AccentWarning"))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("banner.low_credit.title", comment: "Low credit title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))

                Text(String(format: NSLocalizedString("banner.low_credit.subtitle", comment: "Low credit subtitle"), creditsRemaining))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("TextSecondary"))
            }

            Spacer()

            // Buy Credits Button
            Button(action: onBuyCredits) {
                Text(NSLocalizedString("banner.low_credit.action", comment: "Buy credits"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color("AccentWarning"))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AccentWarning").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color("AccentWarning").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Low Credit Banner") {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()

        VStack {
            LowCreditBanner(creditsRemaining: 3) {
                print("Buy credits tapped")
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

#Preview("Low Credit Banner - Dark") {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()

        VStack {
            LowCreditBanner(creditsRemaining: 5) {
                print("Buy credits tapped")
            }

            Spacer()
        }
        .padding(.top, 16)
    }
    .preferredColorScheme(.dark)
}

#Preview("Low Credit Banner - No Credits") {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()

        VStack {
            LowCreditBanner(creditsRemaining: 0) {
                print("Buy credits tapped")
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}
