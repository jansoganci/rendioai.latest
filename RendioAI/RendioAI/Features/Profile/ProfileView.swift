//
//  ProfileView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(
        userService: UserService.shared
    )

    var body: some View {
        ZStack {
            Color("SurfaceBase")
                .ignoresSafeArea()

            // Only show full-page loading on FIRST load (when no user data exists)
            if viewModel.isLoading && viewModel.user == nil {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        if let user = viewModel.user {
                            ProfileHeader(
                                userName: user.displayName,
                                email: user.email ?? "profile.email_hidden".localized,
                                tier: viewModel.tierDisplay,
                                isGuest: user.isGuest
                            )

                            // Credit Info Section
                            CreditInfoSection(
                                creditsDisplay: user.creditsDisplay,
                                onBuyCredits: {
                                    if viewModel.canBuyCredits {
                                        viewModel.buyCredits()
                                    } else {
                                        viewModel.showGuestPurchaseAlert()
                                    }
                                },
                                onViewHistory: {
                                    viewModel.navigateToHistory()
                                },
                                canBuyCredits: viewModel.canBuyCredits,
                                isLoadingCredits: viewModel.isLoadingCredits
                            )

                            // Account Section
                            AccountSection(
                                isGuest: viewModel.isGuest,
                                onSignIn: { viewModel.signInWithApple() },
                                onRestorePurchases: { viewModel.restorePurchases() },
                                onSignOut: { viewModel.signOut() },
                                onDeleteAccount: { viewModel.deleteAccount() }
                            )

                            // Settings Section
                            SettingsSection(
                                selectedLanguage: $viewModel.selectedLanguage,
                                selectedTheme: $viewModel.selectedTheme,
                                appVersion: viewModel.appVersion,
                                onLanguageChange: { language in
                                    viewModel.handleLanguageChange(language)
                                },
                                onThemeChange: { theme in
                                    viewModel.handleThemeChange(theme)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 20)
                }
                .refreshable {
                    await viewModel.loadUserProfile()
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("profile.title".localized)
        .navigationDestination(isPresented: $viewModel.navigateToHistoryView) {
            HistoryView()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            alertButtons
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $viewModel.showingPurchaseSheet) {
            PurchaseSheet { creditsAdded in
                Task {
                    await viewModel.handlePurchaseComplete(credits: creditsAdded)
                }
            }
        }
        .task {
            await viewModel.loadUserProfile()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color("BrandPrimary"))

            Text("common.loading".localized)
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch viewModel.alertType {
        case .signOut:
            Button("common.cancel".localized, role: .cancel) {}
            Button("profile.sign_out".localized, role: .destructive) {
                Task {
                    await viewModel.confirmSignOut()
                }
            }

        case .deleteAccount:
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                Task {
                    await viewModel.confirmDeleteAccount()
                }
            }

        case .guestPurchase, .error, .success:
            Button("common.ok".localized, role: .cancel) {}

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("Guest User - Light") {
    NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.light)
}

#Preview("Guest User - Dark") {
    NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Registered User") {
    let viewModel = ProfileViewModel(userService: MockUserService())
    viewModel.user = .registeredPreview

    return NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.light)
}

#Preview("Premium User") {
    let viewModel = ProfileViewModel(userService: MockUserService())
    viewModel.user = .premiumPreview

    return NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    let viewModel = ProfileViewModel(userService: MockUserService())
    viewModel.isLoading = true

    return NavigationStack {
        ProfileView()
    }
    .preferredColorScheme(.light)
}
