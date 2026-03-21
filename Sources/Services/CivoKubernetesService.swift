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
        try await api.getRaw(path: "/kubernetes/clusters/\(id)/kubeconfig")
    }

    func removeCluster(_ id: String) async throws {
        try await api.delete(path: "/kubernetes/clusters/\(id)")
    }
}
