import Foundation

@Observable
@MainActor
final class NetworkViewModel {
    var networks: [CivoNetwork] = []
    var firewalls: [CivoFirewall] = []
    var loadBalancers: [CivoLoadBalancer] = []
    var isLoading = false
    var error: String?

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
}
