import Foundation

@Observable
@MainActor
final class KubernetesViewModel {
    var clusters: [CivoKubernetesCluster] = []
    var selectedCluster: CivoKubernetesCluster?
    var isLoading = false
    var error: String?

    // Create/Edit state
    var isCreating = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    // Form picker data
    var availableNetworks: [CivoNetwork] = []
    var availableSizes: [CivoSize] = []

    private let service = CivoKubernetesService()
    private let networkService = CivoNetworkService()
    private let sizeService = CivoSizeService()

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

    func loadFormData() async {
        do {
            async let nets = networkService.listNetworks()
            async let sizes = sizeService.listSizes()
            availableNetworks = try await nets
            availableSizes = try await sizes
        } catch {
            Log.error("Failed to load form data: \(error.localizedDescription)")
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

    func createCluster(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.createCluster(body)
            isCreating = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func updateCluster(_ id: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.updateCluster(id, body: body)
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
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
