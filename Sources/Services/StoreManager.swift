import Foundation
import StoreKit

enum AppProduct: String, CaseIterable {
    case fullAccess = "de.berger_rosenstock.CivoCloudManager.fullaccess"
}

@Observable
@MainActor
final class StoreManager {
    static let shared = StoreManager()

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var error: String?

    var isFullAccessUnlocked: Bool {
        #if DEBUG
        Log.info("StoreManager: DEBUG mode — full access granted")
        return true
        #else
        let unlocked = purchasedProductIDs.contains(AppProduct.fullAccess.rawValue)
        Log.info("StoreManager: Release mode — unlocked=\(unlocked), products=\(purchasedProductIDs)")
        return unlocked
        #endif
    }

    private var updateTask: Task<Void, Never>?

    init() {}

    func startListening() {
        guard updateTask == nil else { return }
        Task { await refreshPurchaseStatus() }
        updateTask = Task { await listenForTransactions() }
    }

    // MARK: - Load products

    func loadProducts() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            products = try await Product.products(for: AppProduct.allCases.map(\.rawValue))
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Redeem offer code (App Store Connect codes)

    func redeemOfferCode() {
        // Opens Apple's native offer code redemption sheet.
        // Codes are generated in App Store Connect → Subscriptions/IAP → Offer Codes.
        if let url = URL(string: "https://apps.apple.com/redeem") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Entitlements

    func refreshPurchaseStatus() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    // MARK: - Transaction listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate != nil {
                    purchasedProductIDs.remove(transaction.productID)
                } else {
                    purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let item):
            return item
        }
    }
}

enum StoreError: LocalizedError {
    case verificationFailed
    var errorDescription: String? { "Transaction verification failed." }
}
