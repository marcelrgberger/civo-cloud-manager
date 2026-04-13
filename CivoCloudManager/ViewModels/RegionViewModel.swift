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
    var currentRegion = CivoConfig.shared.region

    private let service = CivoRegionService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            regions = try await service.listRegions()
        } catch {
            self.error = CivoAPIError.userMessage(error)
            Log.error("Region list failed: \(error.localizedDescription)")
        }
    }

    var isLoadingCounts = false

    func loadAllRegionCounts() async {
        isLoadingCounts = true

        for region in regions {
            regionCounts[region.code] = RegionResourceCounts(isLoading: true)
        }

        let userRegion = CivoConfig.shared.region
        for region in regions {
            // Temporarily swap region for API calls, restore immediately after each
            CivoConfig.shared.region = region.code

            var counts = RegionResourceCounts()
            do { counts.instances = try await CivoInstanceService().listInstances().count } catch {}
            do { counts.clusters = try await CivoKubernetesService().listClusters().count } catch {}
            do { counts.databases = try await CivoDatabaseService().listDatabases().count } catch {}
            do { counts.networks = try await CivoNetworkService().listNetworks().count } catch {}
            do { counts.volumes = try await CivoVolumeService().listVolumes().count } catch {}

            regionCounts[region.code] = counts
            CivoConfig.shared.region = userRegion
        }

        isLoadingCounts = false
    }

    /// Called from MainWindowView to refresh all ViewModels after region switch.
    var onRegionChanged: (@MainActor () async -> Void)?

    func useRegion(_ code: String) async {
        CivoConfig.shared.region = code
        currentRegion = code
        // Refresh all VMs first while region is stable
        await onRegionChanged?()
        // Then count all regions (swaps region temporarily per-region)
        await loadAllRegionCounts()
    }
}
