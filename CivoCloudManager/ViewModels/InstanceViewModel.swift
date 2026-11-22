import Foundation

/// Why an instance action was refused before anything was sent.
enum InstanceTargetError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case instanceMissing
    case firewallUnavailable

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Instance actions require Full Access.")
        case .noRegion:
            String(localized: "The region of this instance is unknown. Reload the list and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the instance action was cancelled. Nothing was sent.")
        case .instanceMissing:
            String(localized: "The instance is no longer in the list, so nothing was sent.")
        case .firewallUnavailable:
            String(localized: "The selected firewall is no longer in the network of this instance, so nothing was sent.")
        }
    }
}

/// An instance action waiting for the user's confirmation, with the target captured when it was started.
struct PendingInstanceAction: Equatable {
    enum Kind: Equatable {
        case resize, delete, firewall, removeAllTags
        case power(InstancePowerAction)
    }

    let kind: Kind
    let target: ConsoleTarget
}

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
    /// Dropped with a message as soon as its target is no longer valid.
    private(set) var pendingAction: PendingInstanceAction?
    var isCreatingInstance = false
    var isCreatingSSHKey = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []
    var availableFirewalls: [CivoFirewall] = []
    var availableSizes: [CivoSize] = []
    var availableDiskImages: [CivoDiskImage] = []
    /// nil until loaded or when loading failed; then only one instance can be created at a time.
    private(set) var creationQuota: CivoQuota?
    /// Where to find the initial password of the instances just created. Never contains the password.
    var creationNotice: String?
    /// Firewalls and networks of the region the shown instance was listed from.
    private(set) var firewallOptions: InstanceFirewallOptions?
    /// Why the last loading of `firewallOptions` failed, nil while it succeeded or is running.
    private(set) var firewallOptionsError: String?

    private let sshKeyService = CivoSSHKeyService()
    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let sizeService = CivoSizeService()
    private let volumeService = CivoVolumeService()
    private let quotaService = CivoQuotaService()
    private let credentials: InstanceCredentialStore
    private let api: any InstanceAPI
    private let loadSSHKeys: @Sendable () async throws -> [CivoSSHKey]
    private let loadFirewallOptions: @Sendable (_ region: String) async throws -> InstanceFirewallOptions
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (_ action: String, _ detail: String?, ConsoleTarget) -> Void
    /// Why a confirmation was closed. Survives the next refresh, which a region change starts right away.
    @ObservationIgnored private var cancellationNotice: String?
    @ObservationIgnored nonisolated(unsafe) private var regionObserver: NSObjectProtocol?

    init(
        credentials: InstanceCredentialStore? = nil,
        api: any InstanceAPI = CivoInstanceService(),
        loadSSHKeys: (@Sendable () async throws -> [CivoSSHKey])? = nil,
        loadFirewallOptions: (@Sendable (_ region: String) async throws -> InstanceFirewallOptions)? = nil,
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (_ action: String, _ detail: String?, ConsoleTarget) -> Void = { action, detail, target in
            ActivityLog.shared.log(action, detail: detail, resourceType: "Instance", resourceName: target.instanceName, resourceId: target.instanceId)
        }
    ) {
        self.credentials = credentials ?? .shared
        self.api = api
        let sshKeyService = CivoSSHKeyService()
        self.loadSSHKeys = loadSSHKeys ?? { try await sshKeyService.listSSHKeys() }
        let firewallService = CivoFirewallService()
        let networkService = CivoNetworkService()
        self.loadFirewallOptions = loadFirewallOptions ?? { region in
            async let firewalls = firewallService.listFirewalls(region: region)
            async let networks = networkService.listNetworks(region: region)
            return try await InstanceFirewallOptions(region: region, firewalls: firewalls, networks: networks)
        }
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.notificationCenter = notificationCenter
        self.recordActivity = recordActivity
        regionObserver = notificationCenter.addObserver(forName: .civoRegionDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.settingsRegionDidChange() }
        }
    }

    deinit {
        regionObserver.map(notificationCenter.removeObserver)
    }

    func refresh() async {
        isLoading = true
        error = cancellationNotice
        cancellationNotice = nil
        defer { isLoading = false }

        do {
            let region = settingsRegion()
            async let insts = api.listInstances(region: region.isEmpty ? nil : region)
            async let keys = loadSSHKeys()

            let instanceList: PaginatedList<CivoInstance>
            do {
                instanceList = try await insts
            } catch {
                instanceCompleteness.update(after: error)
                throw error
            }
            // A region change while loading starts its own refresh; this list belongs to the old region.
            guard Self.isSameRegion(region, settingsRegion()) else { return }
            instances = instanceList.items
            instanceCompleteness.update(with: instanceList)
            instancesRegion = region
            updateSelection()
            dropInvalidPendingAction()
            sshKeys = try await keys
        } catch {
            self.error = CivoAPIError.userMessage(error)
            Log.error("Instance refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Targets

    /// Captures the instance with the region it was listed from, never a later Settings change.
    /// nil for an instance that is not in the current list or whose region is unknown.
    /// Every instance action, including the console, starts from this target.
    func consoleTarget(for instance: CivoInstance) -> ConsoleTarget? {
        guard instances.contains(where: { $0.id == instance.id }) else { return nil }
        let region = instance.region.flatMap { $0.isEmpty ? nil : $0 } ?? instancesRegion
        guard !region.isEmpty else { return nil }
        return ConsoleTarget(instanceId: instance.id, instanceName: instance.name, region: region)
    }

    /// Why a captured target may no longer be used, nil while it may. Checked again right before
    /// every request, so a confirmation that outlived a region change or a reload sends nothing.
    func targetError(for target: ConsoleTarget) -> InstanceTargetError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard Self.isSameRegion(target.region, settingsRegion()),
              Self.isSameRegion(target.region, instancesRegion) else { return .regionChanged }
        guard instances.contains(where: { $0.id == target.instanceId }) else { return .instanceMissing }
        return nil
    }

    /// Opens a confirmation for `instance` with its target captured now, unless that target is already invalid.
    func beginConfirmation(_ kind: PendingInstanceAction.Kind, for instance: CivoInstance) {
        guard let target = consoleTarget(for: instance) else {
            error = InstanceTargetError.noRegion.message
            return
        }
        if let problem = targetError(for: target) {
            error = problem.message
            return
        }
        pendingAction = PendingInstanceAction(kind: kind, target: target)
    }

    func cancelConfirmation() {
        pendingAction = nil
    }

    /// Closes the confirmation and returns its target. The action checks the target again.
    func confirmPendingAction() -> ConsoleTarget? {
        defer { pendingAction = nil }
        return pendingAction?.target
    }

    private func settingsRegionDidChange() {
        if let selected = selectedInstance,
           consoleTarget(for: selected).map({ !Self.isSameRegion($0.region, settingsRegion()) }) ?? true {
            selectedInstance = nil
        }
        dropInvalidPendingAction()
    }

    /// Keeps the selection on fresh data, or drops it once the instance is no longer listed.
    private func updateSelection() {
        guard let selected = selectedInstance else { return }
        if let updated = instances.first(where: { $0.id == selected.id }) {
            selectedInstance = updated
        } else {
            selectedInstance = nil
            error = InstanceTargetError.instanceMissing.message
        }
    }

    private func dropInvalidPendingAction() {
        guard let pending = pendingAction, let problem = targetError(for: pending.target) else { return }
        pendingAction = nil
        error = problem.message
        cancellationNotice = problem.message
    }

    private static func isSameRegion(_ lhs: String, _ rhs: String) -> Bool {
        lhs.caseInsensitiveCompare(rhs) == .orderedSame
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
        do {
            creationQuota = try await quotaService.getQuota()
        } catch {
            creationQuota = nil
            Log.error("Failed to load quota for instance creation: \(error.localizedDescription)")
        }
    }

    /// The most instances one Create may request for `form`, from the quota loaded with the form data.
    func maximumCreationCount(for form: InstanceCreationForm) -> Int {
        InstanceBulkCreation.maximumCount(quota: creationQuota, size: size(of: form), createsPublicIp: form.createsPublicIp)
    }

    /// How many instances of the form's size fit the remaining quota, nil while no quota is loaded.
    func creationCapacity(for form: InstanceCreationForm) -> Int? {
        InstanceBulkCreation.capacity(quota: creationQuota, size: size(of: form), createsPublicIp: form.createsPublicIp)
    }

    private func size(of form: InstanceCreationForm) -> CivoSize? {
        availableSizes.first { $0.name == form.size }
    }

    /// Sends the form. More than one instance is created only after `BulkCreationConfirmation` was confirmed.
    func createInstance(_ form: InstanceCreationForm) async -> Bool {
        guard let body = form.requestBody() else { return false }
        guard isAccessAllowed() else {
            saveError = InstanceTargetError.accessRevoked.message
            return false
        }
        guard form.count <= maximumCreationCount(for: form) else {
            saveError = String(localized: "The remaining quota does not allow this many instances. Lower the count.")
            return false
        }
        isSaving = true
        saveError = nil
        creationNotice = nil
        defer { isSaving = false }

        do {
            let response = try await api.createInstance(body)
            showCreatedInstances()
            showSuccess = true
            await refresh()
            if response.setsInitialPassword { creationNotice = Self.initialPasswordNotice }
            return true
        } catch CivoAPIError.decodingError {
            // Civo answered with success, so instances may have been created: show the list before a retry.
            showCreatedInstances()
            await refresh()
            error = String(localized: "Civo accepted the request, but its answer could not be read. Check the instance list before creating again.")
            if form.sshKeyId.isEmpty { creationNotice = Self.initialPasswordNotice }
            return true
        } catch {
            saveError = CivoAPIError.userMessage(error)
            return false
        }
    }

    /// Closes the form and returns to the list, where the new instances and the creation notice are shown.
    private func showCreatedInstances() {
        isCreatingInstance = false
        selectedInstance = nil
    }

    static var initialPasswordNotice: String {
        String(localized: "No SSH key was chosen, so Civo set an initial password. Open the instance: its detail page shows the password under Security after Touch ID or your system password.")
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

    func changePower(_ action: InstancePowerAction, of target: ConsoleTarget) async {
        await perform(Self.activity(for: action), on: target) {
            try await $0.changePower(action, of: target.instanceId, region: target.region)
        }
    }

    /// Stored in English; the activity log translates it when shown.
    private static func activity(for action: InstancePowerAction) -> String {
        switch action {
        case .start: "Started"
        case .stop: "Stopped"
        case .softReboot: "Soft rebooted"
        case .hardReboot: "Hard rebooted"
        }
    }

    // MARK: - Firewall

    /// The firewall options loaded for the region `instance` was listed from, nil until they are loaded.
    func firewallOptions(for instance: CivoInstance) -> InstanceFirewallOptions? {
        guard let options = firewallOptions, let target = consoleTarget(for: instance),
              Self.isSameRegion(options.region, target.region) else { return nil }
        return options
    }

    /// Loads the firewalls and networks of the region `instance` was listed from.
    func loadFirewallOptions(for instance: CivoInstance) async {
        guard let target = consoleTarget(for: instance) else { return }
        firewallOptionsError = nil
        do {
            firewallOptions = try await loadFirewallOptions(target.region)
        } catch {
            firewallOptionsError = CivoAPIError.userMessage(error)
        }
    }

    /// Switches the instance to `firewallId`. The firewall list is loaded again first, so a firewall that was
    /// deleted or is not in the instance's network is refused without a request.
    func setFirewall(_ firewallId: String, of target: ConsoleTarget) async {
        if let problem = targetError(for: target) {
            error = problem.message
            return
        }
        let options: InstanceFirewallOptions
        do {
            options = try await loadFirewallOptions(target.region)
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return
        }
        firewallOptions = options
        if let problem = targetError(for: target) {
            error = problem.message
            return
        }
        guard let instance = instances.first(where: { $0.id == target.instanceId }),
              let firewall = options.offered(for: instance).first(where: { $0.id == firewallId }) else {
            error = InstanceTargetError.firewallUnavailable.message
            return
        }
        do {
            try await api.setFirewall(target.instanceId, firewallId: firewall.id, region: target.region)
            showSuccess = true
            recordActivity("Firewall set to %@", firewall.name, target)
            await refresh()
        } catch CivoAPIError.decodingError {
            // Civo answered with success, so the change may have been made: show what the instance uses now.
            await refresh()
            error = [Self.unreadableFirewallChangeMessage, error].compactMap { $0 }.joined(separator: " ")
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
    }

    static var unreadableFirewallChangeMessage: String {
        String(localized: "Civo accepted the firewall change, but its answer could not be read. Check which firewall the instance uses now.")
    }

    // MARK: - Tags

    /// Replaces the tags with the comma-separated `input`. Input that is invalid or holds no tag sends
    /// nothing: only `removeAllTags(of:)` may clear the tags. Returns whether the tags were changed.
    func setTags(_ input: String, of target: ConsoleTarget) async -> Bool {
        let change: InstanceTagChange
        do {
            change = try InstanceTagChange.replacing(with: input)
        } catch {
            self.error = error.message
            return false
        }
        return await perform("Tags set to %@", detail: change.tags.joined(separator: ", "), on: target) {
            try await $0.setTags(target.instanceId, change, region: target.region)
        }
    }

    /// Removes every tag. Called only from the confirmation opened with `beginConfirmation(.removeAllTags, for:)`.
    func removeAllTags(of target: ConsoleTarget) async {
        await perform("Removed all tags", on: target) {
            try await $0.setTags(target.instanceId, .removeAll, region: target.region)
        }
    }

    func updateInstance(_ target: ConsoleTarget, reverseDns: String) async {
        await perform("Set Reverse DNS to \(reverseDns)", on: target) {
            try await $0.updateInstance(target.instanceId, body: ["reverse_dns": reverseDns], region: target.region)
        }
    }

    func resizeInstance(_ target: ConsoleTarget, size: String) async {
        await perform("Resized to \(size)", on: target) {
            try await $0.resizeInstance(target.instanceId, size: size, region: target.region)
        }
    }

    /// Sends one request for `target`, only if the target is still valid at this moment. Returns whether it succeeded.
    @discardableResult
    private func perform(
        _ activity: String,
        detail: String? = nil,
        on target: ConsoleTarget,
        _ request: (any InstanceAPI) async throws -> Void
    ) async -> Bool {
        if let problem = targetError(for: target) {
            error = problem.message
            return false
        }
        do {
            try await request(api)
            showSuccess = true
            recordActivity(activity, detail, target)
            await refresh()
            return true
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return false
        }
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

    func removeInstance(_ target: ConsoleTarget) async {
        guard await delete(target) else { return }
        // Refreshing clears `error`; a warning about leftover credentials must stay visible.
        let warning = error
        await refresh()
        if error == nil { error = warning }
    }

    /// Deletes the instance and, only once Civo confirmed the deletion, its saved credentials.
    /// A failed or refused deletion keeps them. Returns whether the instance was deleted.
    func delete(_ target: ConsoleTarget) async -> Bool {
        error = nil
        if let problem = targetError(for: target) {
            error = problem.message
            return false
        }
        do {
            try await api.removeInstance(target.instanceId, region: target.region)
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return false
        }
        do {
            try credentials.delete(InstanceCredentialKey(target))
        } catch {
            let credentialError = error as? InstanceCredentialError ?? .unreadableEntry
            Log.error("Instance credentials not removed after instance deletion: \(credentialError.logDescription)")
            self.error = String(localized: "The instance was deleted, but its saved credentials could not be removed.")
        }
        return true
    }

    /// Whether credentials may be saved for the instance, checked without authentication. A keychain
    /// error counts as "may be saved": only a confirmed missing entry rules it out.
    func mayHaveSavedCredentials(_ target: ConsoleTarget) -> Bool {
        (try? credentials.contains(InstanceCredentialKey(target))) != false
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
