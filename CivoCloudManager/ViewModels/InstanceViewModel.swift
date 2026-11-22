import Foundation

@Observable
@MainActor
final class InstanceViewModel {
    var instances: [CivoInstance] = []
    private(set) var instanceCompleteness = ListCompleteness()
    var sshKeys: [CivoSSHKey] = []
    var isLoading = false
    var error: String?

    var selectedInstance: CivoInstance?
    /// Region the current `instances` were fetched from.
    private(set) var instancesRegion = ""
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
    private let credentials: InstanceCredentialStore
    private let deleteInstance: (String) async throws -> Void

    init(credentials: InstanceCredentialStore? = nil, deleteInstance: ((String) async throws -> Void)? = nil) {
        self.credentials = credentials ?? .shared
        let service = CivoInstanceService()
        self.deleteInstance = deleteInstance ?? { try await service.removeInstance($0) }
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let region = CivoConfig.shared.region
            async let insts = instanceService.listInstances(region: region.isEmpty ? nil : region)
            async let keys = sshKeyService.listSSHKeys()

            let instanceList: PaginatedList<CivoInstance>
            do {
                instanceList = try await insts
            } catch {
                instanceCompleteness.update(after: error)
                throw error
            }
            instances = instanceList.items
            instanceCompleteness.update(with: instanceList)
            instancesRegion = region
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

    /// Console target with the region the instance was fetched from, never a later Settings change.
    func consoleTarget(for instance: CivoInstance) -> ConsoleTarget? {
        let region = instance.region.flatMap { $0.isEmpty ? nil : $0 } ?? instancesRegion
        guard !region.isEmpty else { return nil }
        return ConsoleTarget(instanceId: instance.id, instanceName: instance.name, region: region)
    }

    /// Passes the instance's initial login to the console window in memory, right before it opens.
    func handOverConsoleLogin(of instance: CivoInstance, to target: ConsoleTarget) {
        ConsoleLoginStore.shared.register(
            ConsoleLogin(user: instance.initialUser, password: instance.initialPassword),
            for: target
        )
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
            saveError = CivoAPIError.userMessage(error)
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
            try? await Task.sleep(for: .seconds(1))
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

    func removeInstance(_ instance: CivoInstance) async {
        guard await delete(instance) else { return }
        // Refreshing clears `error`; a warning about leftover credentials must stay visible.
        let warning = error
        await refresh()
        if error == nil { error = warning }
    }

    /// Deletes the instance and, only once Civo confirmed the deletion, its saved credentials.
    /// A failed deletion keeps them. Returns whether the instance was deleted.
    func delete(_ instance: CivoInstance) async -> Bool {
        error = nil
        // Captured before the request: the key uses the region the instance was loaded from.
        let key = consoleTarget(for: instance).map(InstanceCredentialKey.init)
        do {
            try await deleteInstance(instance.id)
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return false
        }
        guard let key else { return true }
        do {
            try credentials.delete(key)
        } catch {
            let credentialError = error as? InstanceCredentialError ?? .unreadableEntry
            Log.error("Instance credentials not removed after instance deletion: \(credentialError.logDescription)")
            self.error = String(localized: "The instance was deleted, but its saved credentials could not be removed.")
        }
        return true
    }

    /// Whether credentials may be saved for the instance, checked without authentication. A keychain
    /// error counts as "may be saved": only a confirmed missing entry rules it out.
    func mayHaveSavedCredentials(_ instance: CivoInstance) -> Bool {
        guard let target = consoleTarget(for: instance) else { return false }
        return (try? credentials.contains(InstanceCredentialKey(target))) != false
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
