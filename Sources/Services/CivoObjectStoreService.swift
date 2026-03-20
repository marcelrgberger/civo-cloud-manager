import Foundation

final class CivoObjectStoreService: Sendable {
    private let api = CivoAPIClient.shared

    func listObjectStores() async throws -> [CivoObjectStore] {
        try await api.getPaginatedList(path: "/objectstores")
    }

    func createObjectStore(_ body: [String: Any]) async throws -> CivoObjectStore {
        try await api.post(path: "/objectstores", body: body)
    }

    func getCredentials() async throws -> CivoObjectStoreCredential {
        try await api.get(path: "/objectstores/credentials")
    }

    func removeObjectStore(_ id: String) async throws {
        try await api.delete(path: "/objectstores/\(id)")
    }
}
