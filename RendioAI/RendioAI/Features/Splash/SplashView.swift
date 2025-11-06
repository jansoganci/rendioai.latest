//
//  SplashView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel = SplashViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Background
            Color("BrandPrimary")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App Logo/Icon
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)

                // App Name
                Text("RendioAI")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)

                // Tagline
                Text("AI Video Generation")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(opacity)

                // Loading indicator (only shows if taking longer than 2 seconds)
                if viewModel.showLoadingIndicator {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.top, 32)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Start onboarding process
            Task {
                await viewModel.performOnboarding()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isOnboardingComplete) {
            ContentView()
                .environmentObject(localizationManager)
        }
    }
}

// MARK: - Splash ViewModel

@MainActor
class SplashViewModel: ObservableObject {
    @Published var isOnboardingComplete = false
    @Published var showLoadingIndicator = false

    private let onboardingViewModel: OnboardingViewModel

    // Minimum splash duration (2 seconds)
    private let minimumSplashDuration: TimeInterval = 2.0

    // Maximum splash duration (30 seconds) - safety timeout
    private let maximumSplashDuration: TimeInterval = 30.0

    init(onboardingViewModel: OnboardingViewModel? = nil) {
        self.onboardingViewModel = onboardingViewModel ?? OnboardingViewModel()
    }

    /// Performs the onboarding process in the background
    func performOnboarding() async {
        let startTime = Date()

        // Show loading indicator after 2 seconds if still processing
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            if !isOnboardingComplete {
                showLoadingIndicator = true
            }
        }

        // Safety timeout: Force proceed after maximum duration
        Task {
            try? await Task.sleep(for: .seconds(maximumSplashDuration))
            if !isOnboardingComplete {
                print("⚠️ Maximum splash duration exceeded, forcing navigation")
                isOnboardingComplete = true
            }
        }

        // Perform onboarding using the orchestration layer
        let result = await onboardingViewModel.performOnboarding()

        // Log result
        switch result {
        case .success(let response):
            print("✅ Onboarding success:")
            print("   - Device ID: \(response.deviceId)")
            print("   - Is Existing User: \(response.isExistingUser)")
            print("   - Credits: \(response.creditsRemaining)")

        case .fallback(let reason, let deviceId):
            print("⚠️ Onboarding fallback:")
            print("   - Reason: \(reason)")
            print("   - Device ID: \(deviceId)")

        case .alreadyCompleted:
            print("ℹ️ Onboarding already completed")
        }

        // Ensure minimum splash duration
        await ensureMinimumDuration(startTime: startTime)

        // Navigate to main app
        isOnboardingComplete = true
    }

    /// Ensures splash screen shows for at least the minimum duration
    private func ensureMinimumDuration(startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = minimumSplashDuration - elapsed

        if remaining > 0 {
            print("⏳ Waiting \(String(format: "%.1f", remaining))s to meet minimum splash duration...")
            try? await Task.sleep(for: .seconds(remaining))
        }
    }
}

// MARK: - Preview

#Preview("Splash Screen") {
    SplashView()
        .preferredColorScheme(.dark)
}

#Preview("Splash Screen - Light") {
    SplashView()
        .preferredColorScheme(.light)
}
