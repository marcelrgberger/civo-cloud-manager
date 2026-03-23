import Foundation

struct RegionResourceCounts: Sendable {
    var instances: Int?
    var clusters: Int?
    var databases: Int?
    var networks: Int?
    var volumes: Int?
    var isLoading = false

    var total: Int {
        (instances ?? 0) + (clusters ?? 0) + (databases ?? 0) + (networks ?? 0) + (volumes ?? 0)
    }
}

@Observable
@MainActor
final class RegionViewModel {
    var regions: [CivoRegion] = []
    var regionCounts: [String: RegionResourceCounts] = [:]
    var isLoading = false
    var error: String?

    private let service = CivoRegionService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            regions = try await service.listRegions()
        } catch {
            self.error = error.localizedDescription
            Log.error("Region list failed: \(error.localizedDescription)")
        }
    }

    var isLoadingCounts = false

    func loadCurrentRegionCounts() async {
        let currentCode = CivoConfig.shared.region
        isLoadingCounts = true
        regionCounts[currentCode] = RegionResourceCounts(isLoading: true)

        var counts = RegionResourceCounts()
        do { counts.instances = try await CivoInstanceService().listInstances().count } catch {}
        do { counts.clusters = try await CivoKubernetesService().listClusters().count } catch {}
        do { counts.databases = try await CivoDatabaseService().listDatabases().count } catch {}
        do { counts.networks = try await CivoNetworkService().listNetworks().count } catch {}
        do { counts.volumes = try await CivoVolumeService().listVolumes().count } catch {}

        regionCounts[currentCode] = counts
        isLoadingCounts = false
    }

    func useRegion(_ code: String) {
        CivoConfig.shared.region = code
    }
}
