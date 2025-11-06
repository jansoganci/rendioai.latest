//
//  StoreKitManager.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import StoreKit

// MARK: - Credit Package Model

struct CreditPackage: Identifiable, Hashable {
    let id: String
    let credits: Int
    let price: String
    let priceValue: Decimal
    let displayTitle: String
    let displayDescription: String
    let isPopular: Bool

    init(product: Product, isPopular: Bool = false) {
        self.id = product.id
        self.credits = CreditPackage.creditsFromProductId(product.id)
        self.price = product.displayPrice
        self.priceValue = product.price
        self.displayTitle = product.displayName
        self.displayDescription = product.description
        self.isPopular = isPopular
    }

    init(id: String, credits: Int, price: String, priceValue: Decimal, displayTitle: String, displayDescription: String, isPopular: Bool = false) {
        self.id = id
        self.credits = credits
        self.price = price
        self.priceValue = priceValue
        self.displayTitle = displayTitle
        self.displayDescription = displayDescription
        self.isPopular = isPopular
    }

    static func creditsFromProductId(_ productId: String) -> Int {
        // Extract credits from product ID (e.g., "com.janstrade.rendio.credits.10" -> 10)
        let components = productId.split(separator: ".")
        if let last = components.last, let credits = Int(last) {
            return credits
        }
        return 0
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success(credits: Int)
    case pending
    case cancelled
    case failed(Error)
}

// MARK: - StoreKitManager Protocol

protocol StoreKitManagerProtocol {
    /// Load available credit packages from App Store
    func loadProducts() async throws -> [CreditPackage]

    /// Purchase a credit package
    func purchase(_ package: CreditPackage) async -> PurchaseResult

    /// Restore previous purchases
    func restorePurchases() async throws -> Int

    /// Validate receipt with backend
    func validateReceipt(transaction: Transaction) async throws -> Int
}

// MARK: - StoreKitManager Implementation

@MainActor
class StoreKitManager: ObservableObject, StoreKitManagerProtocol {
    static let shared = StoreKitManager()

    // MARK: - Published Properties

    @Published var availablePackages: [CreditPackage] = []
    @Published var isPurchasing: Bool = false

    // MARK: - Private Properties

    private var productIds: [String] {
        [
            "com.janstrade.rendio.credits.10",
            "com.janstrade.rendio.credits.25",
            "com.janstrade.rendio.credits.50",
            "com.janstrade.rendio.credits.100",
            "com.janstrade.rendio.credits.250"
        ]
    }

    private var productsCache: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Start transaction listener
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async throws -> [CreditPackage] {
        do {
            let products = try await Product.products(for: productIds)
            productsCache = products

            // Convert to CreditPackage models
            let packages = products.enumerated().map { index, product in
                CreditPackage(product: product, isPopular: index == 2) // Mark 50 credits as popular
            }

            // Sort by credits ascending
            let sortedPackages = packages.sorted { $0.credits < $1.credits }

            await MainActor.run {
                availablePackages = sortedPackages
            }

            return sortedPackages

        } catch {
            throw AppError.networkError("Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(_ package: CreditPackage) async -> PurchaseResult {
        guard let product = productsCache.first(where: { $0.id == package.id }) else {
            return .failed(AppError.invalidResponse)
        }

        await MainActor.run {
            isPurchasing = true
        }

        defer {
            Task { @MainActor in
                isPurchasing = false
            }
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Validate with backend
                let credits = try await validateReceipt(transaction: transaction)

                // Finish the transaction
                await transaction.finish()

                return .success(credits: credits)

            case .pending:
                return .pending

            case .userCancelled:
                return .cancelled

            @unknown default:
                return .failed(AppError.unknown("Unknown purchase result"))
            }

        } catch {
            return .failed(error)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws -> Int {
        var totalCreditsRestored = 0

        // Iterate through all transactions
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)

            // Validate with backend
            let credits = try await validateReceipt(transaction: transaction)
            totalCreditsRestored += credits
        }

        return totalCreditsRestored
    }

    // MARK: - Validate Receipt

    func validateReceipt(transaction: Transaction) async throws -> Int {
        // Phase 2: Replace with actual Supabase Edge Function call
        // Endpoint: POST /api/validate-receipt
        // Body: { transaction_id, product_id, receipt_data }
        // Currently using mock data for development

        // Simulate network delay
        try await Task.sleep(for: .seconds(1.0))

        // Extract credits from product ID
        let credits = CreditPackage.creditsFromProductId(transaction.productID)

        // Phase 2: Backend should:
        // 1. Verify receipt with Apple
        // 2. Check if transaction already processed (prevent double-crediting)
        // 3. Add credits to quota_log
        // 4. Return total credits added

        print("✅ Validated receipt for \(credits) credits (Transaction: \(transaction.id))")

        return credits
    }

    // MARK: - Private Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw AppError.invalidResponse
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor in
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Deliver products to the user
                    await self.handleTransaction(transaction)

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        // handled by CreditService (credit updates via validateReceipt)
        print("📦 Processing transaction: \(transaction.productID)")
    }
}

// MARK: - Mock StoreKitManager

class MockStoreKitManager: StoreKitManagerProtocol {
    var shouldSucceed = true
    var mockPackages: [CreditPackage] = [
        CreditPackage(
            id: "com.janstrade.rendio.credits.10",
            credits: 10,
            price: "$0.99",
            priceValue: 0.99,
            displayTitle: "10 Credits",
            displayDescription: "Perfect for trying out",
            isPopular: false
        ),
        CreditPackage(
            id: "com.janstrade.rendio.credits.25",
            credits: 25,
            price: "$1.99",
            priceValue: 1.99,
            displayTitle: "25 Credits",
            displayDescription: "Great value",
            isPopular: false
        ),
        CreditPackage(
            id: "com.janstrade.rendio.credits.50",
            credits: 50,
            price: "$2.99",
            priceValue: 2.99,
            displayTitle: "50 Credits",
            displayDescription: "Most popular",
            isPopular: true
        ),
        CreditPackage(
            id: "com.janstrade.rendio.credits.100",
            credits: 100,
            price: "$4.99",
            priceValue: 4.99,
            displayTitle: "100 Credits",
            displayDescription: "Best value",
            isPopular: false
        ),
        CreditPackage(
            id: "com.janstrade.rendio.credits.250",
            credits: 250,
            price: "$9.99",
            priceValue: 9.99,
            displayTitle: "250 Credits",
            displayDescription: "Ultimate package",
            isPopular: false
        )
    ]

    func loadProducts() async throws -> [CreditPackage] {
        try await Task.sleep(for: .seconds(1.0))

        if shouldSucceed {
            return mockPackages
        } else {
            throw AppError.networkError("Failed to load products")
        }
    }

    func purchase(_ package: CreditPackage) async -> PurchaseResult {
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        } catch {
            return .failed(error)
        }

        if shouldSucceed {
            return .success(credits: package.credits)
        } else {
            return .failed(AppError.networkError("Purchase failed"))
        }
    }

    func restorePurchases() async throws -> Int {
        try await Task.sleep(for: .seconds(1.0))

        if shouldSucceed {
            return 50 // Mock restored credits
        } else {
            throw AppError.networkError("Restore failed")
        }
    }

    func validateReceipt(transaction: Transaction) async throws -> Int {
        try await Task.sleep(for: .seconds(0.5))

        if shouldSucceed {
            return CreditPackage.creditsFromProductId(transaction.productID)
        } else {
            throw AppError.networkError("Validation failed")
        }
    }
}
