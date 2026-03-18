import Foundation
import Testing

// MARK: - Import all model types from the main target
@testable import CivoCloudManager

@Suite("API Response Decoding Tests")
struct APIDecodingTests {

    // MARK: - CivoQuota

    @Test("Decode quota response (single object)")
    func decodeQuota() throws {
        let json = """
        {"cpu_core_limit":"74","cpu_core_usage":"28","database_count_limit":"4","database_count_usage":"3","database_cpu_core_limit":"16","database_cpu_core_usage":"4","database_disk_gb_limit":"400","database_disk_gb_usage":"80","database_ram_mb_limit":"32768","database_ram_mb_usage":"8192","database_snapshot_count_limit":"20","database_snapshot_count_usage":"0","disk_gb_limit":"1600","disk_gb_usage":"700","disk_snapshot_count_limit":"48","disk_snapshot_count_usage":"0","disk_volume_count_limit":"128","disk_volume_count_usage":"11","instance_count_limit":"64","instance_count_usage":"9","loadbalancer_count_limit":"16","loadbalancer_count_usage":"1","network_count_limit":"10","network_count_usage":"1","objectstore_gb_limit":"5000","objectstore_gb_usage":"3000","public_ip_address_limit":"64","public_ip_address_usage":"5","ram_mb_limit":"262144","ram_mb_usage":"57344","security_group_limit":"16","security_group_rule_limit":"160","security_group_rule_usage":"0","security_group_usage":"0","subnet_count_limit":"10","subnet_count_usage":"0"}
        """
        let data = json.data(using: .utf8)!
        let quota = try JSONDecoder().decode(CivoQuota.self, from: data)
        #expect(quota.instanceCountLimit == "64")
        #expect(quota.instanceCountUsage == "9")
        #expect(quota.cpuCoreLimit == "74")
        #expect(quota.databaseCountUsage == "3")
        #expect(quota.items.count == 13)
        #expect(quota.items.first?.label == "Instances")
    }

    // MARK: - CivoKubernetesListItem (paginated)

    @Test("Decode kubernetes list response (paginated)")
    func decodeKubernetesList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"4874e5e5-62dc-44d2-888b-6a422f692b85","name":"k8s-cluster","version":"1.35.0-k3s1","status":"ACTIVE","ready":true,"cluster_type":"k3s","num_target_nodes":1,"target_nodes_size":"g4s.kube.medium","kubernetes_version":"1.35.0-k3s1","api_endpoint":"https://74.220.31.124:6443","master_ip":"74.220.31.124","dns_entry":"4874e5e5.k8s.civo.com","network_id":"7fa62450","firewall_id":"2a18a3ee","cni_plugin":"flannel","created_at":"2025-06-19T11:37:18Z"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoKubernetesCluster>.self, from: data)
        #expect(response.items.count == 1)
        let cluster = response.items[0]
        #expect(cluster.name == "k8s-cluster")
        #expect(cluster.status == "ACTIVE")
        #expect(cluster.clusterType == "k3s")
        #expect(cluster.kubernetesVersion == "1.35.0-k3s1")
        #expect(cluster.masterIp == "74.220.31.124")
        #expect(cluster.cniPlugin == "flannel")
    }

    // MARK: - CivoDatabase (paginated)

    @Test("Decode database list response (paginated)")
    func decodeDatabaseList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"67763af0","name":"dev-database","status":"Ready","software":"PostgreSQL","software_version":"14","size":"g3.db.xsmall","nodes":"1","port":"5432","host":"74.220.25.6","private_ipv4":"192.168.1.8","firewall_id":"62f22b50","network_id":"7fa62450","dns_entry":"67763af0.db.civo.com"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoDatabase>.self, from: data)
        #expect(response.items.count == 1)
        let db = response.items[0]
        #expect(db.name == "dev-database")
        #expect(db.status == "Ready")
        #expect(db.software == "PostgreSQL")
        #expect(db.softwareVersion == "14")
        #expect(db.port == "5432")
        #expect(db.portInt == 5432)
    }

    // MARK: - CivoFirewall (plain array)

    @Test("Decode firewall list response (rules_count as string)")
    func decodeFirewallListString() throws {
        let json = """
        [{"id":"2a18a3ee","name":"k8s-cluster-firewall","rules_count":"7"},{"id":"62f22b50","name":"db-firewall","rules_count":"3"}]
        """
        let data = json.data(using: .utf8)!
        let firewalls = try JSONDecoder().decode([CivoFirewall].self, from: data)
        #expect(firewalls.count == 2)
        #expect(firewalls[0].name == "k8s-cluster-firewall")
        #expect(firewalls[0].rulesCount == "7")
        #expect(firewalls[0].rulesCountInt == 7)
    }

    @Test("Decode firewall list response (rules_count as int)")
    func decodeFirewallListInt() throws {
        let json = """
        [{"id":"2a18a3ee","name":"k8s-cluster-firewall","rules_count":7}]
        """
        let data = json.data(using: .utf8)!
        let firewalls = try JSONDecoder().decode([CivoFirewall].self, from: data)
        #expect(firewalls[0].rulesCount == "7")
        #expect(firewalls[0].rulesCountInt == 7)
    }

    // MARK: - CivoRule (plain array)

    @Test("Decode firewall rule list response")
    func decodeRuleList() throws {
        let json = """
        [{"id":"rule1","label":"civo-cloud-test-fw","cidr":"1.2.3.4/32","ports":"6443","start_port":"6443","end_port":"6443","direction":"ingress","action":"allow"}]
        """
        let data = json.data(using: .utf8)!
        let rules = try JSONDecoder().decode([CivoRule].self, from: data)
        #expect(rules.count == 1)
        #expect(rules[0].label == "civo-cloud-test-fw")
        #expect(rules[0].cidr == "1.2.3.4/32")
    }

    // MARK: - CivoNetwork (plain array)

    @Test("Decode network list response (plain array)")
    func decodeNetworkList() throws {
        let json = """
        [{"id":"7fa62450","label":"default","region":"fra1","status":"Active","default":"true"}]
        """
        let data = json.data(using: .utf8)!
        let networks = try JSONDecoder().decode([CivoNetwork].self, from: data)
        #expect(networks.count == 1)
        #expect(networks[0].name == "default")
        #expect(networks[0].isDefault == "true")
    }

    // MARK: - CivoVolume (plain array)

    @Test("Decode volume list response (plain array)")
    func decodeVolumeList() throws {
        let json = """
        [{"id":"c0da7fd0","name":"pvc-test","status":"attached","size_gigabytes":"20 GB","mount_point":"sdb","instance_id":"inst1","cluster_id":"clust1","network_id":"default"}]
        """
        let data = json.data(using: .utf8)!
        let volumes = try JSONDecoder().decode([CivoVolume].self, from: data)
        #expect(volumes.count == 1)
        #expect(volumes[0].name == "pvc-test")
        #expect(volumes[0].sizeGigabytes == "20 GB")
        #expect(volumes[0].status == "attached")
    }

    // MARK: - CivoObjectStore (paginated)

    @Test("Decode object store list response (paginated)")
    func decodeObjectStoreList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"656648","name":"database-backups","max_size":"500","objectstore_endpoint":"objectstore.fra1.civo.com","status":"ready"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoObjectStore>.self, from: data)
        #expect(response.items.count == 1)
        #expect(response.items[0].name == "database-backups")
        #expect(response.items[0].maxSizeInt == 500)
    }

    // MARK: - CivoLoadBalancer (plain array)

    @Test("Decode load balancer list response (plain array)")
    func decodeLoadBalancerList() throws {
        let json = """
        [{"id":"0cf0cbc6","name":"k8s-ingress","algorithm":"round_robin","public_ip":"74.220.28.127","private_ip":"192.168.1.10","state":"available","cluster_id":"4874e5e5","firewall_id":"3219e15f","Backends":"192.168.1.9, 192.168.1.23","external_traffic_policy":"Local"}]
        """
        let data = json.data(using: .utf8)!
        let lbs = try JSONDecoder().decode([CivoLoadBalancer].self, from: data)
        #expect(lbs.count == 1)
        #expect(lbs[0].name == "k8s-ingress")
        #expect(lbs[0].algorithm == "round_robin")
        #expect(lbs[0].publicIp == "74.220.28.127")
        #expect(lbs[0].backendList.count == 2)
    }

    // MARK: - CivoRegion (plain array)

    @Test("Decode region list response (plain array)")
    func decodeRegionList() throws {
        let json = """
        [{"code":"fra1","name":"fra1","country":"Germany","current":"Yes"},{"code":"lon1","name":"lon1","country":"United Kingdom","current":"No"}]
        """
        let data = json.data(using: .utf8)!
        let regions = try JSONDecoder().decode([CivoRegion].self, from: data)
        #expect(regions.count == 2)
        #expect(regions[0].code == "fra1")
        #expect(regions[0].isCurrent == true)
        #expect(regions[1].isCurrent == false)
    }

    // MARK: - CivoInstance (paginated)

    @Test("Decode instance list response (paginated)")
    func decodeInstanceList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"b75f2659","hostname":"test-server","size":"g4s.kube.large","status":"ACTIVE","public_ip":"74.220.31.124","cpu_cores":4,"ram_mb":8192,"disk_gb":60,"firewall_id":"2a18a3ee","created_at":"2026-03-05T10:25:10Z","tags":["k3s"]}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoInstance>.self, from: data)
        #expect(response.items.count == 1)
        let inst = response.items[0]
        #expect(inst.name == "test-server")
        #expect(inst.status == "ACTIVE")
        #expect(inst.cpuCores == 4)
        #expect(inst.ramMb == 8192)
    }

    // MARK: - CivoSSHKey (plain array)

    @Test("Decode SSH key list response (plain array)")
    func decodeSSHKeyList() throws {
        let json = """
        [{"id":"ssh1","name":"my-key","fingerprint":"SHA256:abc123"}]
        """
        let data = json.data(using: .utf8)!
        let keys = try JSONDecoder().decode([CivoSSHKey].self, from: data)
        #expect(keys.count == 1)
        #expect(keys[0].name == "my-key")
        #expect(keys[0].fingerprint == "SHA256:abc123")
    }

    // MARK: - CivoDomain (plain array)

    @Test("Decode domain list response (plain array)")
    func decodeDomainList() throws {
        let json = """
        [{"id":"dom1","name":"example.com"}]
        """
        let data = json.data(using: .utf8)!
        let domains = try JSONDecoder().decode([CivoDomain].self, from: data)
        #expect(domains.count == 1)
        #expect(domains[0].name == "example.com")
    }

    // MARK: - CivoResult (DELETE response)

    @Test("Decode delete result response")
    func decodeDeleteResult() throws {
        let json = """
        {"result":"success"}
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(CivoResult.self, from: data)
        #expect(result.result == "success")
    }

    // MARK: - CivoK8sCondition

    @Test("Decode kubernetes conditions")
    func decodeK8sConditions() throws {
        let json = """
        [{"type":"ControlPlaneReady","status":"True","last_transition_time":"2025-08-31T16:20:33Z"},{"type":"WorkerNodesReady","status":"True","last_transition_time":"2026-03-12T14:55:30Z"}]
        """
        let data = json.data(using: .utf8)!
        let conditions = try JSONDecoder().decode([CivoK8sCondition].self, from: data)
        #expect(conditions.count == 2)
        #expect(conditions[0].isHealthy == true)
        #expect(conditions[0].type == "ControlPlaneReady")
    }

    // MARK: - CivoNodePool

    @Test("Decode node pools")
    func decodeNodePools() throws {
        let json = """
        [{"id":"dev-pool","count":1,"size":"g4s.kube.medium","instance_names":["node1"]}]
        """
        let data = json.data(using: .utf8)!
        let pools = try JSONDecoder().decode([CivoNodePool].self, from: data)
        #expect(pools.count == 1)
        #expect(pools[0].count == 1)
        #expect(pools[0].size == "g4s.kube.medium")
    }

    // MARK: - QuotaItem computed values

    @Test("QuotaItem percentage calculation")
    func quotaItemPercentage() {
        let item = QuotaItem(id: "test", label: "Test", usage: 7, limit: 10, icon: "cpu")
        #expect(item.percentage == 0.7)

        let zeroLimit = QuotaItem(id: "zero", label: "Zero", usage: 0, limit: 0, icon: "cpu")
        #expect(zeroLimit.percentage == 0)
    }

    // MARK: - CivoAccessLabel

    @Test("Access label generation")
    func accessLabelGeneration() {
        let label = CivoAccessLabel.make(firewallName: "test-fw")
        #expect(label.hasPrefix("civo-cloud-"))
        #expect(label.hasSuffix("-test-fw"))
    }

    // MARK: - LoadBalancer backends parsing

    @Test("Load balancer backend list parsing")
    func loadBalancerBackends() throws {
        let json = """
        [{"id":"lb1","name":"test-lb","Backends":"10.0.0.1, 10.0.0.2, 10.0.0.3"}]
        """
        let data = json.data(using: .utf8)!
        let lbs = try JSONDecoder().decode([CivoLoadBalancer].self, from: data)
        #expect(lbs[0].backendList == ["10.0.0.1", "10.0.0.2", "10.0.0.3"])
    }

    // MARK: - CivoRule CIDR string handling

    @Test("CivoRule decodes cidr as string")
    func civoRuleCidrString() throws {
        let json = """
        {"id":"r1","cidr":"10.0.0.0/8"}
        """
        let data = json.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CivoRule.self, from: data)
        #expect(rule.cidr == "10.0.0.0/8")
    }

    @Test("CivoRule decodes cidr as array")
    func civoRuleCidrArray() throws {
        let json = """
        {"id":"r2","cidr":["10.0.0.0/8","172.16.0.0/12"]}
        """
        let data = json.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CivoRule.self, from: data)
        #expect(rule.cidr == "10.0.0.0/8")
    }
}
