#if DEBUG
import Foundation

/// Fictional Civo API answers for demo mode, in the JSON shape the real models decode.
/// Addresses come from the documentation ranges 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24 or from 10.0.0.0/16.
enum DemoFixtures {
    static let region = "lon1"
    static let placeholderAPIKey = "demo-data-placeholder"
    static let documentationIP = "203.0.113.10"

    private static let networkID = id(1, 1)
    private static let privateNetworkID = id(1, 2)
    private static let webFirewallID = id(2, 1)
    private static let clusterID = id(3, 1)
    private static let startedAt = "2026-01-12T09:30:00Z"

    /// Stable, obviously fake identifiers: `kind` selects the resource type, `number` the resource.
    static func id(_ kind: Int, _ number: Int) -> String {
        String(format: "%08x-0000-4000-8000-%012x", kind, number)
    }

    static func page(_ items: [[String: Any]]) -> [String: Any] {
        ["page": 1, "per_page": max(items.count, 20), "pages": 1, "items": items]
    }

    // MARK: - Account

    static var quota: [String: Any] {
        [
            "instance_count_limit": "20", "instance_count_usage": "12",
            "cpu_core_limit": "64", "cpu_core_usage": "30",
            "ram_mb_limit": "262144", "ram_mb_usage": "114688",
            "disk_gb_limit": "2000", "disk_gb_usage": "1100",
            "disk_volume_count_limit": "20", "disk_volume_count_usage": "3",
            "disk_snapshot_count_limit": "30", "disk_snapshot_count_usage": "6",
            "public_ip_address_limit": "20", "public_ip_address_usage": "12",
            "network_count_limit": "10", "network_count_usage": "2",
            "security_group_limit": "15", "security_group_usage": "4",
            "security_group_rule_limit": "200", "security_group_rule_usage": "37",
            "subnet_count_limit": "10", "subnet_count_usage": "2",
            "loadbalancer_count_limit": "10", "loadbalancer_count_usage": "1",
            "objectstore_gb_limit": "5000", "objectstore_gb_usage": "1500",
            "database_count_limit": "10", "database_count_usage": "2",
            "database_cpu_core_limit": "32", "database_cpu_core_usage": "6",
            "database_ram_mb_limit": "131072", "database_ram_mb_usage": "24576",
            "database_disk_gb_limit": "1000", "database_disk_gb_usage": "160",
            "database_snapshot_count_limit": "20", "database_snapshot_count_usage": "4",
        ]
    }

    static var regions: [[String: Any]] {
        [
            ["code": "lon1", "name": "London", "country": "GBR", "country_name": "United Kingdom", "default": true],
            ["code": "fra1", "name": "Frankfurt", "country": "DEU", "country_name": "Germany", "default": false],
            ["code": "nyc1", "name": "New York", "country": "USA", "country_name": "United States", "default": false],
        ]
    }

    static var networks: [[String: Any]] {
        [
            ["id": networkID, "label": "demo-network", "region": region, "status": "Active", "default": true],
            ["id": privateNetworkID, "label": "internal-network", "region": region, "status": "Active", "default": false],
        ]
    }

    // MARK: - Compute

    private static let instanceSpecs: [(name: String, size: String, status: String, ip: String, tags: [String], firewall: Int)] = [
        ("web-01", "g3.medium", "ACTIVE", "203.0.113.11", ["web", "prod"], 1),
        ("web-02", "g3.medium", "ACTIVE", "203.0.113.12", ["web", "prod"], 1),
        ("web-03", "g3.small", "ACTIVE", "203.0.113.13", ["web", "staging"], 1),
        ("api-01", "g3.large", "ACTIVE", "203.0.113.21", ["api", "prod", "team-a"], 2),
        ("api-02", "g3.large", "ACTIVE", "203.0.113.22", ["api", "staging", "team-a"], 2),
        ("worker-01", "g3.small", "ACTIVE", "203.0.113.31", ["worker", "prod"], 2),
        ("worker-02", "g3.small", "SHUTOFF", "203.0.113.32", ["worker", "staging"], 2),
        ("db-01", "g3.xlarge", "ACTIVE", "203.0.113.41", ["database", "prod", "team-b"], 3),
        ("cache-01", "g3.small", "ACTIVE", "203.0.113.51", ["cache", "prod"], 2),
        ("batch-01", "g3.medium", "ACTIVE", "203.0.113.61", ["batch", "team-b"], 2),
        ("bastion-01", "g3.xsmall", "ACTIVE", "198.51.100.10", ["admin"], 3),
        ("monitor-01", "g3.small", "ACTIVE", "198.51.100.20", ["monitoring", "team-a"], 2),
    ]

    private static let sizeSpecs: [(name: String, cpu: Int, ramMB: Int, diskGB: Int, label: String)] = [
        ("g3.xsmall", 1, 1024, 25, "Extra Small"),
        ("g3.small", 1, 2048, 50, "Small"),
        ("g3.medium", 2, 4096, 80, "Medium"),
        ("g3.large", 4, 8192, 120, "Large"),
        ("g3.xlarge", 6, 16384, 160, "Extra Large"),
        ("g3.2xlarge", 8, 32768, 240, "2X Large"),
    ]

    static var instances: [[String: Any]] {
        instanceSpecs.enumerated().map { index, spec in
            let size = sizeSpecs.first { $0.name == spec.size }
            return [
                "id": id(4, index + 1), "hostname": spec.name, "size": spec.size, "status": spec.status,
                "public_ip": spec.ip, "private_ip": "10.0.0.\(index + 10)",
                "cpu_cores": size?.cpu ?? 1, "ram_mb": size?.ramMB ?? 1024, "disk_gb": size?.diskGB ?? 25,
                "firewall_id": id(2, spec.firewall), "network_id": networkID, "region": region,
                "created_at": startedAt, "tags": spec.tags,
            ]
        }
    }

    /// Every demo instance runs normally, so the detail shows recovery mode as off.
    static var recoveryStatus: [String: Any] { ["result": false] }

    static var sizes: [[String: Any]] {
        sizeSpecs.map { spec in
            [
                "name": spec.name, "nice_name": spec.label, "type": "Instance", "selectable": true,
                "description": spec.label, "cpu_cores": spec.cpu, "ram_mb": spec.ramMB, "disk_gb": spec.diskGB,
            ]
        }
    }

    // MARK: - Networking

    private static let firewallSpecs: [(name: String, rules: Int, isDefault: Bool)] = [
        ("web-frontend", 9, false), ("internal-only", 4, false), ("admin-access", 3, false), ("default", 2, true),
    ]

    static var firewalls: [[String: Any]] {
        firewallSpecs.enumerated().map { index, spec in
            [
                "id": id(2, index + 1), "name": spec.name, "rules_count": String(spec.rules),
                "network_id": networkID, "default": spec.isDefault,
            ]
        }
    }

    private static func rule(
        _ number: Int, _ label: String, _ proto: String, ports: (String, String), _ cidr: String,
        _ direction: String = "ingress"
    ) -> [String: Any] {
        [
            "id": id(5, number), "label": label, "protocol": proto, "cidr": [cidr],
            "ports": ports.0 == ports.1 ? ports.0 : "\(ports.0)-\(ports.1)",
            "start_port": ports.0, "end_port": ports.1, "direction": direction, "action": "allow",
        ]
    }

    static func rules(forFirewall firewallID: String) -> [[String: Any]] {
        guard firewallID == webFirewallID else {
            return [
                rule(21, "Internal HTTPS", "tcp", ports: ("443", "443"), "10.0.0.0/16"),
                rule(22, "All outbound", "tcp", ports: ("1", "65535"), "0.0.0.0/0", "egress"),
            ]
        }
        return [
            rule(1, "HTTPS", "tcp", ports: ("443", "443"), "0.0.0.0/0"),
            rule(2, "HTTP", "tcp", ports: ("80", "80"), "0.0.0.0/0"),
            rule(3, "SSH office", "tcp", ports: ("22", "22"), "198.51.100.0/24"),
            rule(4, "Admin console", "tcp", ports: ("8443", "8443"), "203.0.113.0/24"),
            rule(5, "Metrics", "tcp", ports: ("9100", "9100"), "192.0.2.0/24"),
            rule(6, "Cluster API", "tcp", ports: ("6443", "6443"), "192.0.2.0/24"),
            rule(7, "Service ports", "tcp", ports: ("30000", "32767"), "10.0.0.0/16"),
            rule(8, "All outbound", "tcp", ports: ("1", "65535"), "0.0.0.0/0", "egress"),
            rule(9, "DNS outbound", "udp", ports: ("53", "53"), "0.0.0.0/0", "egress"),
        ]
    }

    static var reservedIPs: [[String: Any]] {
        let assignments: [(name: String, ip: String, target: (id: String, name: String)?)] = [
            ("ip-web", "203.0.113.101", (id(4, 1), "web-01")),
            ("ip-api", "203.0.113.102", (id(4, 4), "api-01")),
            ("ip-bastion", "203.0.113.103", (id(4, 11), "bastion-01")),
            ("ip-spare-a", "203.0.113.104", nil),
            ("ip-spare-b", "203.0.113.105", nil),
        ]
        return assignments.enumerated().map { index, entry in
            let assignedTo: [String: Any] = entry.target.map { ["type": "instance", "id": $0.id, "name": $0.name] } ?? [:]
            return ["id": id(6, index + 1), "name": entry.name, "ip": entry.ip, "assigned_to": assignedTo]
        }
    }

    // MARK: - Kubernetes

    static let currentKubernetesVersion = "1.29.6-k3s1"

    static var clusters: [[String: Any]] {
        [
            cluster(clusterID, name: "demo-cluster", upgradeTo: "1.31.2-k3s1", nodes: 3),
            cluster(id(3, 2), name: "staging-cluster", upgradeTo: nil, nodes: 2),
        ]
    }

    static func cluster(_ clusterID: String, name: String, upgradeTo: String?, nodes: Int) -> [String: Any] {
        var cluster: [String: Any] = [
            "id": clusterID, "name": name, "status": "ACTIVE", "ready": true,
            "version": currentKubernetesVersion, "kubernetes_version": currentKubernetesVersion,
            "cluster_type": "k3s", "num_target_nodes": nodes, "target_nodes_size": "g4s.kube.medium",
            "network_id": networkID, "firewall_id": id(2, 4), "cni_plugin": "flannel",
            "built_at": startedAt, "created_at": startedAt,
            "pools": [[
                "id": id(7, clusterID == DemoFixtures.clusterID ? 1 : 2), "count": nodes, "size": "g4s.kube.medium",
                "instance_names": (1...nodes).map { "\(name)-pool-node-\($0)" },
            ]],
            "installed_applications": [],
            "conditions": [["type": "ClusterVersionSync", "status": "True"]],
        ]
        if let upgradeTo { cluster["upgrade_available_to"] = upgradeTo }
        return cluster
    }

    static func cluster(withID clusterID: String) -> [String: Any]? {
        clusters.first { $0["id"] as? String == clusterID }
    }

    static var kubernetesVersions: [[String: Any]] {
        [
            ["version": "1.31.2+k3s1", "label": "v1.31.2+k3s1", "type": "stable", "default": true, "clusterType": "k3s"],
            ["version": "1.30.6+k3s1", "label": "v1.30.6+k3s1", "type": "stable", "default": false, "clusterType": "k3s"],
            ["version": "1.30.4+k3s1", "label": "v1.30.4+k3s1", "type": "stable", "default": false, "clusterType": "k3s"],
            ["version": "1.29.6+k3s1", "label": "v1.29.6+k3s1", "type": "stable", "default": false, "clusterType": "k3s"],
            ["version": "1.28.9+k3s1", "label": "v1.28.9+k3s1", "type": "deprecated", "default": false, "clusterType": "k3s"],
        ]
    }

    // MARK: - Other resources

    static var databases: [[String: Any]] {
        [
            ["id": id(8, 1), "name": "demo-postgres", "status": "Ready", "software": "PostgreSQL",
             "software_version": "16", "size": "g3.db.small", "nodes": 1, "port": 5432,
             "private_ipv4": "10.0.1.10", "network_id": networkID, "region": region, "created_at": startedAt],
            ["id": id(8, 2), "name": "demo-mysql", "status": "Ready", "software": "MySQL",
             "software_version": "8", "size": "g3.db.medium", "nodes": 1, "port": 3306,
             "private_ipv4": "10.0.1.11", "network_id": networkID, "region": region, "created_at": startedAt],
        ]
    }

    static var volumes: [[String: Any]] {
        (1...3).map { number in
            ["id": id(9, number), "name": "data-volume-\(number)", "status": "available", "size_gb": 100 * number,
             "network_id": networkID, "region": region, "created_at": startedAt, "bootable": false]
        }
    }

    static var objectStores: [[String: Any]] {
        [
            ["id": id(10, 1), "name": "assets-demo", "max_size": 500, "status": "ready"],
            ["id": id(10, 2), "name": "backups-demo", "max_size": 1000, "status": "ready"],
        ]
    }

    static var loadBalancers: [[String: Any]] {
        [["id": id(11, 1), "name": "demo-lb", "algorithm": "round_robin", "state": "available",
          "public_ip": "203.0.113.200", "private_ip": "10.0.0.200", "network_id": networkID,
          "created_at": startedAt, "backends": []]]
    }

    // MARK: - Charges

    private static let chargeSpecs: [(code: String, label: String, nodes: Int?, sizeGB: Double?)] = [
        ("instance-g3.medium", "web-01", nil, nil),
        ("instance-g3.medium", "web-02", nil, nil),
        ("instance-g3.large", "api-01", nil, nil),
        ("instance-g3.xlarge", "db-01", nil, nil),
        ("kube-node-g4s.kube.medium", "demo-cluster", 3, nil),
        ("database-g3.db.small", "demo-postgres", nil, nil),
        ("volume", "data-volume-2", nil, 200),
        ("objectstore", "assets-demo", nil, 500),
        ("loadbalancer", "demo-lb", nil, nil),
    ]

    /// Running resources for the half-open window, billed up to `now`, so any requested month has plausible rows.
    static func charges(from: Date, to: Date, now: Date) -> [[String: Any]] {
        let end = min(to, now)
        guard end > from else { return [] }
        let formatter = ISO8601DateFormatter()
        let hours = (end.timeIntervalSince(from) / 3600).rounded()
        let month = Int(from.timeIntervalSinceReferenceDate / 86_400 / 28)
        return chargeSpecs.enumerated().map { index, spec in
            var charge: [String: Any] = [
                "id": month * 100 + index + 1, "code": spec.code, "label": spec.label,
                "from": formatter.string(from: from), "to": formatter.string(from: end),
                "num_hours": hours, "region": region,
            ]
            if let nodes = spec.nodes { charge["nodes"] = nodes }
            if let sizeGB = spec.sizeGB { charge["size_gb"] = sizeGB }
            return charge
        }
    }
}
#endif
