import Foundation

/// The load balancer requests of the create form and the editor, each pinned to one account and region.
protocol LoadBalancerAPI: Sendable {
    func listLoadBalancers(region: String, apiKey: String) async throws -> [CivoLoadBalancer]
    func getLoadBalancer(_ id: String, region: String, apiKey: String) async throws -> CivoLoadBalancer
    func listNetworks(region: String, apiKey: String) async throws -> [CivoNetwork]
    func createLoadBalancer(body: sending [String: Any], region: String, apiKey: String) async throws -> CivoLoadBalancer
    func updateLoadBalancer(_ id: String, body: sending [String: Any], region: String, apiKey: String) async throws -> CivoLoadBalancer
}

/// https://www.civo.com/api/vpc, "VPC Load Balancers". Backends have no endpoints of their own; they are part of
/// the load balancer's create and update requests. The pinned requests keep Civo's answer text and decoding details
/// out of errors and the log, as the app never shows them.
final class CivoLoadBalancerService: LoadBalancerAPI, Sendable {
    private let api = CivoAPIClient.shared
    private let networkService = CivoNetworkService()

    /// The list for the current account and region, for counts that bind nothing to it.
    func listLoadBalancers() async throws -> [CivoLoadBalancer] {
        try await api.getArray(path: "/loadbalancers")
    }

    func listLoadBalancers(region: String, apiKey: String) async throws -> [CivoLoadBalancer] {
        try await api.getArray(path: "/loadbalancers", queryItems: Self.query(region), apiKey: apiKey, redactDiagnostics: true)
    }

    func getLoadBalancer(_ id: String, region: String, apiKey: String) async throws -> CivoLoadBalancer {
        try await api.get(path: "/loadbalancers/\(id)", queryItems: Self.query(region), apiKey: apiKey, redactDiagnostics: true)
    }

    func listNetworks(region: String, apiKey: String) async throws -> [CivoNetwork] {
        try await networkService.listNetworks(region: region, apiKey: apiKey)
    }

    func createLoadBalancer(body: sending [String: Any], region: String, apiKey: String) async throws -> CivoLoadBalancer {
        try await api.post(path: "/loadbalancers", body: body, queryItems: Self.query(region), apiKey: apiKey, redactDiagnostics: true)
    }

    func updateLoadBalancer(_ id: String, body: sending [String: Any], region: String, apiKey: String) async throws -> CivoLoadBalancer {
        try await api.put(path: "/loadbalancers/\(id)", body: body, queryItems: Self.query(region), apiKey: apiKey, redactDiagnostics: true)
    }

    func removeLoadBalancer(_ id: String) async throws {
        try await api.delete(path: "/loadbalancers/\(id)")
    }

    /// A pinned key needs the region in the query, since the client then reads no settings.
    private static func query(_ region: String) -> [URLQueryItem] {
        [URLQueryItem(name: "region", value: region)]
    }
}
