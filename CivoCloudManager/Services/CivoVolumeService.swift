import Foundation

/// Attaching and detaching volumes from an instance's detail page, pinned to the instance's region.
protocol InstanceVolumeAPI: Sendable {
    func volumeOptions(region: String) async throws -> InstanceVolumeOptions
    func attachVolume(_ volumeId: String, to instanceId: String, region: String) async throws
    func detachVolume(_ volumeId: String, region: String) async throws
}

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

    func resizeVolume(_ volumeId: String, sizeGb: Int) async throws {
        let _: CivoResult = try await api.put(path: "/volumes/\(volumeId)/resize", body: ["size_gb": sizeGb])
    }

    func removeVolume(_ id: String) async throws {
        try await api.delete(path: "/volumes/\(id)")
    }
}

extension CivoVolumeService: InstanceVolumeAPI {
    func volumeOptions(region: String) async throws -> InstanceVolumeOptions {
        async let volumes = listVolumes(region: region)
        async let networks = CivoNetworkService().listNetworks(region: region)
        return try await InstanceVolumeOptions(region: region, volumes: volumes, networks: networks)
    }

    /// Civo requires the region in the body as well.
    func attachVolume(_ volumeId: String, to instanceId: String, region: String) async throws {
        let _: CivoResult = try await api.put(
            path: "/volumes/\(volumeId)/attach",
            body: ["instance_id": instanceId, "region": region],
            queryItems: [URLQueryItem(name: "region", value: region)]
        )
    }

    /// Civo requires the region in the body as well.
    func detachVolume(_ volumeId: String, region: String) async throws {
        let _: CivoResult = try await api.put(
            path: "/volumes/\(volumeId)/detach",
            body: ["region": region],
            queryItems: [URLQueryItem(name: "region", value: region)]
        )
    }
}
