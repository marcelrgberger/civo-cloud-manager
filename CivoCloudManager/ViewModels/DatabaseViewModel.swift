import Foundation

@Observable
@MainActor
final class DatabaseViewModel {
    var databases: [CivoDatabase] = []
    var isLoading = false
    var error: String?

    var selectedDatabase: CivoDatabase?
    var isCreating = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []
    var availableFirewalls: [CivoFirewall] = []
    var availableSizes: [CivoSize] = []

    private let service = CivoDatabaseService()
    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let sizeService = CivoSizeService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            databases = try await service.listDatabases()
        } catch {
            self.error = CivoAPIError.userMessage(error)
            Log.error("Database list failed: \(error.localizedDescription)")
        }
    }

    func loadFormData() async {
        do {
            async let nets = networkService.listNetworks()
            async let fws = firewallService.listFirewalls()
            async let sizes = sizeService.listSizes()
            availableNetworks = try await nets
            availableFirewalls = try await fws
            availableSizes = try await sizes
        } catch {
            Log.error("Failed to load form data: \(error.localizedDescription)")
        }
    }

    func createDatabase(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.createDatabase(body)
            isCreating = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func removeDatabase(_ name: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await service.removeDatabase(name)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }
}
