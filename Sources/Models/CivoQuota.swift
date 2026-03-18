import Foundation

struct CivoQuota: Codable, Sendable {
    let instanceCountLimit: String
    let instanceCountUsage: String
    let cpuCoreLimit: String
    let cpuCoreUsage: String
    let ramMbLimit: String
    let ramMbUsage: String
    let diskGbLimit: String
    let diskGbUsage: String
    let diskVolumeCountLimit: String
    let diskVolumeCountUsage: String
    let diskSnapshotCountLimit: String
    let diskSnapshotCountUsage: String
    let publicIpAddressLimit: String
    let publicIpAddressUsage: String
    let networkCountLimit: String
    let networkCountUsage: String
    let securityGroupLimit: String
    let securityGroupUsage: String
    let securityGroupRuleLimit: String
    let securityGroupRuleUsage: String
    let subnetCountLimit: String
    let subnetCountUsage: String
    let loadbalancerCountLimit: String
    let loadbalancerCountUsage: String
    let objectstoreGbLimit: String
    let objectstoreGbUsage: String
    let databaseCountLimit: String
    let databaseCountUsage: String
    let databaseCpuCoreLimit: String
    let databaseCpuCoreUsage: String
    let databaseRamMbLimit: String
    let databaseRamMbUsage: String
    let databaseDiskGbLimit: String
    let databaseDiskGbUsage: String
    let databaseSnapshotCountLimit: String
    let databaseSnapshotCountUsage: String

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
            QuotaItem(id: "instances", label: "Instances", usage: Int(instanceCountUsage) ?? 0, limit: Int(instanceCountLimit) ?? 0, icon: "desktopcomputer"),
            QuotaItem(id: "cpu", label: "CPU Cores", usage: Int(cpuCoreUsage) ?? 0, limit: Int(cpuCoreLimit) ?? 0, icon: "cpu"),
            QuotaItem(id: "ram", label: "RAM (MB)", usage: Int(ramMbUsage) ?? 0, limit: Int(ramMbLimit) ?? 0, icon: "memorychip"),
            QuotaItem(id: "disk", label: "Disk (GB)", usage: Int(diskGbUsage) ?? 0, limit: Int(diskGbLimit) ?? 0, icon: "externaldrive"),
            QuotaItem(id: "volumes", label: "Volumes", usage: Int(diskVolumeCountUsage) ?? 0, limit: Int(diskVolumeCountLimit) ?? 0, icon: "cylinder"),
            QuotaItem(id: "publicIps", label: "Public IPs", usage: Int(publicIpAddressUsage) ?? 0, limit: Int(publicIpAddressLimit) ?? 0, icon: "network"),
            QuotaItem(id: "networks", label: "Networks", usage: Int(networkCountUsage) ?? 0, limit: Int(networkCountLimit) ?? 0, icon: "point.3.connected.trianglepath.dotted"),
            QuotaItem(id: "loadbalancers", label: "Load Balancers", usage: Int(loadbalancerCountUsage) ?? 0, limit: Int(loadbalancerCountLimit) ?? 0, icon: "arrow.triangle.branch"),
            QuotaItem(id: "objectstore", label: "Object Store (GB)", usage: Int(objectstoreGbUsage) ?? 0, limit: Int(objectstoreGbLimit) ?? 0, icon: "tray.2"),
            QuotaItem(id: "databases", label: "Databases", usage: Int(databaseCountUsage) ?? 0, limit: Int(databaseCountLimit) ?? 0, icon: "cylinder.split.1x2"),
            QuotaItem(id: "dbCpu", label: "DB CPU Cores", usage: Int(databaseCpuCoreUsage) ?? 0, limit: Int(databaseCpuCoreLimit) ?? 0, icon: "cpu"),
            QuotaItem(id: "dbRam", label: "DB RAM (MB)", usage: Int(databaseRamMbUsage) ?? 0, limit: Int(databaseRamMbLimit) ?? 0, icon: "memorychip"),
            QuotaItem(id: "dbDisk", label: "DB Disk (GB)", usage: Int(databaseDiskGbUsage) ?? 0, limit: Int(databaseDiskGbLimit) ?? 0, icon: "externaldrive"),
        ]
    }
}
