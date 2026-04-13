import ServiceManagement
import SwiftUI

// MARK: - UserDefaults keys

private enum UDKey {
    static let managedFirewalls = "CivoCloudManager.managedFirewalls"
    static let onboardingComplete = "CivoCloudManager.onboardingComplete"
    static let launchAtLogin = "CivoCloudManager.launchAtLogin"
    static let ipPresets = "CivoCloudManager.ipPresets"
}

// MARK: - Setup state

enum SetupState: Equatable {
    case checking
    case needsAPIKey
    case needsRegion
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
    var availableRegions: [CivoRegion] = []

    // IP Presets (persisted)
    var ipPresets: [IPPreset] {
        didSet { savePresets() }
    }

    // Auto-close timers: maps "firewallId:ruleId" to scheduled close time
    var autoCloseTimers: [String: Date] = [:]
    private var autoCloseTimer: Timer?

    // Persisted settings
    var managedFirewalls: [ManagedFirewall] {
        didSet { saveManagedFirewalls() }
    }

    var launchAtLogin: Bool {
        didSet {
            guard !isRevertingLaunchAtLogin else { return }
            UserDefaults.standard.set(launchAtLogin, forKey: UDKey.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: UDKey.onboardingComplete) }
    }

    // Internal
    private let firewallService = CivoFirewallService()
    private let regionService = CivoRegionService()
    private let ipDetector = IPDetector()
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var isRevertingLaunchAtLogin = false

    // MARK: - Computed properties

    var config: CivoConfig { CivoConfig.shared }

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
        if error != nil { return .red }
        if anyOpen { return .yellow }
        return .green
    }

    var statusText: String {
        if setupState == .needsAPIKey { return "API key not configured" }
        if setupState == .needsRegion { return "No region selected" }
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
        if let data = UserDefaults.standard.data(forKey: UDKey.managedFirewalls),
            let decoded = try? JSONDecoder().decode([ManagedFirewall].self, from: data)
        {
            self.managedFirewalls = decoded
        } else {
            self.managedFirewalls = []
        }

        if let data = UserDefaults.standard.data(forKey: UDKey.ipPresets),
            let decoded = try? JSONDecoder().decode([IPPreset].self, from: data)
        {
            self.ipPresets = decoded
        } else {
            self.ipPresets = []
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
            } else {
                try service.unregister()
            }
        } catch {
            isRevertingLaunchAtLogin = true
            launchAtLogin = !launchAtLogin
            UserDefaults.standard.set(launchAtLogin, forKey: UDKey.launchAtLogin)
            isRevertingLaunchAtLogin = false
            self.error = "Launch at login failed: \(error.localizedDescription)"
        }
    }

    // MARK: - IP Presets

    private func savePresets() {
        if let data = try? JSONEncoder().encode(ipPresets) {
            UserDefaults.standard.set(data, forKey: UDKey.ipPresets)
        }
    }

    func addPreset(name: String, ip: String) {
        let preset = IPPreset(name: name, ip: ip)
        ipPresets.append(preset)
    }

    func removePreset(id: UUID) {
        ipPresets.removeAll { $0.id == id }
    }

    func openFirewallWithPreset(_ preset: IPPreset, firewall: ManagedFirewall) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let label = CivoAccessLabel.make(firewallName: firewall.name)
            try await firewallService.openAccess(
                firewallId: firewall.id,
                port: firewall.port,
                ip: preset.ip,
                label: label,
                region: firewall.region
            )
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    // MARK: - Auto-Close Timer

    func openFirewallWithTimer(_ managed: ManagedFirewall, minutes: Int) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            currentIP = try await ipDetector.detectIP()
            let label = CivoAccessLabel.make(firewallName: managed.name)
            try await firewallService.openAccess(
                firewallId: managed.id,
                port: managed.port,
                ip: currentIP,
                label: label,
                region: managed.region
            )
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()

        // Find the rule that was just opened to register the timer
        if let status = firewalls.first(where: { $0.id == managed.id }), let ruleId = status.ruleId {
            let key = "\(managed.id):\(ruleId)"
            autoCloseTimers[key] = Date().addingTimeInterval(Double(minutes * 60))
            startAutoCloseTimer()
        }
    }

    func startAutoCloseTimer() {
        guard autoCloseTimer == nil else { return }
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAutoCloseTimers()
            }
        }
    }

    private func checkAutoCloseTimers() async {
        let now = Date()
        var keysToRemove: [String] = []

        for (key, closeTime) in autoCloseTimers where closeTime <= now {
            let parts = key.split(separator: ":")
            guard parts.count == 2 else {
                keysToRemove.append(key)
                continue
            }
            let firewallId = String(parts[0])
            let ruleId = String(parts[1])

            do {
                try await firewallService.closeAccess(firewallId: firewallId, ruleId: ruleId)
                keysToRemove.append(key)
            } catch {
                Log.error("Auto-close failed for \(key): \(error.localizedDescription)")
                keysToRemove.append(key) // Remove even on failure to avoid infinite retries
            }
        }

        for key in keysToRemove {
            autoCloseTimers.removeValue(forKey: key)
        }

        if !keysToRemove.isEmpty {
            try? await Task.sleep(for: .seconds(1))
            await forceRefresh()
        }

        // Stop the timer if no more scheduled closures
        if autoCloseTimers.isEmpty {
            autoCloseTimer?.invalidate()
            autoCloseTimer = nil
        }
    }

    /// Returns the remaining minutes for an auto-close timer, if any, for the given firewall status.
    func remainingMinutes(for status: FirewallStatus) -> Int? {
        guard let ruleId = status.ruleId else { return nil }
        let key = "\(status.managed.id):\(ruleId)"
        guard let closeTime = autoCloseTimers[key] else { return nil }
        let remaining = closeTime.timeIntervalSince(Date())
        guard remaining > 0 else { return nil }
        return Int(ceil(remaining / 60))
    }

    // MARK: - Setup & Onboarding

    func checkSetup() async {
        setupState = .checking

        guard config.hasAPIKey else {
            setupState = .needsAPIKey
            return
        }

        // Validate API key — only reject if we get a definitive auth failure,
        // not on network errors (timeout, DNS, etc.)
        do {
            let regions: [CivoRegion] = try await CivoAPIClient.shared.getArray(
                path: "/regions", regionRequired: false
            )
            // Key is valid if we got a response
            _ = regions
        } catch CivoAPIError.httpError(let code, _) where code == 401 || code == 403 {
            setupState = .needsAPIKey
            return
        } catch {
            // Network error — don't force re-auth, just log and continue
            Log.warning("API validation failed (network): \(error.localizedDescription)")
        }

        guard config.hasRegion else {
            setupState = .needsRegion
            return
        }

        if enabledFirewalls.isEmpty {
            setupState = .needsFirewallSelection
            return
        }

        setupState = .ready
    }

    func discoverFirewalls() async {
        discoveredFirewalls = []

        // Load regions first if not already loaded
        if availableRegions.isEmpty {
            await loadRegions()
        }

        // Discover firewalls from all regions (pass region as query param to avoid mutating global state)
        var allFirewalls: [CivoFirewall] = []

        for region in availableRegions {
            do {
                var regionFirewalls = try await firewallService.listFirewalls(region: region.code)
                for i in regionFirewalls.indices {
                    regionFirewalls[i].region = region.code
                }
                allFirewalls.append(contentsOf: regionFirewalls)
            } catch {
                Log.error("Firewall discovery failed for \(region.code): \(error.localizedDescription)")
            }
        }
        discoveredFirewalls = allFirewalls
    }

    func loadRegions() async {
        do {
            availableRegions = try await regionService.listRegions()
            // Regions loaded for onboarding picker
            _ = availableRegions
        } catch {
            Log.error("Region load failed: \(error.localizedDescription)")
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

        if setupState != .ready && !onboardingComplete {
            showOnboarding = true
        }

        guard setupState == .ready else { return }
        await syncManagedFirewalls()
        await refresh()
        startAutoRefresh()
    }

    /// Sync managed firewalls with all regions:
    /// - Backfill region for existing entries that are missing it
    /// - Auto-add firewalls from regions that weren't scanned before
    /// - Remove firewalls that no longer exist in the API
    private func syncManagedFirewalls() async {
        await loadRegions()

        var allFirewalls: [(fw: CivoFirewall, region: String)] = []
        for region in availableRegions {
            do {
                let fws = try await firewallService.listFirewalls(region: region.code)
                for fw in fws {
                    allFirewalls.append((fw: fw, region: region.code))
                }
            } catch {
                Log.error("Firewall sync failed for \(region.code): \(error.localizedDescription)")
            }
        }

        let existingIds = Set(managedFirewalls.map(\.id))
        let apiIds = Set(allFirewalls.map(\.fw.id))
        var updated = managedFirewalls

        // Backfill region for existing entries
        for i in updated.indices where updated[i].region.isEmpty {
            if let match = allFirewalls.first(where: { $0.fw.id == updated[i].id }) {
                updated[i].region = match.region
            }
        }

        // Remove firewalls that no longer exist in API
        updated.removeAll { !apiIds.contains($0.id) }

        // Auto-add new firewalls from all regions (enabled by default, skip "default-*")
        for (fw, region) in allFirewalls where !existingIds.contains(fw.id) {
            let isDefault = fw.name.hasPrefix("default")
            updated.append(ManagedFirewall(
                id: fw.id,
                name: fw.name,
                port: 6443,
                enabled: !isDefault,
                region: region
            ))
        }

        managedFirewalls = updated
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

        do {
            currentIP = try await ipDetector.detectIP()
        } catch is CancellationError {
            return // Task was cancelled (e.g. popover closed), don't show error
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            self.error = "IP detection failed: \(error.localizedDescription)"
            return
        }

        firewalls = await firewallService.getStatus(
            managedFirewalls: enabledFirewalls,
            currentIP: currentIP
        )
        lastRefresh = Date()
    }

    func openFirewall(_ managed: ManagedFirewall) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            currentIP = try await ipDetector.detectIP()
            let label = CivoAccessLabel.make(firewallName: managed.name)
            try await firewallService.openAccess(
                firewallId: managed.id,
                port: managed.port,
                ip: currentIP,
                label: label,
                region: managed.region
            )
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    func closeFirewall(_ status: FirewallStatus) async {
        guard !isLoading, let ruleId = status.ruleId else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await firewallService.closeAccess(firewallId: status.managed.id, ruleId: ruleId, region: status.managed.region)
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
            currentIP = try await ipDetector.detectIP()

            for managed in enabledFirewalls {
                let existing = firewalls.first { $0.id == managed.id }
                if existing?.isOpen != true {
                    let label = CivoAccessLabel.make(firewallName: managed.name)
                    try await firewallService.openAccess(
                        firewallId: managed.id,
                        port: managed.port,
                        ip: currentIP,
                        label: label,
                        region: managed.region
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
            let result = try await firewallService.closeAllManagedRules(managedFirewalls: enabledFirewalls)
            if result.failed > 0 {
                self.error = "Failed to remove \(result.failed) rule\(result.failed == 1 ? "" : "s")"
            }
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()
    }

    private func forceRefresh() async {
        error = nil

        if currentIP == "..." {
            do {
                currentIP = try await ipDetector.detectIP()
            } catch {
                self.error = "IP detection failed: \(error.localizedDescription)"
                return
            }
        }

        firewalls = await firewallService.getStatus(
            managedFirewalls: enabledFirewalls,
            currentIP: currentIP
        )
        lastRefresh = Date()
    }

    // MARK: - Auto-refresh

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshTask?.cancel()
                self?.refreshTask = Task {
                    await self?.refresh()
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        refreshTask?.cancel()
        refreshTask = nil
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
}
