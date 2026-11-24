import Foundation

/// Why an instance action was refused before anything was sent.
enum InstanceTargetError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case instanceMissing
    case firewallUnavailable
    case volumeUnavailable
    case volumeNotAttached

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
        case .volumeUnavailable:
            String(localized: "The selected volume is no longer free in the network of this instance, so nothing was sent.")
        case .volumeNotAttached:
            String(localized: "The volume is no longer attached to this instance, so nothing was sent.")
        }
    }
}

/// Why a resize was refused before anything was sent.
enum InstanceResizeError: Error, Equatable {
    case notRunning
    case sizeNotEligible

    var message: String {
        switch self {
        case .notRunning:
            String(localized: "This app resizes only running instances. Nothing was sent.")
        case .sizeNotEligible:
            String(localized: "The selected size is no longer available as a larger size for this instance. Nothing was sent.")
        }
    }
}

/// Sizes loaded for the resize sheet, with the region Civo listed them for.
enum ResizeSizes: Equatable {
    case loading
    case loaded([CivoSize], region: String)
    case failed(String)
}

/// What a confirmed instance deletion did.
enum InstanceDeletionOutcome: Equatable {
    /// Civo confirmed that this request deleted the instance.
    case deleted
    /// Civo no longer knew the instance and the complete list of its region no longer shows it.
    case alreadyGone
    /// Nothing is known to be deleted; the reason is in `error`.
    case failed
}

/// An instance action waiting for the user's confirmation, with the target captured when it was started.
struct PendingInstanceAction: Equatable {
    enum Kind: Equatable {
        case resize, delete, firewall, removeAllTags, attachVolume
        case power(InstancePowerAction)
        case recovery(InstanceRecoveryChange)
        case detachVolume(id: String, name: String)
    }

    let kind: Kind
    let target: ConsoleTarget
    /// Tells two confirmations of the same kind and target apart, such as a resize sheet closed and opened again.
    let id = UUID()
}

/// Why the recovery mode status of an instance could not be read.
struct InstanceRecoveryStatusFailure: Error, Equatable {
    let message: String
}

/// Recovery mode changes Civo accepted that still wait for a reboot, kept across app restarts: until the
/// reboot, Civo's status shows the new setting while the instance still runs the old one.
/// Holds only instance IDs, names and regions.
@MainActor
struct RecoveryRebootStore {
    let read: () -> Data?
    let write: (Data) -> Void

    private static let key = "CivoRecoveryChangesAwaitingReboot"
    static let standard = RecoveryRebootStore(
        read: { AppEnvironment.defaults.data(forKey: key) },
        write: { AppEnvironment.defaults.set($0, forKey: key) }
    )

    private struct Entry: Codable {
        let target: ConsoleTarget
        let change: InstanceRecoveryChange
    }

    func load() -> [ConsoleTarget: InstanceRecoveryChange] {
        guard let data = read(), let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [:] }
        return Dictionary(entries.map { ($0.target, $0.change) }, uniquingKeysWith: { _, last in last })
    }

    func save(_ changes: [ConsoleTarget: InstanceRecoveryChange]) {
        let entries = changes.map { Entry(target: $0.key, change: $0.value) }
        if let data = try? JSONEncoder().encode(entries) { write(data) }
    }
}

/// A detach the user confirmed after being told to unmount the volume. Only `confirmDetach()` creates one.
struct ConfirmedVolumeDetach {
    let volumeId: String
    let target: ConsoleTarget

    fileprivate init(volumeId: String, target: ConsoleTarget) {
        self.volumeId = volumeId
        self.target = target
    }
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
    private(set) var pendingAction: PendingInstanceAction? {
        didSet {
            guard oldValue?.id != pendingAction?.id else { return }
            // A size load of the previous confirmation must not publish into this one. The sizes stay while
            // nothing is pending, because a confirmed resize checks its size against them.
            resizeSizesLoadID = nil
            if pendingAction?.kind == .resize { resizeSizes = .loading }
        }
    }
    var isCreatingInstance = false
    var isCreatingSSHKey = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

    var availableNetworks: [CivoNetwork] = []
    var availableFirewalls: [CivoFirewall] = []
    var availableSizes: [CivoSize] = []
    var availableDiskImages: [CivoDiskImage] = []
    /// Loaded by the resize sheet itself, independent of the Create form.
    private(set) var resizeSizes = ResizeSizes.loading
    /// The newest size load of the current resize confirmation; only its result is published.
    private var resizeSizesLoadID: UUID?
    /// nil until loaded or when loading failed; then only one instance can be created at a time.
    private(set) var creationQuota: CivoQuota?
    /// Where to find the initial password of the instances just created. Never contains the password.
    var creationNotice: String?
    /// Firewalls and networks of the region the shown instance was listed from.
    private(set) var firewallOptions: InstanceFirewallOptions?
    /// Why the last loading of `firewallOptions` failed, nil while it succeeded or is running.
    private(set) var firewallOptionsError: String?
    /// Volumes and networks of the region the shown instance was listed from.
    private(set) var volumeOptions: InstanceVolumeOptions?
    /// Why the last loading of `volumeOptions` failed, nil while it succeeded or is running.
    private(set) var volumeOptionsError: String?
    /// The recovery mode status Civo last reported per instance, or why it could not be read.
    private var recoveryStatuses: [ConsoleTarget: Result<Bool, InstanceRecoveryStatusFailure>] = [:]
    /// The recovery mode setting Civo last reported or accepted per instance. Outlasts a failed status load, so
    /// Exit and the console notice stay while recovery mode was last known to be on, also after the reboot.
    private var knownRecoveryModes: [ConsoleTarget: Bool] = [:]
    /// Recovery mode changes Civo accepted that no reboot sent from this app has applied yet.
    private var recoveryChangesAwaitingReboot: [ConsoleTarget: InstanceRecoveryChange] {
        didSet { recoveryReboots.save(recoveryChangesAwaitingReboot) }
    }

    private let sshKeyService = CivoSSHKeyService()
    private let networkService = CivoNetworkService()
    private let firewallService = CivoFirewallService()
    private let sizeService = CivoSizeService()
    private let quotaService = CivoQuotaService()
    private let credentials: InstanceCredentialStore
    private let api: any InstanceAPI
    private let volumes: any InstanceVolumeAPI
    private let loadSSHKeys: @Sendable () async throws -> [CivoSSHKey]
    private let loadSizes: @Sendable (_ region: String) async throws -> [CivoSize]
    private let loadFirewallOptions: @Sendable (_ region: String) async throws -> InstanceFirewallOptions
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (_ action: String, _ detail: String?, ConsoleTarget) -> Void
    /// Why a confirmation was closed. Survives the next refresh, which a region change starts right away.
    @ObservationIgnored private var cancellationNotice: String?
    /// Counts volume list loads, so only the latest one is shown.
    @ObservationIgnored private var volumeLoads = 0
    /// Counts recovery mode status loads per instance, so only the latest one is shown.
    @ObservationIgnored private var recoveryLoads: [ConsoleTarget: Int] = [:]
    /// Counts accepted recovery mode changes, so a reboot clears only the change that existed when it was sent.
    @ObservationIgnored private var recoveryChangeCount = 0
    @ObservationIgnored private var recoveryChangeNumbers: [ConsoleTarget: Int] = [:]
    private let recoveryReboots: RecoveryRebootStore
    @ObservationIgnored nonisolated(unsafe) private var regionObserver: NSObjectProtocol?

    init(
        credentials: InstanceCredentialStore? = nil,
        api: any InstanceAPI = CivoInstanceService(),
        volumes: any InstanceVolumeAPI = CivoVolumeService(),
        recoveryReboots: RecoveryRebootStore = .standard,
        loadSSHKeys: (@Sendable () async throws -> [CivoSSHKey])? = nil,
        loadSizes: (@Sendable (_ region: String) async throws -> [CivoSize])? = nil,
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
        self.volumes = volumes
        self.recoveryReboots = recoveryReboots
        recoveryChangesAwaitingReboot = recoveryReboots.load()
        let sshKeyService = CivoSSHKeyService()
        self.loadSSHKeys = loadSSHKeys ?? { try await sshKeyService.listSSHKeys() }
        let sizeService = CivoSizeService()
        self.loadSizes = loadSizes ?? { region in try await sizeService.listSizes(region: region) }
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
        // Captured before sending: a change accepted while the reboot is on its way still needs another one.
        let changeBeforeReboot = recoveryChangeNumbers[target]
        await perform(Self.activity(for: action), on: target, onAccepted: {
            // Civo documents a reboot, not a stop and start, as what applies a recovery mode change.
            if action == .softReboot || action == .hardReboot,
               recoveryChangeNumbers[target] == changeBeforeReboot {
                recoveryChangesAwaitingReboot[target] = nil
            }
        }) {
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

    // MARK: - Volumes

    /// The volumes loaded for the region `instance` was listed from, nil until they are loaded.
    func volumeOptions(for instance: CivoInstance) -> InstanceVolumeOptions? {
        guard let options = volumeOptions, let target = consoleTarget(for: instance),
              Self.isSameRegion(options.region, target.region) else { return nil }
        return options
    }

    /// Loads the volumes and networks of the region `instance` was listed from.
    func loadVolumeOptions(for instance: CivoInstance) async {
        guard let target = consoleTarget(for: instance) else { return }
        await loadVolumeOptions(region: target.region)
    }

    /// Skipped for a region other than the Settings region, such as the reload after a request that was
    /// sent before a region change: its list would outdate the current region's load.
    private func loadVolumeOptions(region: String) async {
        guard Self.isSameRegion(region, settingsRegion()) else { return }
        _ = try? await fetchVolumeOptions(region: region)
    }

    /// Loads the volumes of `region` and shows them, unless a later load started or the Settings region
    /// changed meanwhile: an older answer must not replace a newer list or the list of another region.
    private func fetchVolumeOptions(region: String) async throws -> InstanceVolumeOptions {
        volumeLoads += 1
        let load = volumeLoads
        func isCurrent() -> Bool { load == volumeLoads && Self.isSameRegion(region, settingsRegion()) }
        do {
            let options = try await volumes.volumeOptions(region: region)
            if isCurrent() {
                volumeOptions = options
                volumeOptionsError = nil
            }
            return options
        } catch {
            if isCurrent() { volumeOptionsError = CivoAPIError.userMessage(error) }
            throw error
        }
    }

    /// Attaches `volumeId` to the instance. The volumes are loaded again first, so a volume that was attached
    /// meanwhile or is not in the instance's network and region is refused without a request.
    func attachVolume(_ volumeId: String, to target: ConsoleTarget) async {
        guard let volume = await currentVolume(volumeId, of: target, among: { $0.attachable(to: $1) },
                                               otherwise: .volumeUnavailable) else { return }
        await sendVolumeRequest("Attached volume %@", volume: volume, on: target) {
            try await $0.attachVolume(volume.id, to: target.instanceId, region: target.region)
        }
    }

    /// Closes the detach confirmation opened with `beginConfirmation(.detachVolume(id:name:), for:)`.
    /// nil while no detach confirmation is open, so a detach cannot be sent without it.
    func confirmDetach() -> ConfirmedVolumeDetach? {
        guard let pending = pendingAction, case .detachVolume(let volumeId, _) = pending.kind else { return nil }
        pendingAction = nil
        return ConfirmedVolumeDetach(volumeId: volumeId, target: pending.target)
    }

    /// Detaches the confirmed volume, only if it is still attached to the instance.
    func detachVolume(_ confirmed: ConfirmedVolumeDetach) async {
        let target = confirmed.target
        guard let volume = await currentVolume(confirmed.volumeId, of: target, among: { $0.attached(to: $1) },
                                               otherwise: .volumeNotAttached) else { return }
        await sendVolumeRequest("Detached volume %@", volume: volume, on: target) {
            try await $0.detachVolume(volume.id, region: target.region)
        }
    }

    /// The volume as Civo lists it right now, if the target is still valid and `among` still offers it.
    private func currentVolume(
        _ volumeId: String,
        of target: ConsoleTarget,
        among offered: (InstanceVolumeOptions, CivoInstance) -> [CivoVolume],
        otherwise refusal: InstanceTargetError
    ) async -> CivoVolume? {
        if let problem = targetError(for: target) {
            error = problem.message
            return nil
        }
        let options: InstanceVolumeOptions
        do {
            options = try await fetchVolumeOptions(region: target.region)
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return nil
        }
        if let problem = targetError(for: target) {
            error = problem.message
            return nil
        }
        guard let instance = instances.first(where: { $0.id == target.instanceId }),
              let volume = offered(options, instance).first(where: { $0.id == volumeId }) else {
            error = refusal.message
            return nil
        }
        return volume
    }

    /// Sends one volume request and reloads the volumes either way, so the page shows what Civo reports.
    /// Errors such as a volume attached elsewhere in the meantime are shown as Civo returns them.
    private func sendVolumeRequest(
        _ activity: String,
        volume: CivoVolume,
        on target: ConsoleTarget,
        _ request: (any InstanceVolumeAPI) async throws -> Void
    ) async {
        do {
            try await request(volumes)
            error = nil
            showSuccess = true
            recordActivity(activity, volume.name, target)
        } catch {
            self.error = CivoAPIError.userMessage(error)
        }
        await loadVolumeOptions(region: target.region)
    }

    // MARK: - Recovery mode

    /// Whether recovery mode is on for `instance` as Civo last reported it, nil until it is read.
    func recoveryMode(for instance: CivoInstance) -> Bool? {
        guard case .success(let isEnabled) = recoveryStatus(for: instance) else { return nil }
        return isEnabled
    }

    /// Why the recovery mode status of `instance` could not be read, nil while it was read or is loading.
    func recoveryStatusError(for instance: CivoInstance) -> String? {
        guard case .failure(let failure) = recoveryStatus(for: instance) else { return nil }
        return failure.message
    }

    /// The recovery mode change Civo accepted for `instance` that still waits for a reboot.
    func recoveryChangeAwaitingReboot(for instance: CivoInstance) -> InstanceRecoveryChange? {
        consoleTarget(for: instance).flatMap { recoveryChangesAwaitingReboot[$0] }
    }

    /// Exit while recovery mode is on, Enter while it is off. While the status cannot be read, the setting last
    /// known decides, so Exit stays offered after entering, also after the reboot or once Full Access is gone.
    /// After an app restart, before Civo answered, the change still waiting for a reboot decides.
    func offeredRecoveryChange(for instance: CivoInstance) -> InstanceRecoveryChange? {
        let knownMode = consoleTarget(for: instance).flatMap { knownRecoveryModes[$0] }
        guard let isOn = knownMode ?? recoveryChangeAwaitingReboot(for: instance).map({ $0 == .enter })
        else { return nil }
        return isOn ? .exit : .enter
    }

    private func recoveryStatus(for instance: CivoInstance) -> Result<Bool, InstanceRecoveryStatusFailure>? {
        consoleTarget(for: instance).flatMap { recoveryStatuses[$0] }
    }

    /// Loads the recovery mode status of `instance` from the region it was listed from.
    func loadRecoveryStatus(for instance: CivoInstance) async {
        guard let target = consoleTarget(for: instance) else { return }
        await loadRecoveryStatus(of: target)
    }

    /// Shows the answer unless a later load started or the Settings region changed meanwhile.
    private func loadRecoveryStatus(of target: ConsoleTarget) async {
        guard Self.isSameRegion(target.region, settingsRegion()) else { return }
        let load = (recoveryLoads[target] ?? 0) + 1
        recoveryLoads[target] = load
        let status: Result<Bool, InstanceRecoveryStatusFailure>
        do {
            status = .success(try await api.recoveryStatus(of: target.instanceId, region: target.region).isEnabled)
        } catch CivoAPIError.decodingError {
            status = .failure(.init(message: Self.unreadableRecoveryStatusMessage))
        } catch {
            // A load cancelled by leaving the page is not a failure; the next load replaces it.
            guard let message = CivoAPIError.userMessage(error) else { return }
            status = .failure(.init(message: message))
        }
        guard load == recoveryLoads[target], Self.isSameRegion(target.region, settingsRegion()) else { return }
        recoveryStatuses[target] = status
        if case .success(let isEnabled) = status { knownRecoveryModes[target] = isEnabled }
    }

    static var unreadableRecoveryStatusMessage: String {
        String(localized: "Civo reported the recovery mode status in an unexpected form, so it is unknown.")
    }

    /// Turns recovery mode on or off after the confirmation opened with `beginConfirmation(.recovery(_:), for:)`.
    /// The change then waits for a reboot, which the detail page offers until one is sent from this app.
    /// It is saved as soon as Civo accepts it, so quitting during the following reload does not lose the warning.
    func changeRecovery(_ change: InstanceRecoveryChange, of target: ConsoleTarget) async {
        let activity = change == .enter ? "Entered recovery mode" : "Exited recovery mode"
        let changed = await perform(activity, on: target, onAccepted: {
            recoveryChangeCount += 1
            recoveryChangeNumbers[target] = recoveryChangeCount
            recoveryChangesAwaitingReboot[target] = change
            knownRecoveryModes[target] = change == .enter
            // A status load sent before the change would report the old setting.
            recoveryLoads[target, default: 0] += 1
        }) {
            try await $0.changeRecovery(change, of: target.instanceId, region: target.region)
        }
        guard changed else { return }
        await loadRecoveryStatus(of: target)
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

    /// Loads the sizes of the region captured for the pending resize, so neither the Create form nor a
    /// later Settings region decides what the sheet offers.
    /// A load that finishes after its sheet was closed, or after a newer load was started, publishes nothing,
    /// whether or not it was cancelled.
    func loadResizeSizes() async {
        guard let pending = pendingAction, pending.kind == .resize else { return }
        let region = pending.target.region
        let loadID = UUID()
        resizeSizesLoadID = loadID
        resizeSizes = .loading
        let result: ResizeSizes
        do {
            result = .loaded(try await loadSizes(region), region: region)
        } catch {
            // nil for a cancelled load: the sheet was closed.
            guard let message = CivoAPIError.userMessage(error) else { return }
            result = .failed(message)
        }
        guard pendingAction?.id == pending.id, resizeSizesLoadID == loadID else { return }
        resizeSizes = result
    }

    /// Lists the instances again, then their sizes, for a sheet that could not compare sizes. Loads no sizes
    /// if the sheet was closed or opened again during the refresh.
    func reloadResizeComparison() async {
        guard let pending = pendingAction, pending.kind == .resize else { return }
        await refresh()
        guard pendingAction?.id == pending.id else { return }
        await loadResizeSizes()
    }

    /// What the listed instance of `target` may be resized to, only from sizes loaded for the target's region.
    /// nil while no such sizes are loaded or the instance is no longer listed.
    func resizeOptions(for target: ConsoleTarget) -> ResizeOptions? {
        guard case .loaded(let sizes, let region) = resizeSizes, region == target.region,
              let instance = instances.first(where: { $0.id == target.instanceId }) else { return nil }
        return InstanceResize.options(sizes, for: instance)
    }

    /// After the target checks, checks the status and size again on the current list, so an instance that
    /// stopped or changed size while the sheet was open is not resized.
    func resizeInstance(_ target: ConsoleTarget, size: String) async {
        if targetError(for: target) == nil, let problem = resizeError(for: target, size: size) {
            error = problem.message
            return
        }
        await perform("Resized to \(size)", on: target) {
            try await $0.resizeInstance(target.instanceId, size: size, region: target.region)
        }
    }

    private func resizeError(for target: ConsoleTarget, size: String) -> InstanceResizeError? {
        guard let instance = instances.first(where: { $0.id == target.instanceId }) else { return nil }
        guard InstanceResize.isAllowed(status: instance.status) else { return .notRunning }
        guard resizeOptions(for: target)?.sizes.contains(where: { $0.name == size }) == true else { return .sizeNotEligible }
        return nil
    }

    /// Sends one request for `target`, only if the target is still valid at this moment. Returns whether it succeeded.
    /// `onAccepted` runs as soon as Civo accepted the request, before the instances are reloaded.
    @discardableResult
    private func perform(
        _ activity: String,
        detail: String? = nil,
        on target: ConsoleTarget,
        onAccepted: () -> Void = {},
        _ request: (any InstanceAPI) async throws -> Void
    ) async -> Bool {
        if let problem = targetError(for: target) {
            error = problem.message
            return false
        }
        do {
            try await request(api)
            onAccepted()
            showSuccess = true
            recordActivity(activity, detail, target)
            await refresh()
            return true
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return false
        }
    }

    /// Deletes the instance confirmed in `DeleteConfirmationSheet`. Only a deletion this request made is
    /// logged and shown as a success; the detail page of the instance closes once it is gone.
    @discardableResult
    func removeInstance(_ target: ConsoleTarget) async -> InstanceDeletionOutcome {
        let outcome = await delete(target)
        switch outcome {
        case .failed:
            return outcome
        case .deleted:
            showSuccess = true
            recordActivity("Deleted", nil, target)
        case .alreadyGone:
            break
        }
        if selectedInstance?.id == target.instanceId { selectedInstance = nil }
        recoveryChangesAwaitingReboot[target] = nil
        // Refreshing replaces `error`; the notice and a warning about leftover credentials must stay visible.
        let warning = error
        await refresh()
        if let warning { error = [warning, error].compactMap { $0 }.joined(separator: " ") }
        return outcome
    }

    /// Deletes the instance and, only once it is confirmed gone, its saved credentials.
    /// A failed or refused deletion keeps them and leaves the reason in `error`.
    private func delete(_ target: ConsoleTarget) async -> InstanceDeletionOutcome {
        error = nil
        if let problem = targetError(for: target) {
            error = problem.message
            return .failed
        }
        let outcome: InstanceDeletionOutcome
        do {
            try await api.removeInstance(target.instanceId, region: target.region)
            outcome = .deleted
        } catch CivoAPIError.httpError(404, let message) {
            guard await isConfirmedGone(target) else {
                error = CivoAPIError.httpError(404, message).localizedDescription
                return .failed
            }
            outcome = .alreadyGone
        } catch {
            self.error = CivoAPIError.userMessage(error)
            return .failed
        }
        do {
            try credentials.delete(InstanceCredentialKey(target))
        } catch {
            let credentialError = error as? InstanceCredentialError ?? .unreadableEntry
            Log.error("Instance credentials not removed after instance deletion: \(credentialError.logDescription)")
            self.error = String(localized: "The instance was deleted, but its saved credentials could not be removed.")
        }
        if outcome == .alreadyGone {
            error = [Self.alreadyDeletedMessage, error].compactMap { $0 }.joined(separator: " ")
        }
        return outcome
    }

    /// Whether a complete list of the target's region, loaded for this check only, no longer shows the
    /// instance while the target is still valid. A failed or incomplete load proves nothing.
    private func isConfirmedGone(_ target: ConsoleTarget) async -> Bool {
        guard let list = try? await api.listInstances(region: target.region) else { return false }
        return isAccessAllowed()
            && Self.isSameRegion(target.region, settingsRegion())
            && list.isComplete
            && !list.items.contains(where: { $0.id == target.instanceId })
    }

    static var alreadyDeletedMessage: String {
        String(localized: "The instance had already been deleted, so this request deleted nothing.")
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
