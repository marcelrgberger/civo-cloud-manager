import Foundation

/// The reserved IPs of the account and region chosen in Settings, and the detail of the selected one.
/// Only the detail carries a verified assignment; the list is for finding an IP.
@Observable
@MainActor
final class ReservedIPViewModel {
    enum Detail: Equatable {
        case notLoaded
        case loading
        case loaded(CivoReservedIP)
        case failed(String)
    }

    /// The account and region the shown data was loaded with.
    struct Context: Equatable {
        let account: CivoAccount
        let region: String
    }

    private(set) var reservedIPs: [CivoReservedIP] = []
    private(set) var completeness = ListCompleteness()
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var context: Context?
    private(set) var selectedID: String?
    private(set) var detail = Detail.notLoaded
    let controller: ReservedIPController

    private let api: any ReservedIPAPI
    private let settingsRegion: @MainActor () -> String
    private let apiKey: @MainActor () -> String
    private let notificationCenter: NotificationCenter
    /// Only the newest load of each kind is shown, and a change of account or region invalidates both.
    @ObservationIgnored private var listLoad: UUID?
    @ObservationIgnored private var detailLoad: UUID?
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any ReservedIPAPI = CivoReservedIPService(),
        controller: ReservedIPController? = nil,
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        notificationCenter: NotificationCenter = .default
    ) {
        self.api = api
        self.controller = controller ?? ReservedIPController(api: api)
        self.settingsRegion = settingsRegion
        self.apiKey = apiKey
        self.notificationCenter = notificationCenter
        self.controller.reloadList = { [weak self] in await self?.refresh() ?? false }
        observers = [Notification.Name.civoAPIKeyDidChange, .civoRegionDidChange].map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.accountOrRegionDidChange() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    var selectedIP: CivoReservedIP? {
        reservedIPs.first { $0.id == selectedID }
    }

    // MARK: - Loading

    /// Loads the whole list for the account and region in Settings, then the selected IP again.
    /// Returns whether the complete list could be loaded.
    @discardableResult
    func refresh() async -> Bool {
        hasLoaded = true
        let key = apiKey()
        let region = settingsRegion()
        guard !key.isEmpty else { return fail(CivoAPIError.noAPIKey) }
        guard !region.isEmpty else { return fail(CivoAPIError.noRegion) }
        let load = UUID()
        listLoad = load
        isLoading = true
        error = nil
        do {
            let list = try await api.listReservedIPs(region: region, apiKey: key)
            guard listLoad == load else { return false }
            reservedIPs = list.items
            context = Context(account: CivoAccount(apiKey: key), region: region)
            completeness.update(with: list)
            isLoading = false
            if list.isComplete { controller.listDidLoad() }
        } catch {
            guard listLoad == load else { return false }
            isLoading = false
            completeness.update(after: error)
            self.error = CivoAPIError.userMessage(error)
            return false
        }
        if selectedIP == nil {
            select(nil)
        } else {
            await loadDetail()
        }
        // A change of account or region during the detail load invalidated this load, and its list is not shown.
        guard listLoad == load else { return false }
        return !completeness.mayBeMissingItems
    }

    func select(_ id: String?) {
        selectedID = id
        detailLoad = nil
        detail = .notLoaded
    }

    /// Loads the selected IP from Civo, which is where its assignment is verified.
    func loadDetail() async {
        guard let id = selectedID, let context else { return }
        let key = apiKey()
        guard CivoAccount(apiKey: key) == context.account else { return }
        let load = UUID()
        detailLoad = load
        detail = .loading
        do {
            let loaded = try await api.showReservedIP(id, region: context.region, apiKey: key)
            guard detailLoad == load else { return }
            detail = .loaded(loaded)
        } catch {
            guard detailLoad == load, !CivoAPIError.isCancelled(error) else { return }
            detail = .failed(CivoAPIError.userMessage(error) ?? ReservedIPError.assignmentUnknown.message)
        }
    }

    // MARK: - Actions

    /// Opens `operation` for the selected IP, or for a new one when reserving, once what it needs is loaded.
    func begin(_ operation: ReservedIPOperation) {
        guard let context else { return }
        var ip: CivoReservedIP?
        if operation != .reserve {
            guard case .loaded(let loaded) = detail else { return }
            ip = loaded
        }
        controller.begin(
            operation, ip: ip, region: context.region, account: context.account,
            listIsComplete: !completeness.mayBeMissingItems
        )
    }

    // MARK: - Private

    private func fail(_ error: CivoAPIError) -> Bool {
        reset()
        self.error = error.localizedDescription
        return false
    }

    /// Late answers of loads started for the previous account or region must not fill the new one.
    private func reset() {
        listLoad = nil
        detailLoad = nil
        reservedIPs = []
        context = nil
        completeness = ListCompleteness()
        isLoading = false
        error = nil
        select(nil)
    }

    private func accountOrRegionDidChange() {
        reset()
        guard hasLoaded else { return }
        Task { await refresh() }
    }
}
