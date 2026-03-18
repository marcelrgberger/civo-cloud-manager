import Foundation

@Observable
@MainActor
final class InstanceViewModel {
    var instances: [CivoInstance] = []
    var sshKeys: [CivoSSHKey] = []
    var isLoading = false
    var error: String?

    private let instanceService = CivoInstanceService()
    private let sshKeyService = CivoSSHKeyService()

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
