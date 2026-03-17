import ServiceManagement
import SwiftUI

// MARK: - UserDefaults keys

private enum UDKey {
    static let managedFirewalls = "CivoAccessManager.managedFirewalls"
    static let onboardingComplete = "CivoAccessManager.onboardingComplete"
    static let launchAtLogin = "CivoAccessManager.launchAtLogin"
}

// MARK: - Setup state

enum SetupState: Equatable {
    case checking
    case cliMissing
    case unauthenticated
    case needsFirewallSelection
    case ready
}

// MARK: - AppState

@Observable
@MainActor
final class AppState {
    // Setup state
    var setupState: SetupState = .checking
    var showOnboarding: Bool = false

    // Runtime state
    var currentIP: String = "..."
    var firewalls: [FirewallStatus] = []
    var isLoading: Bool = false
    var error: String?
    var lastRefresh: Date?

    // Discovered (not persisted)
    var discoveredFirewalls: [CivoFirewall] = []
    var currentRegion: String = ""

    // Persisted settings
    var managedFirewalls: [ManagedFirewall] {
        didSet { saveManagedFirewalls() }
    }

    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: UDKey.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: UDKey.onboardingComplete) }
    }

    // Internal
    private let civoAdapter = CivoAdapter()
    private let ipDetector = IPDetector()
    private var refreshTimer: Timer?

    // MARK: - Computed properties

    var enabledFirewalls: [ManagedFirewall] {
        managedFirewalls.filter(\.enabled)
    }

    var allClosed: Bool { firewalls.allSatisfy { !$0.isOpen } }
    var anyOpen: Bool { firewalls.contains { $0.isOpen } }
    var openCount: Int { firewalls.filter(\.isOpen).count }

    var menuBarIcon: String {
        if setupState != .ready && setupState != .checking { return "shield.slash" }
        if isLoading { return "shield.lefthalf.filled" }
        if anyOpen { return "shield.checkered" }
        return "shield.fill"
    }

    var menuBarColor: Color {
        if setupState != .ready && setupState != .checking { return .red }
        if anyOpen { return .yellow }
        return .green
    }

    var statusText: String {
        if setupState == .cliMissing { return "civo CLI not installed" }
        if setupState == .unauthenticated { return "civo CLI not authenticated" }
        if setupState == .needsFirewallSelection { return "Setup required" }
        if isLoading { return "Loading..." }
        if let error { return "Error: \(error)" }
        if allClosed && !firewalls.isEmpty { return "All closed" }
        if anyOpen { return "\(openCount) firewall\(openCount == 1 ? "" : "s") open" }
        if enabledFirewalls.isEmpty { return "No firewalls managed" }
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

    // MARK: - Init

    init() {
        // Load persisted managed firewalls
        if let data = UserDefaults.standard.data(forKey: UDKey.managedFirewalls),
            let decoded = try? JSONDecoder().decode([ManagedFirewall].self, from: data)
        {
            self.managedFirewalls = decoded
        } else {
            self.managedFirewalls = []
        }

        self.launchAtLogin = UserDefaults.standard.bool(forKey: UDKey.launchAtLogin)
        self.onboardingComplete = UserDefaults.standard.bool(forKey: UDKey.onboardingComplete)
    }

    // MARK: - Persistence

    private func saveManagedFirewalls() {
        if let data = try? JSONEncoder().encode(managedFirewalls) {
            UserDefaults.standard.set(data, forKey: UDKey.managedFirewalls)
        }
    }

    private func updateLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                try service.register()
                Log.info("Launch at login: registered")
            } else {
                try service.unregister()
                Log.info("Launch at login: unregistered")
            }
        } catch {
            Log.error("Launch at login toggle failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Setup & Onboarding

    func checkSetup() async {
        setupState = .checking

        // Check CLI installed
        guard civoAdapter.isCLIInstalled() else {
            setupState = .cliMissing
            if !onboardingComplete { showOnboarding = true }
            return
        }

        // Check authenticated
        let authed = await civoAdapter.isAuthenticated()
        guard authed else {
            setupState = .unauthenticated
            if !onboardingComplete { showOnboarding = true }
            return
        }

        // Check if user has configured firewalls
        if enabledFirewalls.isEmpty {
            setupState = .needsFirewallSelection
            if !onboardingComplete { showOnboarding = true }
            return
        }

        setupState = .ready
    }

    func discoverFirewalls() async {
        do {
            discoveredFirewalls = try await civoAdapter.discoverFirewalls()
            currentRegion = try await civoAdapter.getCurrentRegion()
        } catch {
            self.error = error.localizedDescription
            Log.error("Firewall discovery failed: \(error.localizedDescription)")
        }
    }

    func completeOnboarding() {
        onboardingComplete = true
        showOnboarding = false

        if !enabledFirewalls.isEmpty {
            setupState = .ready
            Task { await initialLoad() }
        }
    }

    // MARK: - Actions

    func initialLoad() async {
        await checkSetup()
        guard setupState == .ready else { return }
        await refresh()
        startAutoRefresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        defer { isLoading = false }

        guard setupState == .ready else {
            error = "Setup not complete"
            return
        }

        // Detect IP
        do {
            currentIP = try await ipDetector.detectIP()
        } catch {
            self.error = "IP detection failed: \(error.localizedDescription)"
            return
        }

        // Get firewall status for managed firewalls
        do {
            firewalls = try await civoAdapter.getStatus(
                managedFirewalls: enabledFirewalls,
                currentIP: currentIP
            )
            lastRefresh = Date()
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func openFirewall(_ managed: ManagedFirewall) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            if currentIP == "..." {
                currentIP = try await ipDetector.detectIP()
            }
            let label = CivoAccessLabel.make(firewallName: managed.name)
            try await civoAdapter.openAccess(
                firewall: managed.name,
                port: managed.port,
                ip: currentIP,
                label: label
            )
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        // Refresh without the isLoading guard
        await forceRefresh()
    }

    func closeFirewall(_ status: FirewallStatus) async {
        guard !isLoading, let ruleId = status.ruleId else { return }
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            try await civoAdapter.closeAccess(firewall: status.managed.name, ruleId: ruleId)
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    func openAll() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            if currentIP == "..." {
                currentIP = try await ipDetector.detectIP()
            }

            for managed in enabledFirewalls {
                let existing = firewalls.first { $0.id == managed.id }
                if existing?.isOpen != true {
                    let label = CivoAccessLabel.make(firewallName: managed.name)
                    try await civoAdapter.openAccess(
                        firewall: managed.name,
                        port: managed.port,
                        ip: currentIP,
                        label: label
                    )
                }
            }

            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    func closeAll() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let count = try await civoAdapter.closeAllManagedRules(managedFirewalls: enabledFirewalls)
            Log.info("Closed \(count) rules")
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    /// Internal refresh that does not check isLoading — used after mutations.
    private func forceRefresh() async {
        error = nil

        do {
            if currentIP == "..." {
                currentIP = try await ipDetector.detectIP()
            }
            firewalls = try await civoAdapter.getStatus(
                managedFirewalls: enabledFirewalls,
                currentIP: currentIP
            )
            lastRefresh = Date()
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Auto-refresh

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
