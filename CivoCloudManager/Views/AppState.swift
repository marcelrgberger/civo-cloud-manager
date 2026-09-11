import ServiceManagement
import SwiftUI

struct FirewallClosureJob: Codable, Sendable, Identifiable {
    let id: UUID
    let firewallId: String
    let ruleId: String
    let region: String
    let closeAt: Date
    var failures: Int?
    var nextAttempt: Date?
    var failureMessage: String?
}

/// Persists deadlines independently of popovers and retries until deletion is confirmed.
@Observable
@MainActor
final class FirewallClosureQueue {
    private(set) var jobs: [FirewallClosureJob] = []
    private(set) var lastError: String?
    private var processing = false
    private let file: URL
    private var loadFailed = false
    private var needsPersistence = false

    init(file: URL? = nil) {
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CivoCloudManager/firewall-closures.json")
        if FileManager.default.fileExists(atPath: self.file.path) {
            do { jobs = try JSONDecoder().decode([FirewallClosureJob].self, from: Data(contentsOf: self.file)) }
            catch {
                loadFailed = true
                lastError = "\(error.localizedDescription) — \(self.file.path)"
            }
        }
    }

    func schedule(firewallId: String, ruleId: String, region: String, closeAt: Date) throws {
        guard !region.isEmpty else { throw CivoAPIError.noRegion }
        guard !loadFailed else { throw CivoAPIError.networkError("Unable to read saved firewall deadlines") }
        let job = FirewallClosureJob(id: UUID(), firewallId: firewallId, ruleId: ruleId, region: region, closeAt: closeAt)
        jobs.append(job)
        do { try persist(jobs) }
        catch {
            // Retain the in-memory job so a failed rollback can still be retried during this run.
            lastError = error.localizedDescription
            needsPersistence = true
            throw error
        }
    }

    func prepare() throws {
        guard !loadFailed else { throw CivoAPIError.networkError("Unable to read saved firewall deadlines") }
        try persist(jobs)
    }

    func retryFailures() {
        if loadFailed {
            do {
                jobs = try JSONDecoder().decode([FirewallClosureJob].self, from: Data(contentsOf: file))
                loadFailed = false
            } catch {
                lastError = "\(error.localizedDescription) — \(file.path)"
                return
            }
        }
        for index in jobs.indices {
            jobs[index].failures = nil
            jobs[index].nextAttempt = nil
            jobs[index].failureMessage = nil
        }
        needsPersistence = true
        lastError = nil
    }

    func closeDue(now: Date = Date(), close: (FirewallClosureJob) async throws -> Void) async {
        guard !processing else { return }
        processing = true
        defer { processing = false }
        var failure: String?
        for job in jobs where job.closeAt <= now && (job.nextAttempt ?? .distantPast) <= now && (job.failures ?? 0) < 8 {
            do {
                do { try await close(job) }
                catch CivoAPIError.httpError(404, _) { /* Already deleted. */ }
                jobs.removeAll { $0.id == job.id }
                needsPersistence = true
            } catch {
                if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                    let count = (jobs[index].failures ?? 0) + 1
                    jobs[index].failures = count
                    jobs[index].nextAttempt = now.addingTimeInterval(min(3600, 30 * pow(2, Double(count - 1))))
                    jobs[index].failureMessage = "\(job.region)/\(job.firewallId): \(error.localizedDescription)"
                    needsPersistence = true
                }
            }
        }
        if needsPersistence && !loadFailed {
            do { try persist(jobs); needsPersistence = false }
            catch { failure = "\(error.localizedDescription) — \(file.path)" }
        }
        if !loadFailed { lastError = failure ?? jobs.compactMap(\.failureMessage).first }
    }

    private func persist(_ jobs: [FirewallClosureJob]) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(jobs).write(to: file, options: .atomic)
    }
}

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

    let firewallClosures: FirewallClosureQueue
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
        if error != nil || firewallClosures.lastError != nil { return .red }
        if anyOpen { return .yellow }
        return .green
    }

    var statusText: String {
        if setupState == .needsAPIKey { return "API key not configured" }
        if setupState == .needsRegion { return "No region selected" }
        if setupState == .needsFirewallSelection { return "Setup required" }
        if isLoading { return "Loading..." }
        if let error { return "Error: \(error)" }
        if let failure = firewallClosures.lastError { return "Error: \(failure)" }
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
        self.firewallClosures = FirewallClosureQueue()
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
        if !firewallClosures.jobs.isEmpty { startAutoCloseTimer() }
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
            guard !managed.region.isEmpty else { throw CivoAPIError.noRegion }
            try firewallClosures.prepare()
            currentIP = try await ipDetector.detectIP()
            let label = CivoAccessLabel.make(firewallName: managed.name)
            let rule = try await firewallService.openAccess(
                firewallId: managed.id,
                port: managed.port,
                ip: currentIP,
                label: label,
                region: managed.region
            )
            do {
                try firewallClosures.schedule(firewallId: managed.id, ruleId: rule.id, region: managed.region,
                                              closeAt: Date().addingTimeInterval(Double(minutes * 60)))
            } catch {
                // If the deadline cannot be persisted, roll back the newly opened access.
                startAutoCloseTimer()
                try await firewallService.closeAccess(firewallId: managed.id, ruleId: rule.id, region: managed.region)
                throw error
            }
            startAutoCloseTimer()
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

        await forceRefresh()

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
        let count = firewallClosures.jobs.count
        await firewallClosures.closeDue { [firewallService] job in
            try await firewallService.closeAccess(firewallId: job.firewallId, ruleId: job.ruleId, region: job.region)
        }
        if firewallClosures.jobs.count != count { await forceRefresh() }
        if firewallClosures.jobs.isEmpty && firewallClosures.lastError == nil {
            autoCloseTimer?.invalidate()
            autoCloseTimer = nil
        }
    }

    /// Returns the remaining minutes for an auto-close timer, if any, for the given firewall status.
    func remainingMinutes(for status: FirewallStatus) -> Int? {
        guard let ruleId = status.ruleId else { return nil }
        guard let closeTime = firewallClosures.jobs.first(where: {
            $0.firewallId == status.managed.id && $0.ruleId == ruleId && $0.region == status.managed.region
        })?.closeAt else { return nil }
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

        if enabledFirewalls.isEmpty && !onboardingComplete {
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
        setupState = .ready
        Task { await initialLoad() }
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
            await forceRefresh()
            if result.failed > 0 {
                self.error = "Failed to remove \(result.failed) rule\(result.failed == 1 ? "" : "s")"
            }
            if !result.listErrors.isEmpty {
                self.error = ([self.error].compactMap { $0 } + result.listErrors).joined(separator: "\n")
            }
            try? await Task.sleep(for: .seconds(1))
        } catch {
            self.error = error.localizedDescription
            return
        }

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
