import Foundation

final class CivoInstanceService: Sendable {
    private let api = CivoAPIClient.shared

    func listInstances() async throws -> [CivoInstance] {
        try await api.getPaginatedList(path: "/instances")
    }

    func createInstance(_ body: [String: Any]) async throws -> CivoInstance {
        try await api.post(path: "/instances", body: body)
    }

    func updateInstance(_ id: String, body: [String: Any]) async throws -> CivoInstance {
        try await api.put(path: "/instances/\(id)", body: body)
    }

    func removeInstance(_ id: String) async throws {
        try await api.delete(path: "/instances/\(id)")
    }
}
