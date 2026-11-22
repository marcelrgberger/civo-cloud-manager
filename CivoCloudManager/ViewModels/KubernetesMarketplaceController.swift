import Foundation

/// The marketplace part of one Create Cluster form: loads Civo's list, keeps the chosen applications and sends
/// the cluster to the account and region they were reviewed for.
@Observable
@MainActor
final class KubernetesMarketplaceController {
    private(set) var state = MarketplaceCreateState()
    private(set) var isLoading = false
    /// Counts forms and catalog requests, so only the answer to the latest request of the open form is applied.
    private var request = 0

    private let api: any KubernetesClusterCreateAPI
    private let apiKey: @MainActor () -> String
    private let region: @MainActor () -> String

    init(
        api: any KubernetesClusterCreateAPI = CivoKubernetesService(),
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        region: @escaping @MainActor () -> String = { CivoConfig.shared.region }
    ) {
        self.api = api
        self.apiKey = apiKey
        self.region = region
    }

    /// Starts a new form without a list or choices. Answers still on their way for an earlier form are dropped.
    func beginForm() {
        request += 1
        state = MarketplaceCreateState()
        isLoading = false
    }

    /// Loads Civo's list again with the current account and region. Choices made for another account or region
    /// are marked at once; a failed load keeps the list and the choices, still marked.
    func reload() async {
        request += 1
        let request = request
        let target = Target(apiKey: apiKey(), region: region())
        state.targetChanged(to: target.context)
        isLoading = true
        let result: Result<MarketplaceCatalog, Error>
        do {
            result = .success(try MarketplaceCatalog(validating: try await api.listApplications(apiKey: target.apiKey)))
        } catch {
            result = .failure(error)
        }
        guard request == self.request else { return }
        isLoading = false
        switch result {
        case .success(let catalog):
            state.catalogLoaded(catalog, in: target.context, at: .now)
        case .failure(let error):
            guard let message = MarketplaceFailure.message(for: error) else { return }
            state.catalogFailed(message)
        }
    }

    func choose(_ application: CivoMarketplaceApplication, plan: String?) {
        state.choose(application, plan: plan)
    }

    func remove(_ id: String) {
        state.remove(id)
    }

    func acceptAgain(_ id: String) {
        state.acceptAgain(id)
    }

    /// Creates the cluster with the chosen applications. The account and region are read once, the choices are
    /// checked against them, and the request is sent to exactly that account and region.
    func createCluster(_ body: sending [String: Any]) async throws {
        let target = Target(apiKey: apiKey(), region: region())
        var body = body
        if let applications = try state.applicationsField(in: target.context) {
            body["applications"] = applications
        }
        try await api.createCluster(body, region: target.region, apiKey: target.apiKey)
    }

    /// The account and region one request is bound to. The key is only kept for the request.
    private struct Target {
        let apiKey: String
        let region: String

        var context: MarketplaceContext { MarketplaceContext(account: CivoAccount(apiKey: apiKey), region: region) }
    }
}
