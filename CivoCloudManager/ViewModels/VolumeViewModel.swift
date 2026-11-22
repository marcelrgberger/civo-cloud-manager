import Foundation

@Observable
@MainActor
final class VolumeViewModel {
    var volumes: [CivoVolume] = []
    var objectStores: [CivoObjectStore] = []
    var isLoading = false
    var error: String?

    var selectedVolume: CivoVolume?
    var selectedObjectStore: CivoObjectStore?
    var browsingObjectStore: CivoObjectStore?
    var isCreatingVolume = false
    var isCreatingObjectStore = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var instances: [CivoInstance] = []
    private(set) var objectStoreCompleteness = ListCompleteness()
    var availableNetworks: [CivoNetwork] = []
    var credentials: [CivoObjectStoreCredential] = []
    private(set) var credentialCompleteness = ListCompleteness()
    var isCreatingCredential = false

    // Pause/Resume
    var pausedStores: [PausedObjectStore] = []
    var isPausing = false
    var isResuming = false
    var pauseProgress: PauseProgress?
    var pauseError: String?
    var vaultEnabled = false
    var pausingTask: Task<Void, Never>?

    private let volumeService = CivoVolumeService()
    private let instanceService = CivoInstanceService()
    private let objectStoreService = CivoObjectStoreService()
    private let networkService = CivoNetworkService()
    private let pauseService: any ObjectStorePauseAPI

    let operationGate = StorageOperationGate()
    private(set) var loadContext: StorageLoadContext?
    private(set) var selectedObjectStoreContext: StorageLoadContext?
    private(set) var credentialStateID = UUID()
    private var listGeneration = 0
    private var detailGeneration = 0
    private var refreshGeneration = 0
    private let credentialAPI: any ObjectStoreCredentialAPI
    private let settingsRegion: () -> String
    private let apiKey: () -> String
    private let isAccessAllowed: () -> Bool
    private let notificationCenter: NotificationCenter
    private let recordCredentialActivity: (ObjectStoreCredentialTarget) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []
    @ObservationIgnored lazy var credentialSwitcher = ObjectStoreCredentialSwitcher(vm: self, api: credentialAPI, recordActivity: recordCredentialActivity)

    struct PendingAssignment {
        let target: ObjectStoreCredentialTarget
        let requestedAccessKey: String
    }
    // In memory only. A Settings round trip must not erase an unresolved request.
    private var pendingAssignments: [PendingAssignment] = []

    init(
        credentialAPI: any ObjectStoreCredentialAPI = CivoObjectStoreService(),
        pauseService: any ObjectStorePauseAPI = ObjectStorePauseService(),
        settingsRegion: @escaping () -> String = { CivoConfig.shared.region },
        apiKey: @escaping () -> String = { CivoConfig.shared.apiKey },
        isAccessAllowed: @escaping () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        notificationCenter: NotificationCenter = .default,
        recordCredentialActivity: @escaping (ObjectStoreCredentialTarget) -> Void = { target in
            ActivityLog.shared.log("Changed object store credential", resourceType: "Object Store", resourceName: target.storeName, resourceId: target.storeId)
        }
    ) {
        self.credentialAPI = credentialAPI
        self.pauseService = pauseService
        self.settingsRegion = settingsRegion
        self.apiKey = apiKey
        self.isAccessAllowed = isAccessAllowed
        self.notificationCenter = notificationCenter
        self.recordCredentialActivity = recordCredentialActivity
        observers = [Notification.Name.civoAPIKeyDidChange, .civoRegionDidChange].map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.settingsChanged() }
            }
        }
    }

    deinit { observers.forEach(notificationCenter.removeObserver) }

    var currentAPIKey: String { apiKey() }
    var currentStorageContext: StorageLoadContext { StorageLoadContext(account: CivoAccount(apiKey: apiKey()), region: settingsRegion()) }
    var isCredentialAccessAllowed: Bool { isAccessAllowed() }

    private func settingsChanged() {
        invalidateStorageReads()
        refreshGeneration += 1
        isLoading = false
        selectedObjectStore = nil
        selectedObjectStoreContext = nil
        browsingObjectStore = nil
        loadContext = nil
        credentials = []
        objectStores = []
        credentialStateID = UUID()
        credentialSwitcher.cancel()
    }

    func invalidateStorageReads() {
        listGeneration += 1
        detailGeneration += 1
    }

    func credentialChangeProblem(for store: CivoObjectStore) -> ObjectStoreCredentialChangeError? {
        if !isAccessAllowed() { return .accessRevoked }
        if loadContext != currentStorageContext || selectedObjectStoreContext != currentStorageContext || selectedObjectStore?.id != store.id || currentStorageContext.region.isEmpty { return .reload }
        if isAssignmentUnconfirmed(store.id) { return .unconfirmed }
        if store.name == ObjectStorePauseService.vaultName { return .vault }
        if store.status?.lowercased() != "ready" { return .inactive }
        if isPausing || isResuming { return .pauseBusy }
        if isSaving { return .saveBusy }
        return operationGate.problem
    }

    func canUseCredentials(for store: CivoObjectStore) -> Bool {
        loadContext == currentStorageContext && !isAssignmentUnconfirmed(store.id) && !operationGate.isExclusive
    }

    func pendingCredentialAssignment(_ id: String) -> PendingAssignment? {
        pendingAssignments.first { $0.target.context == currentStorageContext && $0.target.storeId == id }
    }

    func isAssignmentUnconfirmed(_ id: String) -> Bool { pendingCredentialAssignment(id) != nil }

    func markCredentialAssignmentUnconfirmed(_ target: ObjectStoreCredentialTarget, requestedAccessKey: String) {
        pendingAssignments.removeAll { $0.target.context == target.context && $0.target.storeId == target.storeId }
        pendingAssignments.append(PendingAssignment(target: target, requestedAccessKey: requestedAccessKey))
        if currentStorageContext == target.context {
            invalidateStorageReads()
            browsingObjectStore = nil
            credentialStateID = UUID()
        }
    }

    func resolveCredentialAssignment(_ target: ObjectStoreCredentialTarget, store: CivoObjectStore) {
        pendingAssignments.removeAll { $0.target.context == target.context && $0.target.storeId == target.storeId }
        guard currentStorageContext == target.context else { return }
        invalidateStorageReads()
        if let index = objectStores.firstIndex(where: { $0.id == store.id }) { objectStores[index] = store }
        if selectedObjectStore?.id == store.id {
            selectedObjectStore = store
            selectedObjectStoreContext = target.context
        }
        browsingObjectStore = nil
        credentialStateID = UUID()
        showSuccess = true
    }

    func installCredentials(_ list: PaginatedList<CivoObjectStoreCredential>, context: StorageLoadContext) {
        guard context == currentStorageContext else { return }
        credentials = list.items
        credentialCompleteness.update(with: list)
    }

    func reloadObjectStores() async {
        let context = currentStorageContext
        let key = apiKey()
        listGeneration += 1
        let generation = listGeneration
        do {
            async let stores = credentialAPI.listObjectStores(region: context.region, apiKey: key)
            async let creds = credentialAPI.listCredentials(region: context.region, apiKey: key)
            let (storeList, credentialList) = try await (stores, creds)
            guard generation == listGeneration, context == currentStorageContext,
                  !operationGate.isExclusive else { return }
            objectStores = storeList.items
            installCredentials(credentialList, context: context)
            objectStoreCompleteness.update(with: storeList)
            loadContext = context
            vaultEnabled = objectStores.contains { $0.name == ObjectStorePauseService.vaultName }
        } catch {
            guard generation == listGeneration, context == currentStorageContext else { return }
            objectStoreCompleteness.update(after: error)
            credentialCompleteness.update(after: error)
            self.error = ObjectStoreCredentialChangeError.from(error).message
        }
    }

    func refresh(holding operation: StorageOperationGate.Token? = nil) async {
        guard operation != nil || !operationGate.isBusy else { return }
        refreshGeneration += 1
        let generation = refreshGeneration
        let context = currentStorageContext
        isLoading = true
        error = nil
        defer { if generation == refreshGeneration { isLoading = false } }
        await reloadObjectStores()
        do {
            async let vols = volumeService.listVolumes()
            async let insts = instanceService.listInstances()
            let (volumes, instances) = try await (vols, insts)
            guard generation == refreshGeneration, context == currentStorageContext else { return }
            self.volumes = volumes
            self.instances = instances.items
            try await reloadPausedStores(holding: operation)
        } catch {
            guard generation == refreshGeneration, context == currentStorageContext else { return }
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func reloadPausedStores(holding operation: StorageOperationGate.Token? = nil) async throws {
        // Manifest reads can repair vault metadata. Reuse the caller's reservation during its refresh.
        guard let token = operation ?? operationGate.begin(.save) else { return }
        defer { if operation == nil { operationGate.end(token) } }
        let context = currentStorageContext
        let generation = refreshGeneration
        let paused = try await pauseService.loadPausedStores()
        guard generation == refreshGeneration, context == currentStorageContext else { return }
        pausedStores = paused
    }

    func loadFormData() async {
        do {
            availableNetworks = try await networkService.listNetworks()
        } catch {
            saveError = CivoAPIError.userMessage(error)
            Log.error("Failed to load form data: \(error.localizedDescription)")
        }
    }

    func createVolume(_ body: sending [String: Any]) async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await volumeService.createVolume(body)
            isCreatingVolume = false
            showSuccess = true
            await refresh(holding: token)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func createObjectStore(_ body: sending [String: Any]) async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.createObjectStore(body)
            isCreatingObjectStore = false
            showSuccess = true
            await refresh(holding: token)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    var unusedVolumes: [CivoVolume] {
        volumes.filter { $0.status?.lowercased() == "available" }
    }

    func cleanupUnusedVolumes() async {
        guard let token = operationGate.begin(.save) else { return }
        defer { operationGate.end(token) }
        let unused = unusedVolumes
        var hadError = false
        for vol in unused {
            do {
                try await volumeService.removeVolume(vol.id)
            } catch {
                hadError = true
                self.error = CivoAPIError.userMessage(error)
                Log.error("Failed to remove volume \(vol.name): \(error.localizedDescription)")
            }
        }
        await refresh(holding: token)
        if !hadError { showSuccess = true }
    }

    func removeVolume(_ id: String) async {
        guard let token = operationGate.begin(.save) else { return }
        defer { operationGate.end(token) }
        do {
            try await volumeService.removeVolume(id)
            await refresh(holding: token)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func resizeVolume(_ id: String, newSizeGb: Int) async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            try await volumeService.resizeVolume(id, sizeGb: newSizeGb)
            showSuccess = true
            await refresh(holding: token)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func updateObjectStoreSize(_ id: String, newSize: Int) async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.updateObjectStore(id, body: ["max_size_gb": newSize])
            showSuccess = true
            await refresh(holding: token)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func loadObjectStoreDetail(_ id: String) async {
        let context = currentStorageContext
        guard loadContext == context, !operationGate.isExclusive else { return }
        let key = apiKey()
        detailGeneration += 1
        let generation = detailGeneration
        do {
            let store = try await credentialAPI.showObjectStore(id, region: context.region, apiKey: key)
            guard generation == detailGeneration, context == currentStorageContext,
                  !operationGate.isExclusive, store.id == id else { return }
            selectedObjectStore = store
            selectedObjectStoreContext = context
        } catch {
            guard generation == detailGeneration, context == currentStorageContext else { return }
            self.error = ObjectStoreCredentialChangeError.from(error).message
        }
    }

    func removeObjectStore(_ name: String) async {
        guard let token = operationGate.begin(.save) else { return }
        defer { operationGate.end(token) }
        do {
            try await objectStoreService.removeObjectStore(name)
            await refresh(holding: token)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func credentialForStore(_ store: CivoObjectStore) -> CivoObjectStoreCredential? {
        guard loadContext == currentStorageContext, !isAssignmentUnconfirmed(store.id) else { return nil }
        if let credId = store.credentialId,
           let credential = credentials.first(where: { $0.id == credId && (store.accessKeyId == nil || $0.accessKeyId == store.accessKeyId) }) {
            return credential
        }
        // The access key is authoritative for S3, even if Civo still reports the previous credential ID.
        guard let key = store.accessKeyId, !key.isEmpty else { return nil }
        let matches = credentials.filter { $0.accessKeyId == key }
        return matches.count == 1 ? matches[0] : nil
    }

    func createCredential(_ name: String) async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.createCredential(["name": name])
            isCreatingCredential = false
            showSuccess = true
            await refresh(holding: token)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func removeCredential(_ id: String) async {
        guard let token = operationGate.begin(.save) else { return }
        defer { operationGate.end(token) }
        do {
            try await objectStoreService.removeCredential(id)
            await refresh(holding: token)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    // MARK: - Pause / Resume

    /// Stores visible to the user (excludes the vault store)
    var visibleObjectStores: [CivoObjectStore] {
        objectStores.filter { $0.name != ObjectStorePauseService.vaultName }
    }

    func setupVault() async -> Bool {
        guard let token = operationGate.begin(.save) else { return false }
        defer { operationGate.end(token) }
        isSaving = true
        pauseError = nil
        defer { isSaving = false }

        do {
            let _ = try await pauseService.setupVault()
            vaultEnabled = true
            await refresh(holding: token)
            return true
        } catch {
            pauseError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func pauseObjectStore(_ store: CivoObjectStore) {
        guard !isPausing && !isResuming else { return }
        guard let credential = credentialForStore(store) else {
            pauseError = "No credentials found for \(store.name)"
            return
        }
        guard !isAssignmentUnconfirmed(store.id), let token = operationGate.begin(.pauseResume) else { return }
        isPausing = true
        pauseError = nil
        pauseProgress = nil

        pausingTask = Task { [self] in
            defer { operationGate.end(token); isPausing = false; pausingTask = nil }
            do {
                try await pauseService.pauseStore(store, credential: credential) { progress in
                    Task { @MainActor [weak self] in
                        self?.pauseProgress = progress
                    }
                }
                isPausing = false
                showSuccess = true
                await refresh(holding: token)
            } catch is CancellationError {
                isPausing = false
                pauseProgress = nil
            } catch {
                isPausing = false
                pauseError = CivoAPIError.userMessage(error)
            }
        }
    }

    func resumeObjectStore(_ paused: PausedObjectStore) {
        guard !isPausing && !isResuming else { return }
        guard let token = operationGate.begin(.pauseResume) else { return }
        startResume(paused, token: token)
    }

    private func startResume(_ paused: PausedObjectStore, token: StorageOperationGate.Token) {
        isResuming = true
        pauseError = nil
        pauseProgress = nil

        pausingTask = Task { [self] in
            defer { operationGate.end(token); isResuming = false; pausingTask = nil }
            do {
                try await pauseService.resumeStore(paused) { progress in
                    Task { @MainActor [weak self] in
                        self?.pauseProgress = progress
                    }
                }
                isResuming = false
                showSuccess = true
                await refresh(holding: token)
            } catch is CancellationError {
                isResuming = false
                pauseProgress = nil
            } catch {
                isResuming = false
                pauseError = CivoAPIError.userMessage(error)
            }
        }
    }

    func cancelPauseResume() {
        pausingTask?.cancel()
        // Cancellation is cooperative. The task retains its token until its body finishes.
    }

    func assignCredentialAndResume(_ paused: PausedObjectStore, credentialId: String, accessKeyId: String?) async {
        guard let token = operationGate.begin(.pauseResume) else { return }
        await prepareCredentialAndResume(paused, credentialId: credentialId, accessKeyId: accessKeyId, token: token)
    }

    private func prepareCredentialAndResume(_ paused: PausedObjectStore, credentialId: String, accessKeyId: String?, token: StorageOperationGate.Token) async {
        do {
            try await pauseService.updatePausedStoreCredential(
                storeName: paused.originalName,
                credentialId: credentialId,
                accessKeyId: accessKeyId
            )
            // Build updated paused store directly (do NOT call loadPausedStores which may auto-clean the entry)
            let updated = PausedObjectStore(
                id: paused.id, originalName: paused.originalName, originalMaxSize: paused.originalMaxSize,
                credentialId: credentialId, accessKeyId: accessKeyId,
                region: paused.region, endpoint: paused.endpoint, pausedAt: paused.pausedAt,
                fileCount: paused.fileCount, totalSizeBytes: paused.totalSizeBytes, vaultPrefix: paused.vaultPrefix
            )
            try Task.checkCancellation()
            startResume(updated, token: token)
        } catch {
            operationGate.end(token)
            pauseError = CivoAPIError.userMessage(error)
        }
    }

    func discardPausedStore(_ paused: PausedObjectStore) async {
        guard let token = operationGate.begin(.save) else { return }
        defer { operationGate.end(token) }
        do {
            try await pauseService.discardPausedStore(paused)
            showSuccess = true
            await refresh(holding: token)
        } catch {
            pauseError = CivoAPIError.userMessage(error)
        }
    }

    func createCredentialAndResume(_ paused: PausedObjectStore) async {
        guard let token = operationGate.begin(.pauseResume) else { return }
        do {
            let newCred = try await CivoObjectStoreService().createCredential(["name": paused.originalName])
            await prepareCredentialAndResume(paused, credentialId: newCred.id, accessKeyId: newCred.accessKeyId, token: token)
        } catch {
            operationGate.end(token)
            pauseError = CivoAPIError.userMessage(error)
        }
    }
}
