import Foundation

final class CivoNetworkService: Sendable {
    private let api = CivoAPIClient.shared

    /// `apiKey` pins the request to one account instead of reading the current key.
    func listNetworks(region: String? = nil, apiKey: String? = nil) async throws -> [CivoNetwork] {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getArray(path: "/networks", queryItems: queryItems, apiKey: apiKey)
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
