import Foundation

final class CivoNetworkService: Sendable {
    private let api = CivoAPIClient.shared

    func listNetworks(region: String? = nil) async throws -> [CivoNetwork] {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getArray(path: "/networks", queryItems: queryItems)
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
