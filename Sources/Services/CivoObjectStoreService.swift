import Foundation

final class CivoObjectStoreService: Sendable {
    private let api = CivoAPIClient.shared

    func listObjectStores() async throws -> [CivoObjectStore] {
        try await api.getPaginatedList(path: "/objectstores")
    }

    func showObjectStore(_ id: String) async throws -> CivoObjectStore {
        try await api.get(path: "/objectstores/\(id)")
    }

    func createObjectStore(_ body: [String: Any]) async throws -> CivoObjectStore {
        try await api.post(path: "/objectstores", body: body)
    }

    func updateObjectStore(_ id: String, body: [String: Any]) async throws -> CivoObjectStore {
        try await api.put(path: "/objectstores/\(id)", body: body)
    }

    func removeObjectStore(_ id: String) async throws {
        try await api.delete(path: "/objectstores/\(id)")
    }
}
