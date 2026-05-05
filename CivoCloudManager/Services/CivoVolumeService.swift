import Foundation

final class CivoVolumeService: Sendable {
    private let api = CivoAPIClient.shared

    func listVolumes(region: String? = nil) async throws -> [CivoVolume] {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getArray(path: "/volumes", queryItems: queryItems)
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

    func resizeVolume(_ volumeId: String, sizeGb: Int) async throws {
        let _: CivoResult = try await api.put(path: "/volumes/\(volumeId)/resize", body: ["size_gb": sizeGb])
    }

    func removeVolume(_ id: String) async throws {
        try await api.delete(path: "/volumes/\(id)")
    }
}
