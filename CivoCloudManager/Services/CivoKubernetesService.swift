import Foundation

/// The requests of a cluster upgrade, each pinned to the account and region the upgrade was started in.
protocol KubernetesUpgradeAPI: Sendable {
    func listVersions(apiKey: String?) async throws -> [CivoKubernetesVersion]
    func showCluster(_ id: String, region: String?, apiKey: String?) async throws -> CivoKubernetesCluster
    func upgradeCluster(_ id: String, to version: String, region: String, apiKey: String) async throws
}

final class CivoKubernetesService: KubernetesUpgradeAPI, Sendable {
    private let api = CivoAPIClient.shared

    func listClusters(region: String? = nil) async throws -> PaginatedList<CivoKubernetesCluster> {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getPaginatedList(path: "/kubernetes/clusters", queryItems: queryItems)
    }

    /// `apiKey` pins the request to one account instead of reading the current key.
    func showCluster(_ id: String, region: String? = nil, apiKey: String? = nil) async throws -> CivoKubernetesCluster {
        try await api.get(path: "/kubernetes/clusters/\(id)", queryItems: region.map { [URLQueryItem(name: "region", value: $0)] }, apiKey: apiKey)
    }

    /// `GET /v2/kubernetes/versions`, documented without parameters.
    func listVersions(apiKey: String? = nil) async throws -> [CivoKubernetesVersion] {
        try await api.getArray(path: "/kubernetes/versions", regionRequired: false, apiKey: apiKey)
    }

    func createCluster(_ body: [String: Any]) async throws -> CivoKubernetesCluster {
        try await api.post(path: "/kubernetes/clusters", body: body)
    }

    func updateCluster(_ id: String, body: [String: Any]) async throws -> CivoKubernetesCluster {
        try await api.put(path: "/kubernetes/clusters/\(id)", body: body)
    }

    /// `PUT /v2/kubernetes/clusters/:id` with only the target version, so pools and applications stay as they are.
    func upgradeCluster(_ id: String, to version: String, region: String, apiKey: String) async throws {
        let _: CivoKubernetesCluster = try await api.put(
            path: "/kubernetes/clusters/\(id)",
            body: Self.upgradeBody(to: version, region: region),
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey
        )
    }

    /// Civo treats `pools` as the complete desired state, so an upgrade must not send it, nor `applications`.
    static func upgradeBody(to version: String, region: String) -> [String: Any] {
        ["kubernetes_version": version, "region": region]
    }

    func getKubeconfig(_ id: String) async throws -> String {
        let cluster: CivoKubernetesCluster = try await api.get(path: "/kubernetes/clusters/\(id)")
        guard let kubeconfig = cluster.kubeconfig, !kubeconfig.isEmpty else {
            throw CivoAPIError.decodingError("No kubeconfig available for this cluster")
        }
        return kubeconfig
    }

    func removeCluster(_ id: String) async throws {
        try await api.delete(path: "/kubernetes/clusters/\(id)")
    }
}
