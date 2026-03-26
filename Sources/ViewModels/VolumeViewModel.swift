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

    var availableNetworks: [CivoNetwork] = []
    var credentials: [CivoObjectStoreCredential] = []
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
    private let objectStoreService = CivoObjectStoreService()
    private let networkService = CivoNetworkService()
    private let pauseService = ObjectStorePauseService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let vols = volumeService.listVolumes()
            async let stores = objectStoreService.listObjectStores()
            async let creds = objectStoreService.listCredentials()

            volumes = try await vols
            objectStores = try await stores
            credentials = try await creds

            // Check if vault exists
            vaultEnabled = objectStores.contains { $0.name == ObjectStorePauseService.vaultName }

            // Load paused stores (also check local fallback if vault is missing)
            do {
                pausedStores = try await pauseService.loadPausedStores()
            } catch {
                pauseError = CivoAPIError.userMessage(error)
                Log.error("Failed to load paused stores: \(error.localizedDescription)")
            }
        } catch {
            self.error = CivoAPIError.userMessage(error)
            Log.error("Storage refresh failed: \(error.localizedDescription)")
        }
    }

    func loadFormData() async {
        do {
            availableNetworks = try await networkService.listNetworks()
        } catch {
            Log.error("Failed to load form data: \(error.localizedDescription)")
        }
    }

    func createVolume(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await volumeService.createVolume(body)
            isCreatingVolume = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func createObjectStore(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.createObjectStore(body)
            isCreatingObjectStore = false
            showSuccess = true
            await refresh()
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
        await refresh()
        if !hadError { showSuccess = true }
    }

    func removeVolume(_ id: String) async {
        do {
            try await volumeService.removeVolume(id)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func updateObjectStoreSize(_ id: String, newSize: Int) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.updateObjectStore(id, body: ["max_size_gb": newSize])
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func loadObjectStoreDetail(_ id: String) async {
        do {
            selectedObjectStore = try await objectStoreService.showObjectStore(id)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func removeObjectStore(_ name: String) async {
        do {
            try await objectStoreService.removeObjectStore(name)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func credentialForStore(_ store: CivoObjectStore) -> CivoObjectStoreCredential? {
        guard let credId = store.credentialId else { return nil }
        return credentials.first(where: { $0.id == credId })
    }

    func createCredential(_ name: String) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await objectStoreService.createCredential(["name": name])
            isCreatingCredential = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func removeCredential(_ id: String) async {
        do {
            try await objectStoreService.removeCredential(id)
            await refresh()
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
        isSaving = true
        pauseError = nil
        defer { isSaving = false }

        do {
            let _ = try await pauseService.setupVault()
            vaultEnabled = true
            await refresh()
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
        isPausing = true
        pauseError = nil
        pauseProgress = nil

        pausingTask = Task {
            do {
                try await pauseService.pauseStore(store, credential: credential) { progress in
                    Task { @MainActor [weak self] in
                        self?.pauseProgress = progress
                    }
                }
                isPausing = false
                showSuccess = true
                await refresh()
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
        isResuming = true
        pauseError = nil
        pauseProgress = nil

        pausingTask = Task {
            do {
                try await pauseService.resumeStore(paused) { progress in
                    Task { @MainActor [weak self] in
                        self?.pauseProgress = progress
                    }
                }
                isResuming = false
                showSuccess = true
                await refresh()
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
        pausingTask = nil
        isPausing = false
        isResuming = false
        pauseProgress = nil
    }

    func assignCredentialAndResume(_ paused: PausedObjectStore, credentialId: String, accessKeyId: String?) async {
        do {
            try await pauseService.updatePausedStoreCredential(
                storeName: paused.originalName,
                credentialId: credentialId,
                accessKeyId: accessKeyId
            )
            // Reload to get updated paused store with credentialId
            pausedStores = (try? await pauseService.loadPausedStores()) ?? []
            if let updated = pausedStores.first(where: { $0.originalName == paused.originalName }) {
                resumeObjectStore(updated)
            }
        } catch {
            pauseError = CivoAPIError.userMessage(error)
        }
    }

    func createCredentialAndResume(_ paused: PausedObjectStore) async {
        do {
            let newCred = try await CivoObjectStoreService().createCredential(["name": paused.originalName])
            await assignCredentialAndResume(paused, credentialId: newCred.id, accessKeyId: newCred.accessKeyId)
        } catch {
            pauseError = CivoAPIError.userMessage(error)
        }
    }
}
