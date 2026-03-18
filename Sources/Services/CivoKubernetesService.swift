import Foundation

final class CivoKubernetesService: Sendable {
    private let api = CivoAPIClient.shared

    func listClusters() async throws -> [CivoKubernetesCluster] {
        try await api.getPaginatedList(path: "/kubernetes/clusters")
    }

    func showCluster(_ id: String) async throws -> CivoKubernetesCluster {
        try await api.get(path: "/kubernetes/clusters/\(id)")
    }

    func removeCluster(_ id: String) async throws {
        try await api.delete(path: "/kubernetes/clusters/\(id)")
    }
}
