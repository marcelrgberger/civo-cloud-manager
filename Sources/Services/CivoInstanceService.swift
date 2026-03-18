import Foundation

final class CivoInstanceService: Sendable {
    private let api = CivoAPIClient.shared

    func listInstances() async throws -> [CivoInstance] {
        try await api.getPaginatedList(path: "/instances")
    }

    func removeInstance(_ id: String) async throws {
        try await api.delete(path: "/instances/\(id)")
    }
}
