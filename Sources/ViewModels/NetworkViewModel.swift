import Foundation

@Observable
@MainActor
final class NetworkViewModel {
    var networks: [CivoNetwork] = []
    var firewalls: [CivoFirewall] = []
    var loadBalancers: [CivoLoadBalancer] = []
    var isLoading = false
    var error: String?

    var isCreatingNetwork = false
    var isCreatingFirewall = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let loadBalancerService = CivoLoadBalancerService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let nets = networkService.listNetworks()
            async let fws = firewallService.listFirewalls()
            async let lbs = loadBalancerService.listLoadBalancers()

            networks = try await nets
            firewalls = try await fws
            loadBalancers = try await lbs
        } catch {
            self.error = error.localizedDescription
            Log.error("Network refresh failed: \(error.localizedDescription)")
        }
    }

    func createNetwork(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await networkService.createNetwork(body)
            isCreatingNetwork = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func updateNetwork(_ id: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await networkService.updateNetwork(id, body: body)
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func removeNetwork(_ id: String) async {
        do {
            try await networkService.removeNetwork(id)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFirewall(_ id: String) async {
        do {
            try await firewallService.removeFirewall(id)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeLoadBalancer(_ id: String) async {
        do {
            try await loadBalancerService.removeLoadBalancer(id)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createFirewall(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await firewallService.createFirewall(body)
            isCreatingFirewall = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }
}
