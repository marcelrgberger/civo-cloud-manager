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
    var isCreatingRule = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var selectedFirewall: CivoFirewall?
    private(set) var selectedLoadBalancer: CivoLoadBalancer?
    /// The account and region `loadBalancers` were loaded from; an edit is bound to both.
    private(set) var loadBalancersContext: LoadBalancerContext?
    /// The context of the list the selected load balancer was chosen from.
    private(set) var selectedLoadBalancerContext: LoadBalancerContext?
    let loadBalancerCreator = LoadBalancerCreateController()
    var rules: [CivoRule] = []
    /// The region and account `rules` were loaded from; a rule edit is bound to both.
    private(set) var rulesRegion = ""
    private(set) var rulesAccount: CivoAccount?

    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let loadBalancerService = CivoLoadBalancerService()

    /// Counts refreshes, so only the answer to the latest one is shown.
    private var refreshGeneration = 0

    /// Loads networks, firewalls and load balancers with one account and region, read once at the start.
    /// An answer overtaken by a later refresh is dropped, so the lists never mix accounts or regions.
    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let region = CivoConfig.shared.region
        let apiKey = CivoConfig.shared.apiKey
        isLoading = true
        error = nil
        defer { if generation == refreshGeneration { isLoading = false } }

        do {
            async let nets = networkService.listNetworks(region: region, apiKey: apiKey)
            async let fws = firewallService.listFirewalls(region: region, apiKey: apiKey)
            async let lbs = loadBalancerService.listLoadBalancers(region: region, apiKey: apiKey)
            let (loadedNetworks, loadedFirewalls, loadedLoadBalancers) = try await (nets, fws, lbs)
            guard generation == refreshGeneration else { return }
            networks = loadedNetworks
            firewalls = loadedFirewalls
            loadBalancers = loadedLoadBalancers
            loadBalancersContext = LoadBalancerContext(account: CivoAccount(apiKey: apiKey), region: region)
        } catch {
            guard generation == refreshGeneration else { return }
            // Civo's answer text is not shown or logged; it may echo request details.
            let failure = LoadBalancerFailure(error)
            self.error = failure.message
            Log.error("Network refresh failed: \(failure.diagnosticName)")
        }
    }

    func selectLoadBalancer(_ lb: CivoLoadBalancer?) {
        selectedLoadBalancer = lb
        selectedLoadBalancerContext = lb == nil ? nil : loadBalancersContext
    }

    /// Shows Civo's confirmed values of the selected load balancer, if it is still the one edited under `context`.
    func replaceSelectedLoadBalancer(with lb: CivoLoadBalancer, editedIn context: LoadBalancerContext) {
        guard selectedLoadBalancer?.id == lb.id, selectedLoadBalancerContext == context else { return }
        selectedLoadBalancer = lb
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
            saveError = CivoAPIError.userMessage(error)
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
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func removeNetwork(_ id: String) async {
        do {
            try await networkService.removeNetwork(id)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func removeFirewall(_ id: String) async {
        do {
            try await firewallService.removeFirewall(id)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func removeLoadBalancer(_ id: String) async {
        do {
            try await loadBalancerService.removeLoadBalancer(id)
            await refresh()
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func loadRules(_ firewallId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let region = CivoConfig.shared.region
            let apiKey = CivoConfig.shared.apiKey
            rules = try await firewallService.getRulesForFirewall(firewallId, region: region, apiKey: apiKey)
            rulesRegion = region
            rulesAccount = CivoAccount(apiKey: apiKey)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    func createRule(_ firewallId: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            try await firewallService.createRuleFromBody(firewallId: firewallId, body: body)
            isCreatingRule = false
            showSuccess = true
            await loadRules(firewallId)
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    func deleteRule(_ firewallId: String, ruleId: String) async {
        do {
            try await firewallService.deleteRule(firewallId: firewallId, ruleId: ruleId)
            await loadRules(firewallId)
        } catch {
            self.error = CivoAPIError.userMessage(error)
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
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }
}
