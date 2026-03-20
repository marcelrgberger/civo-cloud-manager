import Foundation

final class CivoVolumeService: Sendable {
    private let api = CivoAPIClient.shared

    func listVolumes() async throws -> [CivoVolume] {
        try await api.getArray(path: "/volumes")
    }

    func createVolume(_ body: [String: Any]) async throws -> CivoVolume {
        try await api.post(path: "/volumes", body: body)
    }

    func removeVolume(_ id: String) async throws {
        try await api.delete(path: "/volumes/\(id)")
    }
}
