import Foundation

@Observable
@MainActor
final class KubernetesViewModel {
    var clusters: [CivoKubernetesCluster] = []
    var selectedCluster: CivoKubernetesCluster?
    var isLoading = false
    var error: String?

    // Create/Edit state
    var isCreating = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    // Form picker data
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

    private let service = CivoKubernetesService()
    private let networkService = CivoNetworkService()
    private let sizeService = CivoSizeService()
    private var k8sClient: KubernetesAPIClient?

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            clusters = try await service.listClusters()
        } catch {
            self.error = error.localizedDescription
            Log.error("Kubernetes list failed: \(error.localizedDescription)")
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
            Log.error("Kubernetes show failed: \(error.localizedDescription)")
        }
    }

    // MARK: - K8s API (via kubeconfig)

    func connectToCluster(_ clusterId: String) async {
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        do {
            let yaml = try await service.getKubeconfig(clusterId)
            let creds = try KubeconfigParser.parse(yaml)
            k8sClient = try KubernetesAPIClient(credentials: creds)
            Log.info("Connected to K8s API at \(creds.server)")
        } catch {
            k8sError = error.localizedDescription
            Log.error("K8s connect failed: \(error.localizedDescription)")
        }
    }

    func loadNodes() async {
        guard let client = k8sClient else {
            k8sError = "Not connected to cluster"
            return
        }
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        do {
            let list = try await client.listNodes()
            k8sNodes = list.items
        } catch {
            k8sError = error.localizedDescription
        }
    }

    func loadPods(nodeName: String) async {
        guard let client = k8sClient else { return }
        isLoadingK8s = true
        k8sError = nil
        defer { isLoadingK8s = false }

        do {
            let list = try await client.listPods(nodeName: nodeName)
            nodePods = list.items
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
        do {
            return try await service.getKubeconfig(clusterId)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - CRUD

    func createCluster(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.createCluster(body)
            isCreating = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func updateCluster(_ id: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.updateCluster(id, body: body)
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func removeCluster(_ id: String) async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await service.removeCluster(id)
            await refresh()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
