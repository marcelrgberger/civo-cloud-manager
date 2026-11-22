import Foundation

final class CivoNetworkService: Sendable {
    private let api: CivoAPIClient

    init(api: CivoAPIClient = .shared) { self.api = api }

    func listNetworks(region: String? = nil) async throws -> [CivoNetwork] {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getArray(path: "/networks", queryItems: queryItems)
    }

    /// Pinned to one account and region. Civo's answer text and decoding details stay out of errors and the log.
    func listNetworks(region: String, apiKey: String) async throws -> [CivoNetwork] {
        try await api.getArray(path: "/networks", queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey, redactDiagnostics: true)
    }

    func createNetwork(_ body: [String: Any]) async throws -> CivoNetwork {
        try await api.post(path: "/networks", body: body)
    }

    func updateNetwork(_ id: String, body: [String: Any]) async throws -> CivoNetwork {
        try await api.put(path: "/networks/\(id)", body: body)
    }

    func removeNetwork(_ id: String) async throws {
        try await api.delete(path: "/networks/\(id)")
    }
}
