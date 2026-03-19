import Foundation

final class CivoDatabaseService: Sendable {
    private let api = CivoAPIClient.shared

    func listDatabases() async throws -> [CivoDatabase] {
        try await api.getPaginatedList(path: "/databases")
    }

    func removeDatabase(_ id: String) async throws {
        try await api.delete(path: "/databases/\(id)")
    }
}
