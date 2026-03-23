import Foundation

struct CivoSnapshotService: Sendable {
    private let api = CivoAPIClient.shared

    func listSnapshots() async throws -> [CivoSnapshot] {
        try await api.getArray(path: "/snapshots")
    }

    func createSnapshot(_ body: sending [String: Any]) async throws -> CivoSnapshot {
        try await api.post(path: "/snapshots", body: body)
    }

    func removeSnapshot(_ id: String) async throws {
        try await api.delete(path: "/snapshots/\(id)")
    }
}
