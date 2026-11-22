import Foundation

final class CivoObjectStoreService: Sendable {
    private let api: CivoAPIClient

    init(api: CivoAPIClient = .shared) { self.api = api }

    // MARK: - Object Stores

    func listObjectStores() async throws -> PaginatedList<CivoObjectStore> {
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

    func listCredentials() async throws -> PaginatedList<CivoObjectStoreCredential> {
        try await api.getPaginatedList(path: "/objectstore/credentials")
    }

    func showCredential(_ id: String) async throws -> CivoObjectStoreCredential {
        try await api.get(path: "/objectstore/credentials/\(id)")
    }

    func createCredential(_ body: [String: Any]) async throws -> CivoObjectStoreCredential {
        try await api.post(path: "/objectstore/credentials", body: body)
    }

    func removeCredential(_ id: String) async throws {
        try await api.delete(path: "/objectstore/credentials/\(id)")
    }
}

protocol ObjectStoreCredentialAPI: Sendable {
    func listObjectStores(region: String, apiKey: String) async throws -> PaginatedList<CivoObjectStore>
    func showObjectStore(_ id: String, region: String, apiKey: String) async throws -> CivoObjectStore
    func listCredentials(region: String, apiKey: String) async throws -> PaginatedList<CivoObjectStoreCredential>
    func changeCredential(of id: String, to accessKeyId: String, region: String, apiKey: String) async throws -> CivoObjectStore
}

extension CivoObjectStoreService: ObjectStoreCredentialAPI {
    func listObjectStores(region: String, apiKey: String) async throws -> PaginatedList<CivoObjectStore> {
        try await api.getPaginatedList(path: "/objectstores", queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey, redactDiagnostics: true)
    }

    func showObjectStore(_ id: String, region: String, apiKey: String) async throws -> CivoObjectStore {
        try await api.get(path: "/objectstores/\(id)", queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey, redactDiagnostics: true)
    }

    func listCredentials(region: String, apiKey: String) async throws -> PaginatedList<CivoObjectStoreCredential> {
        try await api.getPaginatedList(path: "/objectstore/credentials", queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey, redactDiagnostics: true)
    }

    static func credentialChangeBody(region: String, accessKeyId: String) -> [String: String] {
        ["region": region, "access_key_id": accessKeyId]
    }

    func changeCredential(of id: String, to accessKeyId: String, region: String, apiKey: String) async throws -> CivoObjectStore {
        try await api.patch(path: "/objectstores/\(id)", body: Self.credentialChangeBody(region: region, accessKeyId: accessKeyId), queryItems: [URLQueryItem(name: "region", value: region)], apiKey: apiKey, redactDiagnostics: true)
    }
}
