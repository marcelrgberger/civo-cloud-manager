import Foundation

@Observable
@MainActor
final class VolumeViewModel {
    var volumes: [CivoVolume] = []
    var objectStores: [CivoObjectStore] = []
    var isLoading = false
    var error: String?

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

    func removeVolume(_ id: String) async {
        do {
            try await volumeService.removeVolume(id)
            await refresh()
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
