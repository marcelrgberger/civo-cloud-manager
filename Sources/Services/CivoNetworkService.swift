import Foundation

final class CivoNetworkService: Sendable {
    private let api = CivoAPIClient.shared

    func listNetworks() async throws -> [CivoNetwork] {
        try await api.getArray(path: "/networks")
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
