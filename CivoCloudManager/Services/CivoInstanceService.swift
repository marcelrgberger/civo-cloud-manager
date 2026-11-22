import Foundation

/// Requests for one existing instance. Each takes the region the instance was listed from,
/// never the current Settings region, so a later region change cannot redirect them.
protocol InstanceAPI: Sendable {
    func listInstances(region: String?) async throws -> PaginatedList<CivoInstance>
    func updateInstance(_ id: String, body: sending [String: Any], region: String) async throws
    func stopInstance(_ id: String, region: String) async throws
    func startInstance(_ id: String, region: String) async throws
    func rebootInstance(_ id: String, region: String) async throws
    func resizeInstance(_ id: String, size: String, region: String) async throws
    func removeInstance(_ id: String, region: String) async throws
}

final class CivoInstanceService: InstanceAPI {
    private let api = CivoAPIClient.shared

    func listInstances(region: String? = nil) async throws -> PaginatedList<CivoInstance> {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getPaginatedList(path: "/instances", queryItems: queryItems)
    }

    func createInstance(_ body: [String: Any]) async throws -> CivoInstance {
        try await api.post(path: "/instances", body: body)
    }

    func updateInstance(_ id: String, body: sending [String: Any], region: String) async throws {
        let _: CivoInstance = try await api.put(path: "/instances/\(id)", body: body, queryItems: Self.pinned(region))
    }

    func stopInstance(_ id: String, region: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/stop", body: [:], queryItems: Self.pinned(region))
    }

    func startInstance(_ id: String, region: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/start", body: [:], queryItems: Self.pinned(region))
    }

    func rebootInstance(_ id: String, region: String) async throws {
        let _: CivoResult = try await api.post(path: "/instances/\(id)/soft_reboots", body: [:], queryItems: Self.pinned(region))
    }

    func resizeInstance(_ id: String, size: String, region: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/resize", body: ["size": size], queryItems: Self.pinned(region))
    }

    func setFirewall(_ instanceId: String, firewallId: String) async throws {
        let _: CivoInstance = try await api.put(path: "/instances/\(instanceId)/firewall", body: ["firewall_id": firewallId])
    }

    func removeInstance(_ id: String, region: String) async throws {
        try await api.delete(path: "/instances/\(id)", queryItems: Self.pinned(region))
    }

    /// An empty region stays empty, so the client throws `noRegion` instead of using Settings.
    private static func pinned(_ region: String) -> [URLQueryItem] {
        [URLQueryItem(name: "region", value: region)]
    }
}
