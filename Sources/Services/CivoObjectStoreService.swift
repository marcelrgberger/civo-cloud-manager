import Foundation

final class CivoObjectStoreService: Sendable {
    private let api = CivoAPIClient.shared

    // MARK: - Object Stores

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

    // MARK: - Credentials

    func listCredentials() async throws -> [CivoObjectStoreCredential] {
        try await api.getPaginatedList(path: "/objectstore/credentials")
    }

    func showCredential(_ id: String) async throws -> CivoObjectStoreCredential {
        try await api.get(path: "/objectstores/credentials/\(id)")
    }

    func createCredential(_ body: [String: Any]) async throws -> CivoObjectStoreCredential {
        try await api.post(path: "/objectstore/credentials", body: body)
    }

    func removeCredential(_ id: String) async throws {
        try await api.delete(path: "/objectstore/credentials/\(id)")
    }
}
