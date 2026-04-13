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

        await withTaskGroup(of: (String, RegionResourceCounts).self) { group in
            for region in regions {
                let code = region.code
                group.addTask {
                    var counts = RegionResourceCounts()
                    async let insts = CivoInstanceService().listInstances(region: code)
                    async let clusters = CivoKubernetesService().listClusters(region: code)
                    async let dbs = CivoDatabaseService().listDatabases(region: code)
                    async let nets = CivoNetworkService().listNetworks(region: code)
                    async let vols = CivoVolumeService().listVolumes(region: code)
                    counts.instances = (try? await insts)?.count
                    counts.clusters = (try? await clusters)?.count
                    counts.databases = (try? await dbs)?.count
                    counts.networks = (try? await nets)?.count
                    counts.volumes = (try? await vols)?.count
                    return (code, counts)
                }
            }
            for await (code, counts) in group {
                regionCounts[code] = counts
            }
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
