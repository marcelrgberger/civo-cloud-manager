import Foundation

struct CivoVolume: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let status: String?
    let sizeGb: Int?
    let mountpoint: String?
    let instanceId: String?
    let clusterId: String?
    let networkId: String?

    let createdAt: String?
    let region: String?
    let bootable: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, status, mountpoint, region, bootable
        case sizeGb = "size_gb"
        case instanceId = "instance_id"
        case clusterId = "cluster_id"
        case networkId = "network_id"
        case createdAt = "created_at"
    }

    var sizeDisplay: String {
        if let sizeGb { return "\(sizeGb) GB" }
        return "—"
    }
}

// MARK: - Volumes of an instance

/// The volumes and networks of the region an instance was listed from.
/// Civo attaches a volume to one instance at a time, and only within its network.
struct InstanceVolumeOptions: Sendable {
    let region: String
    let volumes: [CivoVolume]
    let networks: [CivoNetwork]

    /// The volumes attached to the instance.
    func attached(to instance: CivoInstance) -> [CivoVolume] {
        volumes.filter { $0.instanceId == instance.id }
    }

    /// The volumes that may be attached to the instance: not attached to any instance, not owned by a
    /// Kubernetes cluster, and in the instance's network and region. A missing network ID on either side
    /// means the region's default network.
    func attachable(to instance: CivoInstance) -> [CivoVolume] {
        guard let networkId = networkId(instance.networkId) else { return [] }
        return volumes.filter { volume in
            volume.instanceId.isBlank
                && volume.clusterId.isBlank
                && self.networkId(volume.networkId) == networkId
                && (volume.region.isBlank || volume.region?.caseInsensitiveCompare(region) == .orderedSame)
        }
    }

    private func networkId(_ id: String?) -> String? {
        if let id, !id.isEmpty { return id }
        return networks.first { $0.isDefault == true }?.id
    }
}

private extension Optional where Wrapped == String {
    var isBlank: Bool { self?.isEmpty ?? true }
}
