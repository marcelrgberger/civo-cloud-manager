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

    func stopInstance(_ id: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/stop", body: [:])
    }

    func startInstance(_ id: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/start", body: [:])
    }

    func rebootInstance(_ id: String) async throws {
        let _: CivoResult = try await api.post(path: "/instances/\(id)/soft_reboots", body: [:])
    }

    func removeInstance(_ id: String) async throws {
        try await api.delete(path: "/instances/\(id)")
    }
}
