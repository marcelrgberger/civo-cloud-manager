import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var quota: CivoQuota?
    var clusterCount: Int?
    var databaseCount: Int?
    var volumeCount: Int?
    var objectStoreCount: Int?
    var loadBalancerCount: Int?
    var networkCount: Int?
    var isLoading = false
    var error: String?
    var warnings: [String] = []

    var isEditingQuota = false
    var isSavingQuota = false
    var quotaSaveError: String?
    var showSuccess = false

    private let quotaService = CivoQuotaService()
    private let kubernetesService = CivoKubernetesService()
    private let databaseService = CivoDatabaseService()
    private let volumeService = CivoVolumeService()
    private let objectStoreService = CivoObjectStoreService()
    private let loadBalancerService = CivoLoadBalancerService()
    private let networkService = CivoNetworkService()

    func refresh() async {
        isLoading = true
        error = nil
        warnings = []
        quota = nil
        clusterCount = nil
        databaseCount = nil
        volumeCount = nil
        objectStoreCount = nil
        loadBalancerCount = nil
        networkCount = nil
        defer { isLoading = false }

        do {
            quota = try await quotaService.getQuota()
        } catch {
            self.error = error.localizedDescription
            Log.error("Dashboard quota fetch failed: \(error.localizedDescription)")
        }

        async let clusters = kubernetesService.listClusters()
        async let databases = databaseService.listDatabases()
        async let volumes = volumeService.listVolumes()
        async let objectStores = objectStoreService.listObjectStores()
        async let loadBalancers = loadBalancerService.listLoadBalancers()
        async let networks = networkService.listNetworks()

        do { clusterCount = try await clusters.count } catch {
            warnings.append("Kubernetes: \(error.localizedDescription)")
        }
        do { databaseCount = try await databases.count } catch {
            warnings.append("Databases: \(error.localizedDescription)")
        }
        do { volumeCount = try await volumes.count } catch {
            warnings.append("Volumes: \(error.localizedDescription)")
        }
        do { objectStoreCount = try await objectStores.count } catch {
            warnings.append("Object Stores: \(error.localizedDescription)")
        }
        do { loadBalancerCount = try await loadBalancers.count } catch {
            warnings.append("Load Balancers: \(error.localizedDescription)")
        }
        do { networkCount = try await networks.count } catch {
            warnings.append("Networks: \(error.localizedDescription)")
        }
    }

    func requestQuotaChange(_ body: sending [String: Any]) async -> Bool {
        isSavingQuota = true
        quotaSaveError = nil
        defer { isSavingQuota = false }

        do {
            _ = try await quotaService.requestQuotaChange(body)
            isEditingQuota = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            quotaSaveError = error.localizedDescription
            return false
        }
    }
}
