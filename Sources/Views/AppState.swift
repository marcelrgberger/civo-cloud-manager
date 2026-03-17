import SwiftUI

@Observable
@MainActor
final class AppState {
    var currentIP: String = "..."
    var firewalls: [FirewallStatus] = []
    var isLoading: Bool = false
    var lastRefresh: Date?
    var error: String?
    var civoAvailable: Bool = true

    private let civoAdapter = CivoAdapter()
    private let ipDetector = IPDetector()
    private var refreshTimer: Timer?

    var allClosed: Bool { firewalls.allSatisfy { !$0.isOpen } }
    var anyOpen: Bool { firewalls.contains { $0.isOpen } }
    var openCount: Int { firewalls.filter(\.isOpen).count }

    var menuBarIcon: String {
        if !civoAvailable { return "shield.slash" }
        if isLoading { return "shield.lefthalf.filled" }
        if anyOpen { return "shield.checkered" }
        return "shield.fill"
    }

    var menuBarColor: Color {
        if !civoAvailable { return .red }
        if anyOpen { return .yellow }
        return .green
    }

    var statusText: String {
        if !civoAvailable { return "civo CLI not available" }
        if isLoading { return "Loading..." }
        if let error { return "Error: \(error)" }
        if allClosed && !firewalls.isEmpty { return "All closed" }
        if anyOpen { return "\(openCount) firewall\(openCount == 1 ? "" : "s") open" }
        return "Ready"
    }

    var lastRefreshText: String {
        guard let lastRefresh else { return "Never" }
        let interval = Date().timeIntervalSince(lastRefresh)
        if interval < 5 { return "Just now" }
        if interval < 60 { return "\(Int(interval))s ago" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }

    // MARK: - Actions

    func initialLoad() {
        Task { await refresh() }
        startAutoRefresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Check civo availability
        let authenticated = await civoAdapter.isAuthenticated()
        civoAvailable = authenticated

        guard authenticated else {
            isLoading = false
            error = "civo CLI not authenticated"
            return
        }

        // Detect IP
        do {
            currentIP = try await ipDetector.detectIP()
        } catch {
            self.error = "IP detection failed: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // Get firewall status
        do {
            firewalls = try await civoAdapter.getStatus(currentIP: currentIP)
            lastRefresh = Date()
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func openFirewall(_ config: FirewallConfig) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            if currentIP == "..." {
                currentIP = try await ipDetector.detectIP()
            }
            try await civoAdapter.openAccess(firewall: config, ip: currentIP)
            // Brief pause before refreshing to let civo propagate
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func closeFirewall(_ status: FirewallStatus) async {
        guard !isLoading, let ruleId = status.ruleId else { return }
        isLoading = true
        error = nil

        do {
            try await civoAdapter.closeAccess(firewallName: status.config.name, ruleId: ruleId)
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func openAll() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            if currentIP == "..." {
                currentIP = try await ipDetector.detectIP()
            }

            for config in Firewalls.all {
                // Only open if not already open
                let existing = firewalls.first { $0.id == config.name }
                if existing?.isOpen != true {
                    try await civoAdapter.openAccess(firewall: config, ip: currentIP)
                }
            }

            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func closeAll() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let count = try await civoAdapter.closeAllAccess()
            Log.info("Closed \(count) rules")
            try? await Task.sleep(for: .seconds(1))
            await refresh()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Auto-refresh

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
