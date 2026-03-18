import Foundation

@Observable
@MainActor
final class VolumeViewModel {
    var volumes: [CivoVolume] = []
    var objectStores: [CivoObjectStore] = []
    var isLoading = false
    var error: String?

    private let volumeService = CivoVolumeService()
    private let objectStoreService = CivoObjectStoreService()

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
