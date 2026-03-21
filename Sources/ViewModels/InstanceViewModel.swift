import Foundation

@Observable
@MainActor
final class InstanceViewModel {
    var instances: [CivoInstance] = []
    var sshKeys: [CivoSSHKey] = []
    var isLoading = false
    var error: String?

    var selectedInstance: CivoInstance?
    var isCreatingInstance = false
    var isCreatingSSHKey = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []
    var availableFirewalls: [CivoFirewall] = []
    var availableSizes: [CivoSize] = []
    var availableDiskImages: [CivoDiskImage] = []

    private let instanceService = CivoInstanceService()
    private let sshKeyService = CivoSSHKeyService()
    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let sizeService = CivoSizeService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let insts = instanceService.listInstances()
            async let keys = sshKeyService.listSSHKeys()

            instances = try await insts
            sshKeys = try await keys
        } catch {
            self.error = error.localizedDescription
            Log.error("Instance refresh failed: \(error.localizedDescription)")
        }
    }

    func loadFormData() async {
        do {
            async let nets = networkService.listNetworks()
            async let fws = firewallService.listFirewalls()
            async let sizes = sizeService.listSizes()
            async let images = sizeService.listDiskImages()
            availableNetworks = try await nets
            availableFirewalls = try await fws
            availableSizes = try await sizes
            availableDiskImages = try await images
        } catch {
            Log.error("Failed to load form data: \(error.localizedDescription)")
        }
    }

    func createInstance(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await instanceService.createInstance(body)
            isCreatingInstance = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func createSSHKey(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await sshKeyService.createSSHKey(body)
            isCreatingSSHKey = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func stopInstance(_ id: String) async {
        do { try await instanceService.stopInstance(id); showSuccess = true; await refresh() }
        catch { self.error = error.localizedDescription }
    }

    func startInstance(_ id: String) async {
        do { try await instanceService.startInstance(id); showSuccess = true; await refresh() }
        catch { self.error = error.localizedDescription }
    }

    func rebootInstance(_ id: String) async {
        do { try await instanceService.rebootInstance(id); showSuccess = true; await refresh() }
        catch { self.error = error.localizedDescription }
    }

    func removeInstance(_ id: String) async {
        do {
            try await instanceService.removeInstance(id)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeSSHKey(_ name: String) async {
        do {
            try await sshKeyService.removeSSHKey(name)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
