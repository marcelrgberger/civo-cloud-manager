import Foundation

final class CivoKubernetesService: Sendable {
    private let api = CivoAPIClient.shared

    func listClusters() async throws -> [CivoKubernetesCluster] {
        try await api.getPaginatedList(path: "/kubernetes/clusters")
    }

    func showCluster(_ id: String) async throws -> CivoKubernetesCluster {
        try await api.get(path: "/kubernetes/clusters/\(id)")
    }

    func createCluster(_ body: [String: Any]) async throws -> CivoKubernetesCluster {
        try await api.post(path: "/kubernetes/clusters", body: body)
    }

    func updateCluster(_ id: String, body: [String: Any]) async throws -> CivoKubernetesCluster {
        try await api.put(path: "/kubernetes/clusters/\(id)", body: body)
    }

    func getKubeconfig(_ id: String) async throws -> String {
        let cluster: CivoKubernetesCluster = try await api.get(path: "/kubernetes/clusters/\(id)")
        guard let kubeconfig = cluster.kubeconfig, !kubeconfig.isEmpty else {
            throw CivoAPIError.decodingError("No kubeconfig available for this cluster")
        }
        return kubeconfig
    }

    func removeCluster(_ id: String) async throws {
        try await api.delete(path: "/kubernetes/clusters/\(id)")
    }
}
