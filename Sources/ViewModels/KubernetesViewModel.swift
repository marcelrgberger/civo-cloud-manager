import Foundation

@Observable
@MainActor
final class KubernetesViewModel {
    var clusters: [CivoKubernetesCluster] = []
    var selectedCluster: CivoKubernetesCluster?
    var isLoading = false
    var error: String?

    var isCreating = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []
    var availableSizes: [CivoSize] = []

    // K8s API state
    var k8sNodes: [K8sNode] = []
    var selectedNode: K8sNode?
    var nodePods: [K8sPod] = []
    var podLog: String?
    var selectedPod: K8sPod?
    var isLoadingK8s = false
    var k8sError: String?
    var isK8sConnected = false

    // Metrics + Events + Workloads + Networking + Storage
    var clusterMetrics: K8sClusterMetrics?
    var nodeMetrics: [K8sNodeMetrics] = []
    var events: [K8sEvent] = []
    var deployments: [K8sDeployment] = []
    var daemonSets: [K8sDaemonSet] = []
    var statefulSets: [K8sStatefulSet] = []
    var cronJobs: [K8sCronJob] = []
    var services: [K8sService] = []
    var ingresses: [K8sIngress] = []
    var namespaces: [K8sNamespace] = []
    var pvcs: [K8sPVC] = []
    var pvs: [K8sPV] = []
    var metricsAvailable = true

    // Auto-firewall state
    private var autoCreatedRuleId: String?
    private var autoFirewallId: String?

    private let service = CivoKubernetesService()
    private let networkService = CivoNetworkService()
    private let sizeService = CivoSizeService()
    private let firewallService = CivoFirewallService()
    private let ipDetector = IPDetector()
    private var k8sClient: KubernetesAPIClient?

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            clusters = try await service.listClusters()
        } catch {
            self.error = error.localizedDescription
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
            return
        }

        // Auto-connect to K8s API in background
        if selectedCluster?.status.lowercased() == "active" {
            Task { await connectToCluster(id) }
        }
    }

    // MARK: - K8s API (via kubeconfig + auto-firewall)

    func connectToCluster(_ clusterId: String) async {
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        var steps: [String] = []
        do {
            // Step 1: Auto-open firewall
            if let cluster = selectedCluster, let fwId = cluster.firewallId {
                await autoOpenFirewall(firewallId: fwId, port: 6443)
                steps.append("Firewall opened")
            } else {
                steps.append("No firewall ID")
            }

            // Step 2: Get kubeconfig
            let yaml = try await service.getKubeconfig(clusterId)
            steps.append("Kubeconfig: \(yaml.count) chars")

            // Step 3: Parse kubeconfig
            let creds = try KubeconfigParser.parse(yaml)
            steps.append("Parsed: server=\(creds.server), CA=\(creds.caCertPEM.count)b, cert=\(creds.clientCertPEM.count)b, key=\(creds.clientKeyPEM.count)b")

            // Step 4: Create client
            let client = try KubernetesAPIClient(credentials: creds)
            steps.append("Client created")
            k8sClient = client

            // Step 5: Test connection
            let nodeList = try await client.listNodes()
            k8sNodes = nodeList.items
            isK8sConnected = true
            steps.append("Connected: \(k8sNodes.count) nodes")

            await loadClusterData()
        } catch {
            steps.append("FAILED: \(error.localizedDescription)")
            k8sError = steps.joined(separator: " → ")
            await autoCloseFirewall()
        }
    }

    func disconnectFromCluster() async {
        k8sClient = nil
        isK8sConnected = false
        k8sNodes = []
        selectedNode = nil
        nodePods = []
        podLog = nil
        selectedPod = nil
        clusterMetrics = nil
        nodeMetrics = []
        events = []
        deployments = []
        daemonSets = []
        statefulSets = []
        cronJobs = []
        services = []
        ingresses = []
        namespaces = []
        pvcs = []
        pvs = []

        await autoCloseFirewall()
    }

    private func autoOpenFirewall(firewallId: String, port: Int) async {
        do {
            let ip = try await ipDetector.detectIP()
            let label = "\(CivoAccessLabel.prefix)\(CivoAccessLabel.hostname)-k8s-api"
            let cidr = "\(ip)/32"

            let rules = try await firewallService.getRulesForFirewall(firewallId)
            let existing = rules.first {
                $0.cidr == cidr && ($0.startPort == "\(port)" || $0.ports == "\(port)")
            }

            if existing == nil {
                try await firewallService.createRule(
                    firewallId: firewallId,
                    startPort: String(port),
                    cidr: cidr,
                    label: label
                )
                let updatedRules = try await firewallService.getRulesForFirewall(firewallId)
                autoCreatedRuleId = updatedRules.first { $0.label == label && $0.cidr == cidr }?.id
                autoFirewallId = firewallId
                Log.info("Auto-opened firewall for K8s API port \(port)")
            }
        } catch {
            Log.error("Auto-open firewall failed: \(error.localizedDescription)")
        }
    }

    private func autoCloseFirewall() async {
        guard let ruleId = autoCreatedRuleId, let fwId = autoFirewallId else { return }
        do {
            try await firewallService.deleteRule(firewallId: fwId, ruleId: ruleId)
            Log.info("Auto-closed K8s API firewall rule")
        } catch {
            Log.error("Auto-close firewall failed: \(error.localizedDescription)")
        }
        autoCreatedRuleId = nil
        autoFirewallId = nil
    }

    func loadClusterData() async {
        guard let client = k8sClient else { return }

        await loadNodes()

        // Load everything concurrently
        async let m: () = loadMetrics(client)
        async let e: () = loadEvents(client)
        async let w: () = loadWorkloads(client)
        async let n: () = loadNetworking(client)
        async let s: () = loadStorage(client)
        _ = await (m, e, w, n, s)
    }

    func loadNodes() async {
        guard let client = k8sClient else { return }
        do {
            k8sNodes = try await client.listNodes().items
        } catch {
            Log.error("Load nodes failed: \(error.localizedDescription)")
        }
    }

    private func loadMetrics(_ client: KubernetesAPIClient) async {
        do {
            let metrics = try await client.getNodeMetrics()
            nodeMetrics = metrics.items

            var cpuUsage = 0.0, cpuCap = 0.0, memUsage = 0.0, memCap = 0.0
            var podCap = 0

            for node in k8sNodes {
                if let cap = node.status?.capacity {
                    cpuCap += K8sMetricsParser.parseCPU(cap.cpu ?? "0")
                    memCap += K8sMetricsParser.parseMemoryMB(cap.memory ?? "0")
                    podCap += Int(cap.pods ?? "0") ?? 0
                }
            }

            for m in metrics.items {
                cpuUsage += K8sMetricsParser.parseCPU(m.usage?.cpu ?? "0")
                memUsage += K8sMetricsParser.parseMemoryMB(m.usage?.memory ?? "0")
            }

            // Count all running pods
            var podCount = 0
            do {
                let allPods = try await client.listPods()
                podCount = allPods.items.filter { $0.status?.phase == "Running" }.count
            } catch { /* pod count remains 0 */ }

            let healthyNodes = k8sNodes.filter {
                $0.status?.conditions?.first(where: { $0.type == "Ready" })?.status == "True"
            }.count

            clusterMetrics = K8sClusterMetrics(
                cpuUsage: cpuUsage, cpuCapacity: cpuCap,
                memoryUsageMB: memUsage, memoryCapacityMB: memCap,
                podCount: podCount, podCapacity: podCap,
                nodeCount: k8sNodes.count, healthyNodes: healthyNodes
            )
            metricsAvailable = true
        } catch {
            metricsAvailable = false
            Log.info("Metrics-server not available")
        }
    }

    private func loadEvents(_ client: KubernetesAPIClient) async {
        do {
            let list = try await client.listEvents(limit: 30)
            events = list.items.sorted { ($0.lastTimestamp ?? "") > ($1.lastTimestamp ?? "") }
        } catch {
            Log.error("Load events failed: \(error.localizedDescription)")
        }
    }

    private func loadWorkloads(_ client: KubernetesAPIClient) async {
        do { deployments = try await client.listDeployments().items }
        catch { Log.error("Deployments: \(error.localizedDescription)") }
        do { daemonSets = try await client.listDaemonSets().items }
        catch { Log.error("DaemonSets: \(error.localizedDescription)") }
        do { statefulSets = try await client.listStatefulSets().items }
        catch { Log.error("StatefulSets: \(error.localizedDescription)") }
        do { cronJobs = try await client.listCronJobs().items }
        catch { Log.error("CronJobs: \(error.localizedDescription)") }
    }

    private func loadNetworking(_ client: KubernetesAPIClient) async {
        do { services = try await client.listServices().items }
        catch { Log.error("Services: \(error.localizedDescription)") }
        do { ingresses = try await client.listIngresses().items }
        catch { Log.error("Ingresses: \(error.localizedDescription)") }
        do { namespaces = try await client.listNamespaces().items }
        catch { Log.error("Namespaces: \(error.localizedDescription)") }
    }

    private func loadStorage(_ client: KubernetesAPIClient) async {
        do { pvcs = try await client.listPVCs().items }
        catch { Log.error("PVCs: \(error.localizedDescription)") }
        do { pvs = try await client.listPVs().items }
        catch { Log.error("PVs: \(error.localizedDescription)") }
    }

    func civoVolumeIdForPVC(_ pvc: K8sPVC) -> String? {
        guard let pvName = pvc.volumeName else { return nil }
        return pvs.first(where: { $0.name == pvName })?.civoVolumeId
    }

    func loadPods(nodeName: String) async {
        guard let client = k8sClient else { return }
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        do {
            nodePods = try await client.listPods(nodeName: nodeName).items
        } catch {
            k8sError = error.localizedDescription
        }
    }

    func loadPodLog(namespace: String, pod: String) async {
        guard let client = k8sClient else { return }
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        do {
            podLog = try await client.getPodLogs(namespace: namespace, pod: pod)
        } catch {
            k8sError = error.localizedDescription
        }
    }

    func saveKubeconfig(_ clusterId: String) async -> String? {
        do { return try await service.getKubeconfig(clusterId) }
        catch { self.error = error.localizedDescription; return nil }
    }

    // MARK: - CRUD

    func createCluster(_ body: sending [String: Any]) async -> Bool {
        isSaving = true; saveError = nil; defer { isSaving = false }
        do {
            _ = try await service.createCluster(body)
            isCreating = false; showSuccess = true; await refresh(); return true
        } catch { saveError = error.localizedDescription; return false }
    }

    func updateCluster(_ id: String, body: sending [String: Any]) async -> Bool {
        isSaving = true; saveError = nil; defer { isSaving = false }
        do {
            _ = try await service.updateCluster(id, body: body)
            showSuccess = true; await refresh(); return true
        } catch { saveError = error.localizedDescription; return false }
    }

    func removeCluster(_ id: String) async -> Bool {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            try await service.removeCluster(id)
            await refresh(); return true
        } catch { self.error = error.localizedDescription; return false }
    }
}
