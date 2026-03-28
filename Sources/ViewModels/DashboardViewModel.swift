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
            self.error = CivoAPIError.userMessage(error)
            Log.error("Dashboard quota fetch failed: \(error.localizedDescription)")
        }

        async let clusters = kubernetesService.listClusters()
        async let databases = databaseService.listDatabases()
        async let volumes = volumeService.listVolumes()
        async let objectStores = objectStoreService.listObjectStores()
        async let loadBalancers = loadBalancerService.listLoadBalancers()
        async let networks = networkService.listNetworks()

        do { clusterCount = try await clusters.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Kubernetes: \(msg)") }
        }
        do { databaseCount = try await databases.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Databases: \(msg)") }
        }
        do { volumeCount = try await volumes.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Volumes: \(msg)") }
        }
        do { objectStoreCount = try await objectStores.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Object Stores: \(msg)") }
        }
        do { loadBalancerCount = try await loadBalancers.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Load Balancers: \(msg)") }
        }
        do { networkCount = try await networks.count } catch {
            if let msg = CivoAPIError.userMessage(error) { warnings.append("Networks: \(msg)") }
        }
    }

    // MARK: - Quota Warnings

    enum QuotaWarningLevel: Sendable {
        case warning  // >= 80%
        case critical // >= 90%
    }

    struct QuotaWarning: Identifiable, Sendable {
        let field: String
        let usage: Int
        let limit: Int
        let level: QuotaWarningLevel

        var id: String { field }

        var percentage: Double {
            guard limit > 0 else { return 0 }
            return Double(usage) / Double(limit)
        }
    }

    var quotaWarnings: [QuotaWarning] {
        guard let quota else { return [] }

        let pairs: [(String, Int, Int)] = [
            ("Instances", quota.instanceCountUsage, quota.instanceCountLimit),
            ("CPU Cores", quota.cpuCoreUsage, quota.cpuCoreLimit),
            ("RAM (MB)", quota.ramMbUsage, quota.ramMbLimit),
            ("Disk (GB)", quota.diskGbUsage, quota.diskGbLimit),
            ("Volumes", quota.diskVolumeCountUsage, quota.diskVolumeCountLimit),
            ("Snapshots", quota.diskSnapshotCountUsage, quota.diskSnapshotCountLimit),
            ("Public IPs", quota.publicIpAddressUsage, quota.publicIpAddressLimit),
            ("Networks", quota.networkCountUsage, quota.networkCountLimit),
            ("Security Groups", quota.securityGroupUsage, quota.securityGroupLimit),
            ("SG Rules", quota.securityGroupRuleUsage, quota.securityGroupRuleLimit),
            ("Subnets", quota.subnetCountUsage, quota.subnetCountLimit),
            ("Load Balancers", quota.loadbalancerCountUsage, quota.loadbalancerCountLimit),
            ("Object Store (GB)", quota.objectstoreGbUsage, quota.objectstoreGbLimit),
            ("Databases", quota.databaseCountUsage, quota.databaseCountLimit),
            ("DB CPU Cores", quota.databaseCpuCoreUsage, quota.databaseCpuCoreLimit),
            ("DB RAM (MB)", quota.databaseRamMbUsage, quota.databaseRamMbLimit),
            ("DB Disk (GB)", quota.databaseDiskGbUsage, quota.databaseDiskGbLimit),
            ("DB Snapshots", quota.databaseSnapshotCountUsage, quota.databaseSnapshotCountLimit),
        ]

        return pairs.compactMap { field, usage, limit in
            guard limit > 0 else { return nil }
            let pct = Double(usage) / Double(limit)
            if pct >= 0.9 {
                return QuotaWarning(field: field, usage: usage, limit: limit, level: .critical)
            } else if pct >= 0.8 {
                return QuotaWarning(field: field, usage: usage, limit: limit, level: .warning)
            }
            return nil
        }
    }

    /// Returns the warning level for a specific QuotaItem id, if any.
    func warningLevel(for itemId: String) -> QuotaWarningLevel? {
        guard let quota else { return nil }
        let usage: Int
        let limit: Int
        switch itemId {
        case "instances": usage = quota.instanceCountUsage; limit = quota.instanceCountLimit
        case "cpu": usage = quota.cpuCoreUsage; limit = quota.cpuCoreLimit
        case "ram": usage = quota.ramMbUsage; limit = quota.ramMbLimit
        case "disk": usage = quota.diskGbUsage; limit = quota.diskGbLimit
        case "volumes": usage = quota.diskVolumeCountUsage; limit = quota.diskVolumeCountLimit
        case "publicIps": usage = quota.publicIpAddressUsage; limit = quota.publicIpAddressLimit
        case "networks": usage = quota.networkCountUsage; limit = quota.networkCountLimit
        case "loadbalancers": usage = quota.loadbalancerCountUsage; limit = quota.loadbalancerCountLimit
        case "objectstore": usage = quota.objectstoreGbUsage; limit = quota.objectstoreGbLimit
        case "databases": usage = quota.databaseCountUsage; limit = quota.databaseCountLimit
        case "dbCpu": usage = quota.databaseCpuCoreUsage; limit = quota.databaseCpuCoreLimit
        case "dbRam": usage = quota.databaseRamMbUsage; limit = quota.databaseRamMbLimit
        case "dbDisk": usage = quota.databaseDiskGbUsage; limit = quota.databaseDiskGbLimit
        default: return nil
        }
        guard limit > 0 else { return nil }
        let pct = Double(usage) / Double(limit)
        if pct >= 0.9 { return .critical }
        if pct >= 0.8 { return .warning }
        return nil
    }

    func requestQuotaChange(_ body: sending [String: Any]) async -> Bool {
        isSavingQuota = true
        quotaSaveError = nil
        defer { isSavingQuota = false }

        do {
            try await quotaService.requestQuotaChange(body)
            return true
        } catch {
            quotaSaveError = CivoAPIError.userMessage(error)
            return false
        }
    }
}
