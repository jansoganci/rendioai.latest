//
//  PurchaseSheet.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI

struct PurchaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitManager.shared

    let onPurchaseComplete: (Int) -> Void

    @State private var selectedPackage: CreditPackage?
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Credit Packages
                    if storeKit.availablePackages.isEmpty {
                        loadingView
                    } else {
                        packagesSection
                    }

                    // Purchase Button
                    purchaseButton

                    // Legal Disclaimer
                    legalDisclaimer
                }
                .padding(.vertical, 24)
            }
            .background(Color("SurfaceBase"))
            .navigationTitle("Buy Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "")) {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button(NSLocalizedString("common.ok", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadProducts()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("BrandPrimary"))

            Text("Choose Your Credit Package")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))

            Text("Credits never expire and can be used for any video generation")
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color("BrandPrimary"))

            Text("Loading packages...")
                .font(.body)
                .foregroundColor(Color("TextSecondary"))
        }
        .frame(height: 200)
    }

    private var packagesSection: some View {
        VStack(spacing: 12) {
            ForEach(storeKit.availablePackages) { package in
                PackageCard(
                    package: package,
                    isSelected: selectedPackage?.id == package.id,
                    onTap: {
                        selectedPackage = package
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            HStack {
                if storeKit.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "cart.fill")
                    Text("Purchase \(selectedPackage?.credits ?? 0) Credits")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedPackage != nil && !storeKit.isPurchasing
                    ? Color("BrandPrimary")
                    : Color("TextSecondary").opacity(0.3)
            )
            .cornerRadius(12)
        }
        .disabled(selectedPackage == nil || storeKit.isPurchasing)
        .padding(.horizontal, 16)
        .accessibilityLabel("Purchase selected credit package")
    }

    private var legalDisclaimer: some View {
        VStack(spacing: 8) {
            Text("By purchasing, you agree to our")
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))

            HStack(spacing: 4) {
                Button(action: {
                    if let url = URL(string: "https://jansoganci.github.io/rendioai.latest/Legal-Documents/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Terms of Service")
                        .font(.caption)
                        .foregroundColor(Color("BrandPrimary"))
                        .underline()
                }

                Text("and")
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))

                Button(action: {
                    if let url = URL(string: "https://jansoganci.github.io/rendioai.latest/Legal-Documents/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundColor(Color("BrandPrimary"))
                        .underline()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func loadProducts() async {
        do {
            let packages = try await storeKit.loadProducts()

            // Auto-select the popular package
            if let popular = packages.first(where: { $0.isPopular }) {
                selectedPackage = popular
            } else if let first = packages.first {
                selectedPackage = first
            }

        } catch {
            errorMessage = "Failed to load products. Please try again."
            showingError = true
        }
    }

    private func handlePurchase() {
        guard let package = selectedPackage else { return }

        Task {
            let result = await storeKit.purchase(package)

            switch result {
            case .success(let credits):
                onPurchaseComplete(credits)
                dismiss()

            case .pending:
                errorMessage = "Purchase is pending. Please check back later."
                showingError = true

            case .cancelled:
                // User cancelled - no action needed
                break

            case .failed(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Package Card Component

private struct PackageCard: View {
    let package: CreditPackage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(package.displayTitle)
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))

                    // Description
                    Text(package.displayDescription)
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.price)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("BrandPrimary"))

                    Text("\(package.credits) credits")
                        .font(.caption)
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            .padding(16)
            .background(
                ZStack {
                    Color("SurfaceCard")

                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("BrandPrimary"), lineWidth: 2)
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.1), radius: isSelected ? 6 : 4, y: 2)
            .overlay(alignment: .topTrailing) {
                if package.isPopular {
                    Text("POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("BrandPrimary"))
                        .cornerRadius(4)
                        .offset(x: -8, y: -8)
                }
            }
        }
        .accessibilityLabel("\(package.displayTitle), \(package.price)")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
    }
}

// MARK: - Preview

#Preview("Purchase Sheet") {
    PurchaseSheet { credits in
        print("Purchased \(credits) credits")
    }
}
