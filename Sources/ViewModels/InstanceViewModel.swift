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
    private let volumeService = CivoVolumeService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let insts = instanceService.listInstances()
            async let keys = sshKeyService.listSSHKeys()

            instances = try await insts
            sshKeys = try await keys

            // Update selectedInstance with fresh data
            if let selected = selectedInstance,
               let updated = instances.first(where: { $0.id == selected.id }) {
                selectedInstance = updated
            }
        } catch {
            self.error = CivoAPIError.userMessage(error)
            Log.error("Instance refresh failed: \(error.localizedDescription)")
        }
    }

    var selectedInstanceIsBuilding: Bool {
        guard let status = selectedInstance?.status?.lowercased() else { return false }
        return status != "active" && status != "error"
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
            saveError = CivoAPIError.userMessage(error)
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
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func stopInstance(_ id: String) async {
        let name = instances.first { $0.id == id }?.name ?? id
        do {
            try await instanceService.stopInstance(id); showSuccess = true
            ActivityLog.shared.log("Stopped", resourceType: "Instance", resourceName: name, resourceId: id)
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func startInstance(_ id: String) async {
        let name = instances.first { $0.id == id }?.name ?? id
        do {
            try await instanceService.startInstance(id); showSuccess = true
            ActivityLog.shared.log("Started", resourceType: "Instance", resourceName: name, resourceId: id)
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func rebootInstance(_ id: String) async {
        let name = instances.first { $0.id == id }?.name ?? id
        do {
            try await instanceService.rebootInstance(id); showSuccess = true
            ActivityLog.shared.log("Rebooted", resourceType: "Instance", resourceName: name, resourceId: id)
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func updateInstance(_ id: String, reverseDns: String) async {
        let name = instances.first { $0.id == id }?.name ?? id
        do {
            _ = try await instanceService.updateInstance(id, body: ["reverse_dns": reverseDns])
            showSuccess = true
            ActivityLog.shared.log("Set Reverse DNS to \(reverseDns)", resourceType: "Instance", resourceName: name, resourceId: id)
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func resizeInstance(_ id: String, size: String) async {
        let name = instances.first { $0.id == id }?.name ?? id
        do {
            try await instanceService.resizeInstance(id, size: size)
            showSuccess = true
            ActivityLog.shared.log("Resized to \(size)", resourceType: "Instance", resourceName: name, resourceId: id)
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func attachVolume(_ volumeId: String, instanceId: String) async {
        do {
            try await volumeService.attachVolume(volumeId, instanceId: instanceId)
            showSuccess = true
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func detachVolume(_ volumeId: String) async {
        do {
            try await volumeService.detachVolume(volumeId)
            showSuccess = true
            await refresh()
        } catch { self.error = CivoAPIError.userMessage(error) }
    }

    func removeInstance(_ id: String) async {
        do {
            try await instanceService.removeInstance(id)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func removeSSHKey(_ name: String) async {
        do {
            try await sshKeyService.removeSSHKey(name)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }
}
