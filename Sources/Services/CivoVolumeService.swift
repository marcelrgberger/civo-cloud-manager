import Foundation

final class CivoVolumeService: Sendable {
    private let api = CivoAPIClient.shared

    func listVolumes() async throws -> [CivoVolume] {
        try await api.getArray(path: "/volumes")
    }

    func removeVolume(_ id: String) async throws {
        try await api.delete(path: "/volumes/\(id)")
    }
}
