import Foundation

@Observable
@MainActor
final class KubernetesViewModel {
    var clusters: [CivoKubernetesCluster] = []
    var selectedCluster: CivoKubernetesCluster?
    var isLoading = false
    var error: String?

    private let service = CivoKubernetesService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            clusters = try await service.listClusters()
        } catch {
            self.error = error.localizedDescription
            Log.error("Kubernetes list failed: \(error.localizedDescription)")
        }
    }

    func loadClusterDetail(_ id: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            selectedCluster = try await service.showCluster(id)
        } catch {
            self.error = error.localizedDescription
            Log.error("Kubernetes show failed: \(error.localizedDescription)")
        }
    }

    func removeCluster(_ id: String) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await service.removeCluster(id)
            await refresh()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
