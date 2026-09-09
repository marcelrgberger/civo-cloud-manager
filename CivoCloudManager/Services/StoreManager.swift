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
    private(set) var isTrialActive: Bool
    private(set) var hasLoadedPurchaseStatus = false
    let trialEndsAt: Date

    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var isFullAccessUnlocked: Bool {
        isTrialActive || purchasedProductIDs.contains(AppProduct.fullAccess.rawValue)
    }

    private var updateTask: Task<Void, Never>?
    private var trialTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        let key = "fullAccessTrialStartedAt"
        let startedAt = defaults.object(forKey: key) as? Date ?? now
        if defaults.object(forKey: key) == nil {
            defaults.set(startedAt, forKey: key)
        }
        trialEndsAt = startedAt.addingTimeInterval(7 * 24 * 60 * 60)
        isTrialActive = now < trialEndsAt
    }

    func refreshTrialStatus(now: Date = Date()) {
        isTrialActive = now < trialEndsAt
    }

    func startListening() {
        guard updateTask == nil else { return }
        refreshTrialStatus()
        trialTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let remaining = self?.trialEndsAt.timeIntervalSinceNow else { return }
                self?.refreshTrialStatus()
                guard remaining > 0 else { return }
                do {
                    try await Task.sleep(for: .seconds(min(remaining, 30)))
                } catch { return }
            }
        }
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

    // MARK: - Redeem promo code

    func redeemPromoCode() {
        if let url = URL(string: "https://apps.apple.com/redeem") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Entitlements

    func refreshPurchaseStatus() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                Log.info("StoreManager: found entitlement: \(transaction.productID), env=\(transaction.environment.rawValue)")
                purchased.insert(transaction.productID)
            }
        }
        Log.info("StoreManager: refreshPurchaseStatus done — found \(purchased.count) entitlements: \(purchased)")
        purchasedProductIDs = purchased
        hasLoadedPurchaseStatus = true
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
