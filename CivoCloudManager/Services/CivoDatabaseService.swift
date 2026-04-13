import Foundation

final class CivoDatabaseService: Sendable {
    private let api = CivoAPIClient.shared

    func listDatabases(region: String? = nil) async throws -> [CivoDatabase] {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getPaginatedList(path: "/databases", queryItems: queryItems)
    }

    func createDatabase(_ body: [String: Any]) async throws -> CivoDatabase {
        try await api.post(path: "/databases", body: body)
    }

    func removeDatabase(_ id: String) async throws {
        try await api.delete(path: "/databases/\(id)")
    }
}
