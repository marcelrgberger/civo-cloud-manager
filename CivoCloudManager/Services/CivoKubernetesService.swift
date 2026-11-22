import Foundation

/// The requests of a cluster upgrade, each pinned to the account and region the upgrade was started in.
protocol KubernetesUpgradeAPI: Sendable {
    func listVersions(apiKey: String?) async throws -> [CivoKubernetesVersion]
    func showCluster(_ id: String, region: String?, apiKey: String?) async throws -> CivoKubernetesCluster
    func upgradeCluster(_ id: String, to version: String, region: String, apiKey: String) async throws
}

/// The requests of a node replacement, each pinned to the account and region the replacement was started in.
protocol KubernetesNodeRecycleAPI: Sendable {
    func showCluster(_ id: String, region: String?, apiKey: String?) async throws -> CivoKubernetesCluster
    func recycleNode(_ hostname: String, inCluster id: String, region: String, apiKey: String) async throws
}

/// The requests of a node pool change, each pinned to the account and region the change was started in.
protocol KubernetesNodePoolAPI: Sendable {
    func showCluster(_ id: String, region: String?, apiKey: String?) async throws -> CivoKubernetesCluster
    func listSizes(region: String, apiKey: String) async throws -> [CivoSize]
    func quota(apiKey: String) async throws -> CivoQuota
    func updatePools(_ pools: [CivoNodePoolSpec], inCluster id: String, region: String, apiKey: String) async throws
}

/// The requests of Create Cluster's marketplace part. Creating is pinned to the account and region the chosen
/// applications were reviewed for.
protocol KubernetesClusterCreateAPI: Sendable {
    func listApplications(apiKey: String?) async throws -> [RawMarketplaceEntry]
    func createCluster(_ body: sending [String: Any], region: String, apiKey: String) async throws
}

final class CivoKubernetesService: KubernetesUpgradeAPI, KubernetesNodeRecycleAPI, KubernetesNodePoolAPI, KubernetesClusterCreateAPI, Sendable {
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

    /// `GET /v2/kubernetes/applications`, documented without parameters. Each entry is read on its own, so only a
    /// failed request or an answer that is not a list fails the load.
    func listApplications(apiKey: String? = nil) async throws -> [RawMarketplaceEntry] {
        try await api.getArray(path: "/kubernetes/applications", regionRequired: false, apiKey: apiKey)
    }

    /// `POST /v2/kubernetes/clusters` in `region` with `apiKey`, never the account or region Settings point to
    /// by the time the request is built.
    func createCluster(_ body: sending [String: Any], region: String, apiKey: String) async throws {
        var body = body
        body["region"] = region
        let _: CivoKubernetesCluster = try await api.post(
            path: "/kubernetes/clusters",
            body: body,
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey
        )
    }

    /// `PUT /v2/kubernetes/clusters/:id` with the complete desired state of the pools, built by `KubernetesNodePoolPlan`.
    func updatePools(_ pools: [CivoNodePoolSpec], inCluster id: String, region: String, apiKey: String) async throws {
        let _: CivoKubernetesCluster = try await api.put(
            path: "/kubernetes/clusters/\(id)",
            body: try Self.poolsBody(pools, region: region),
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey
        )
    }

    /// Only `pools` and `region`, so the version and applications stay as they are. An empty array would delete
    /// every pool, so it is never sent.
    static func poolsBody(_ pools: [CivoNodePoolSpec], region: String) throws -> [String: Any] {
        guard !pools.isEmpty else { throw KubernetesNodePoolError.removesAllPools }
        return ["pools": pools.map(\.body), "region": region]
    }

    /// `GET /v2/sizes` for the region the change was started in.
    func listSizes(region: String, apiKey: String) async throws -> [CivoSize] {
        try await api.getArray(path: "/sizes", queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey)
    }

    /// `GET /v2/quota` of the account the change was started with.
    func quota(apiKey: String) async throws -> CivoQuota {
        try await api.get(path: "/quota", regionRequired: false, apiKey: apiKey)
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

    /// `POST /v2/kubernetes/clusters/:id/recycle`, which replaces the one node named by `hostname`.
    /// Civo's answer is a simple result (`SimpleResponse` in `civogo`) and only means the request was accepted.
    func recycleNode(_ hostname: String, inCluster id: String, region: String, apiKey: String) async throws {
        let _: CivoResult = try await api.post(
            path: "/kubernetes/clusters/\(id)/recycle",
            body: Self.recycleBody(hostname: hostname, region: region),
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey
        )
    }

    /// The body Civo's Go client `civogo` sends: the node's hostname and the cluster's region.
    static func recycleBody(hostname: String, region: String) -> [String: Any] {
        ["hostname": hostname, "region": region]
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
