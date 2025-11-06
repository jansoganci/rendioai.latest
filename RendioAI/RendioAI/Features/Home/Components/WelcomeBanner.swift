//
//  WelcomeBanner.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct WelcomeBanner: View {
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "gift.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("banner.welcome.title", comment: "Welcome title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(NSLocalizedString("banner.welcome.subtitle", comment: "Welcome subtitle"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // Dismiss button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isVisible = false
                }

                // Delay dismiss to allow animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("BrandPrimary"),
                            Color("BrandPrimary").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Welcome Banner") {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()

        VStack {
            WelcomeBanner {
                print("Banner dismissed")
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

#Preview("Welcome Banner - Dark") {
    ZStack {
        Color("SurfaceBase")
            .ignoresSafeArea()

        VStack {
            WelcomeBanner {
                print("Banner dismissed")
            }

            Spacer()
        }
        .padding(.top, 16)
    }
    .preferredColorScheme(.dark)
}
