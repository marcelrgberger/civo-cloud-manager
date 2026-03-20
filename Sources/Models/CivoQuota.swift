import Foundation

struct CivoQuota: Codable, Sendable {
    let instanceCountLimit: Int
    let instanceCountUsage: Int
    let cpuCoreLimit: Int
    let cpuCoreUsage: Int
    let ramMbLimit: Int
    let ramMbUsage: Int
    let diskGbLimit: Int
    let diskGbUsage: Int
    let diskVolumeCountLimit: Int
    let diskVolumeCountUsage: Int
    let diskSnapshotCountLimit: Int
    let diskSnapshotCountUsage: Int
    let publicIpAddressLimit: Int
    let publicIpAddressUsage: Int
    let networkCountLimit: Int
    let networkCountUsage: Int
    let securityGroupLimit: Int
    let securityGroupUsage: Int
    let securityGroupRuleLimit: Int
    let securityGroupRuleUsage: Int
    let subnetCountLimit: Int
    let subnetCountUsage: Int
    let loadbalancerCountLimit: Int
    let loadbalancerCountUsage: Int
    let objectstoreGbLimit: Int
    let objectstoreGbUsage: Int
    let databaseCountLimit: Int
    let databaseCountUsage: Int
    let databaseCpuCoreLimit: Int
    let databaseCpuCoreUsage: Int
    let databaseRamMbLimit: Int
    let databaseRamMbUsage: Int
    let databaseDiskGbLimit: Int
    let databaseDiskGbUsage: Int
    let databaseSnapshotCountLimit: Int
    let databaseSnapshotCountUsage: Int

    enum CodingKeys: String, CodingKey {
        case instanceCountLimit = "instance_count_limit"
        case instanceCountUsage = "instance_count_usage"
        case cpuCoreLimit = "cpu_core_limit"
        case cpuCoreUsage = "cpu_core_usage"
        case ramMbLimit = "ram_mb_limit"
        case ramMbUsage = "ram_mb_usage"
        case diskGbLimit = "disk_gb_limit"
        case diskGbUsage = "disk_gb_usage"
        case diskVolumeCountLimit = "disk_volume_count_limit"
        case diskVolumeCountUsage = "disk_volume_count_usage"
        case diskSnapshotCountLimit = "disk_snapshot_count_limit"
        case diskSnapshotCountUsage = "disk_snapshot_count_usage"
        case publicIpAddressLimit = "public_ip_address_limit"
        case publicIpAddressUsage = "public_ip_address_usage"
        case networkCountLimit = "network_count_limit"
        case networkCountUsage = "network_count_usage"
        case securityGroupLimit = "security_group_limit"
        case securityGroupUsage = "security_group_usage"
        case securityGroupRuleLimit = "security_group_rule_limit"
        case securityGroupRuleUsage = "security_group_rule_usage"
        case subnetCountLimit = "subnet_count_limit"
        case subnetCountUsage = "subnet_count_usage"
        case loadbalancerCountLimit = "loadbalancer_count_limit"
        case loadbalancerCountUsage = "loadbalancer_count_usage"
        case objectstoreGbLimit = "objectstore_gb_limit"
        case objectstoreGbUsage = "objectstore_gb_usage"
        case databaseCountLimit = "database_count_limit"
        case databaseCountUsage = "database_count_usage"
        case databaseCpuCoreLimit = "database_cpu_core_limit"
        case databaseCpuCoreUsage = "database_cpu_core_usage"
        case databaseRamMbLimit = "database_ram_mb_limit"
        case databaseRamMbUsage = "database_ram_mb_usage"
        case databaseDiskGbLimit = "database_disk_gb_limit"
        case databaseDiskGbUsage = "database_disk_gb_usage"
        case databaseSnapshotCountLimit = "database_snapshot_count_limit"
        case databaseSnapshotCountUsage = "database_snapshot_count_usage"
    }
}

struct QuotaItem: Identifiable, Sendable {
    let id: String
    let label: String
    let usage: Int
    let limit: Int
    let icon: String

    var percentage: Double {
        guard limit > 0 else { return 0 }
        return Double(usage) / Double(limit)
    }
}

extension CivoQuota {
    var items: [QuotaItem] {
        [
            QuotaItem(id: "instances", label: "Instances", usage: instanceCountUsage, limit: instanceCountLimit, icon: "desktopcomputer"),
            QuotaItem(id: "cpu", label: "CPU Cores", usage: cpuCoreUsage, limit: cpuCoreLimit, icon: "cpu"),
            QuotaItem(id: "ram", label: "RAM (GB)", usage: ramMbUsage / 1024, limit: ramMbLimit / 1024, icon: "memorychip"),
            QuotaItem(id: "disk", label: "Disk (GB)", usage: diskGbUsage, limit: diskGbLimit, icon: "externaldrive"),
            QuotaItem(id: "volumes", label: "Volumes", usage: diskVolumeCountUsage, limit: diskVolumeCountLimit, icon: "cylinder"),
            QuotaItem(id: "publicIps", label: "Public IPs", usage: publicIpAddressUsage, limit: publicIpAddressLimit, icon: "network"),
            QuotaItem(id: "networks", label: "Networks", usage: networkCountUsage, limit: networkCountLimit, icon: "point.3.connected.trianglepath.dotted"),
            QuotaItem(id: "loadbalancers", label: "Load Balancers", usage: loadbalancerCountUsage, limit: loadbalancerCountLimit, icon: "arrow.triangle.branch"),
            QuotaItem(id: "objectstore", label: "Object Store (GB)", usage: objectstoreGbUsage, limit: objectstoreGbLimit, icon: "tray.2"),
            QuotaItem(id: "databases", label: "Databases", usage: databaseCountUsage, limit: databaseCountLimit, icon: "cylinder.split.1x2"),
            QuotaItem(id: "dbCpu", label: "DB CPU Cores", usage: databaseCpuCoreUsage, limit: databaseCpuCoreLimit, icon: "cpu"),
            QuotaItem(id: "dbRam", label: "DB RAM (GB)", usage: databaseRamMbUsage / 1024, limit: databaseRamMbLimit / 1024, icon: "memorychip"),
            QuotaItem(id: "dbDisk", label: "DB Disk (GB)", usage: databaseDiskGbUsage, limit: databaseDiskGbLimit, icon: "externaldrive"),
        ]
    }
}
