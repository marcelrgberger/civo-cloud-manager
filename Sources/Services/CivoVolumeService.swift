import Foundation

final class CivoVolumeService: Sendable {
    private let api = CivoAPIClient.shared

    func listVolumes() async throws -> [CivoVolume] {
        try await api.getArray(path: "/volumes")
    }

    func createVolume(_ body: [String: Any]) async throws -> CivoVolume {
        try await api.post(path: "/volumes", body: body)
    }

    func attachVolume(_ volumeId: String, instanceId: String) async throws {
        let _: CivoResult = try await api.put(path: "/volumes/\(volumeId)/attach", body: ["instance_id": instanceId])
    }

    func detachVolume(_ volumeId: String) async throws {
        let _: CivoResult = try await api.put(path: "/volumes/\(volumeId)/detach", body: [:])
    }

    func removeVolume(_ id: String) async throws {
        try await api.delete(path: "/volumes/\(id)")
    }
}
