import Foundation

final class CivoObjectStoreService: Sendable {
    private let api = CivoAPIClient.shared

    func listObjectStores() async throws -> [CivoObjectStore] {
        try await api.getPaginatedList(path: "/objectstores")
    }

    func removeObjectStore(_ id: String) async throws {
        try await api.delete(path: "/objectstores/\(id)")
    }
}
