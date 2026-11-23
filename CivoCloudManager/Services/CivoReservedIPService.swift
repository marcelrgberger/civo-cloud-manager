import Foundation

/// Reserved IP requests. Every request takes the region and the API key it was confirmed with,
/// never the current Settings, so a later account or region change cannot redirect it.
protocol ReservedIPAPI: Sendable {
    func listReservedIPs(region: String, apiKey: String) async throws -> PaginatedList<CivoReservedIP>
    func showReservedIP(_ id: String, region: String, apiKey: String) async throws -> CivoReservedIP
    func reserve(name: String, region: String, apiKey: String) async throws -> ReservedIPAck
    func rename(_ id: String, to name: String, region: String, apiKey: String) async throws -> ReservedIPAck
    func assign(_ id: String, toInstance instanceId: String, region: String, apiKey: String) async throws -> ReservedIPActionResult
    func unassign(_ id: String, region: String, apiKey: String) async throws -> ReservedIPActionResult
    func release(_ id: String, region: String, apiKey: String) async throws -> ReservedIPActionResult
    func listInstances(region: String, apiKey: String) async throws -> PaginatedList<ReservedIPInstanceChoice>
}

/// https://www.civo.com/api/vpc, section "VPC Reserved IPs". Civo requires `assign_to_type` for an assignment
/// although the reference does not list it.
final class CivoReservedIPService: ReservedIPAPI {
    private let api: CivoAPIClient

    init(api: CivoAPIClient = .shared) {
        self.api = api
    }

    func listReservedIPs(region: String, apiKey: String) async throws -> PaginatedList<CivoReservedIP> {
        try await api.getPaginatedList(path: "/ips", queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func showReservedIP(_ id: String, region: String, apiKey: String) async throws -> CivoReservedIP {
        try await api.get(path: "/ips/\(id)", queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func reserve(name: String, region: String, apiKey: String) async throws -> ReservedIPAck {
        try await api.post(path: "/ips", body: ["name": name], queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func rename(_ id: String, to name: String, region: String, apiKey: String) async throws -> ReservedIPAck {
        try await api.put(path: "/ips/\(id)", body: ["name": name], queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func assign(_ id: String, toInstance instanceId: String, region: String, apiKey: String) async throws -> ReservedIPActionResult {
        try await api.post(
            path: "/ips/\(id)/actions",
            body: ["action": "assign", "assign_to_id": instanceId, "assign_to_type": ReservedIPAssignment.instanceType],
            queryItems: Self.pinned(region),
            apiKey: apiKey
        )
    }

    func unassign(_ id: String, region: String, apiKey: String) async throws -> ReservedIPActionResult {
        try await api.post(path: "/ips/\(id)/actions", body: ["action": "unassign"], queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func release(_ id: String, region: String, apiKey: String) async throws -> ReservedIPActionResult {
        try await api.delete(path: "/ips/\(id)", queryItems: Self.pinned(region), apiKey: apiKey)
    }

    func listInstances(region: String, apiKey: String) async throws -> PaginatedList<ReservedIPInstanceChoice> {
        try await api.getPaginatedList(path: "/instances", queryItems: Self.pinned(region), apiKey: apiKey, redactDiagnostics: true)
    }

    /// An empty region stays empty, so the client throws `noRegion` instead of using Settings.
    private static func pinned(_ region: String) -> [URLQueryItem] {
        [URLQueryItem(name: "region", value: region)]
    }
}
