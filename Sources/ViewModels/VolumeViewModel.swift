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

    private let volumeService = CivoVolumeService()
    private let objectStoreService = CivoObjectStoreService()
    private let networkService = CivoNetworkService()

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
}
