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
    var isCreatingVolume = false
    var isCreatingObjectStore = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []

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

            volumes = try await vols
            objectStores = try await stores
        } catch {
            self.error = error.localizedDescription
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
            saveError = error.localizedDescription
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
            saveError = error.localizedDescription
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
                self.error = error.localizedDescription
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
            self.error = error.localizedDescription
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
            saveError = error.localizedDescription
            return false
        }
    }

    func loadObjectStoreDetail(_ id: String) async {
        do {
            selectedObjectStore = try await objectStoreService.showObjectStore(id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeObjectStore(_ name: String) async {
        do {
            try await objectStoreService.removeObjectStore(name)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
