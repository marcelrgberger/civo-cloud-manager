import Foundation

// MARK: - Catalog

/// One element of `GET /v2/kubernetes/applications`, read field by field so that one odd entry never fails the
/// whole list. A missing key, a wrong type or an element that is not an object all read as nil. `post_install`,
/// `image_url` and the plans' `configuration` are never read.
struct RawMarketplaceEntry: Decodable, Sendable {
    let name: String?
    let title: String?
    let version: String?
    let isDefault: Bool?
    let dependencies: [String]?
    let description: String?
    let category: String?
    /// The labels of `plans`, nil for a plan without a readable label; nil when Civo lists no plans.
    let planLabels: [String?]?
    /// `plans` is present but not a list, so the application's plans are unknown.
    let hasUnreadablePlans: Bool

    private enum CodingKeys: String, CodingKey {
        case name, title, version, dependencies, description, category, plans
        case isDefault = "default"
    }

    private struct RawPlan: Decodable {
        let label: String?

        private enum CodingKeys: String, CodingKey { case label }

        init(from decoder: Decoder) throws {
            label = try? decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .label)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        name = try? container?.decode(String.self, forKey: .name)
        title = try? container?.decode(String.self, forKey: .title)
        version = try? container?.decode(String.self, forKey: .version)
        isDefault = try? container?.decode(Bool.self, forKey: .isDefault)
        dependencies = try? container?.decode([String].self, forKey: .dependencies)
        description = try? container?.decode(String.self, forKey: .description)
        category = try? container?.decode(String.self, forKey: .category)
        let plans = try? container?.decode([RawPlan].self, forKey: .plans)
        planLabels = plans?.map(\.label)
        let plansAreNull = (try? container?.decodeNil(forKey: .plans)) ?? true
        hasUnreadablePlans = plans == nil && container?.contains(.plans) == true && !plansAreNull
    }
}

/// A marketplace application as Civo lists it. Names, descriptions, categories and plan labels are Civo's
/// original text and are never translated.
struct CivoMarketplaceApplication: Identifiable, Equatable, Sendable {
    enum Availability: Equatable, Sendable {
        case selectable
        /// The name or every plan label would change the meaning of Civo's comma separated list, or the plans
        /// could not be read.
        case unsupported
        /// Civo lists the name more than once with different details, so none of them is picked.
        case listedMoreThanOnce
    }

    /// The identity key, see `MarketplaceIdentity`.
    let id: String
    let name: String
    let title: String?
    let version: String?
    let isDefault: Bool
    let dependencies: [String]
    let description: String?
    let category: String?
    /// Empty when the application has no plans; otherwise one of them must be chosen.
    let plans: [String]
    let availability: Availability

    var displayName: String { title ?? name }
}

/// Civo's list of marketplace applications after validation: one row per name, in Civo's order.
struct MarketplaceCatalog: Equatable, Sendable {
    let applications: [CivoMarketplaceApplication]
    /// Entries from Civo that were skipped, cannot be selected or lost a plan.
    let unusableEntryCount: Int

    var isComplete: Bool { unusableEntryCount == 0 }

    /// Builds the catalog from Civo's entries; throws when not a single application is left to show.
    init(validating entries: [RawMarketplaceEntry]) throws(MarketplaceCatalogError) {
        var order: [String] = []
        var candidates: [String: [Candidate]] = [:]
        var unusable = 0
        for entry in entries {
            guard let candidate = Candidate(entry) else { unusable += 1; continue }
            if candidates[candidate.id] == nil { order.append(candidate.id) }
            candidates[candidate.id, default: []].append(candidate)
        }

        var applications: [CivoMarketplaceApplication] = []
        for id in order {
            let group = candidates[id] ?? []
            guard let first = group.first else { continue }
            let isConflict = group.contains { !$0.hasSameDetails(as: first) }
            let availability: CivoMarketplaceApplication.Availability = isConflict
                ? .listedMoreThanOnce
                : (first.isSupported ? .selectable : .unsupported)
            if availability != .selectable {
                unusable += group.count
            } else {
                unusable += group.filter(\.lostPlans).count
            }
            applications.append(first.application(availability: availability))
        }
        guard !applications.isEmpty else { throw .noApplications }
        self.applications = applications
        unusableEntryCount = unusable
    }

    func application(withID id: String) -> CivoMarketplaceApplication? {
        applications.first { $0.id == id }
    }

    /// The applications whose name, title, category or description contain `query`, ignoring case and diacritics.
    func search(_ query: String) -> [CivoMarketplaceApplication] {
        let needle = MarketplaceIdentity.fold(query)
        guard !needle.isEmpty else { return applications }
        return applications.filter { app in
            [app.name, app.title, app.category, app.description].contains { field in
                field.map { MarketplaceIdentity.fold($0).contains(needle) } ?? false
            }
        }
    }

    /// One validated entry before duplicates are resolved.
    private struct Candidate {
        let id: String
        let name: String
        let entry: RawMarketplaceEntry
        let plans: [String]
        let lostPlans: Bool
        let isSupported: Bool

        init?(_ entry: RawMarketplaceEntry) {
            let name = entry.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return nil }
            self.name = name
            self.entry = entry
            id = MarketplaceIdentity.key(name)
            let labels = entry.planLabels ?? []
            let safeLabels = labels.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter(MarketplaceIdentity.isSafe)
            var plans: [String] = []
            for label in safeLabels where !plans.contains(label) {
                plans.append(label)
            }
            self.plans = plans
            lostPlans = safeLabels.count < labels.count || entry.hasUnreadablePlans
            let plansUsable = !entry.hasUnreadablePlans && (labels.isEmpty || !plans.isEmpty)
            isSupported = MarketplaceIdentity.isSafe(name) && plansUsable
        }

        func hasSameDetails(as other: Candidate) -> Bool {
            entry.version == other.entry.version
                && entry.description == other.entry.description
                && entry.dependencies == other.entry.dependencies
                && Set(plans) == Set(other.plans)
                && isSupported == other.isSupported
        }

        func application(availability: CivoMarketplaceApplication.Availability) -> CivoMarketplaceApplication {
            CivoMarketplaceApplication(
                id: id, name: name, title: entry.title, version: entry.version, isDefault: entry.isDefault == true,
                dependencies: entry.dependencies ?? [], description: entry.description, category: entry.category,
                plans: plans, availability: availability
            )
        }
    }
}

enum MarketplaceCatalogError: Error, Equatable {
    case noApplications

    var message: String {
        String(localized: "Civo listed no marketplace applications that can be shown.")
    }
}

/// How applications are told apart and which names and plans can be written into Civo's list.
enum MarketplaceIdentity {
    /// The trimmed name; Civo documents application names as case-sensitive, so two entries are the same
    /// application only when their names match exactly.
    static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trimmed, ignoring case and diacritics, for searching.
    static func fold(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Civo's `applications` is a comma separated list of `name` or `name:plan`, and a leading `-` removes an
    /// application. A name or plan with any of these characters cannot be written into it without changing its
    /// meaning, and Civo documents no escaping.
    static func isSafe(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed == value && !trimmed.hasPrefix("-")
            && !trimmed.contains(",") && !trimmed.contains(":")
    }
}

// MARK: - Selection

/// The account and region a catalog was loaded with and a choice was made under.
struct MarketplaceContext: Equatable, Sendable {
    let account: CivoAccount
    let region: String
}

/// One chosen application with what the user saw of it when choosing.
struct MarketplaceChoice: Equatable, Sendable {
    let id: String
    let name: String
    let plan: String?
    let version: String?
    let description: String?
    let dependencies: [String]
    let context: MarketplaceContext

    init(_ application: CivoMarketplaceApplication, plan: String?, context: MarketplaceContext) {
        id = application.id
        name = application.name
        self.plan = plan
        version = application.version
        description = application.description
        dependencies = application.dependencies
        self.context = context
    }

    var entry: String { plan.map { "\(name):\($0)" } ?? name }
}

enum MarketplaceSelectionIssue: Equatable, Sendable {
    case noLongerOffered
    case planNoLongerOffered
    case detailsChanged
    /// Chosen under another account or region than the list now shown.
    case contextChanged

    var label: String {
        switch self {
        case .noLongerOffered: String(localized: "No longer offered")
        case .planNoLongerOffered: String(localized: "Plan no longer offered")
        case .detailsChanged: String(localized: "Details changed, review again")
        case .contextChanged: String(localized: "Chosen for another account or region, review again")
        }
    }
}

enum MarketplaceSelectionError: Error, Equatable {
    case unsafeEntry(String)
    /// A choice is marked in the review and has not been removed or chosen again.
    case needsReview
    /// The account or region changed after the applications were chosen.
    case contextChanged

    var message: String {
        switch self {
        case .unsafeEntry(let name):
            String(localized: "\(name) cannot be sent to Civo as written.")
        case .needsReview:
            String(localized: "Remove or review the marked applications before creating the cluster.")
        case .contextChanged:
            String(localized: "The account or region changed after the applications were chosen. Review them again.")
        }
    }
}

/// The chosen applications in the order they were chosen, at most one per application.
struct MarketplaceSelection: Equatable, Sendable {
    private(set) var choices: [MarketplaceChoice] = []

    var isEmpty: Bool { choices.isEmpty }

    /// Chooses `application` with `plan`, or replaces the earlier choice of the same application in its place.
    mutating func choose(_ application: CivoMarketplaceApplication, plan: String?, context: MarketplaceContext) {
        let choice = MarketplaceChoice(application, plan: plan, context: context)
        if let index = choices.firstIndex(where: { $0.id == choice.id }) {
            choices[index] = choice
        } else {
            choices.append(choice)
        }
    }

    mutating func remove(_ id: String) {
        choices.removeAll { $0.id == id }
    }

    func choice(for id: String) -> MarketplaceChoice? {
        choices.first { $0.id == id }
    }

    /// Civo's documented `applications` value, `Name` or `Name:Plan` joined by `,`; nil when nothing is chosen,
    /// so the field is left out instead of being sent empty.
    func serialized() throws(MarketplaceSelectionError) -> String? {
        guard !choices.isEmpty else { return nil }
        for choice in choices where !MarketplaceIdentity.isSafe(choice.name) || !(choice.plan.map(MarketplaceIdentity.isSafe) ?? true) {
            throw .unsafeEntry(choice.entry)
        }
        return choices.map(\.entry).joined(separator: ",")
    }

    /// What changed for each choice in `catalog`, loaded under `context`, compared with what the user saw.
    func issues(against catalog: MarketplaceCatalog, loadedIn context: MarketplaceContext) -> [String: MarketplaceSelectionIssue] {
        var issues: [String: MarketplaceSelectionIssue] = [:]
        for choice in choices {
            guard let app = catalog.application(withID: choice.id), app.availability == .selectable else {
                issues[choice.id] = .noLongerOffered
                continue
            }
            if let plan = choice.plan, !app.plans.contains(plan) {
                issues[choice.id] = .planNoLongerOffered
            } else if choice.plan == nil, !app.plans.isEmpty {
                issues[choice.id] = .planNoLongerOffered
            } else if choice.context != context {
                issues[choice.id] = .contextChanged
            } else if app.name != choice.name || app.version != choice.version || app.description != choice.description
                        || app.dependencies != choice.dependencies {
                issues[choice.id] = .detailsChanged
            }
        }
        return issues
    }
}

// MARK: - Create Cluster

/// The marketplace part of Create Cluster: the last catalog that loaded, the user's choices and whether the
/// cluster may be created with them.
struct MarketplaceCreateState: Equatable {
    private(set) var catalog: MarketplaceCatalog?
    private(set) var catalogContext: MarketplaceContext?
    private(set) var loadedAt: Date?
    /// The safe reason of the last failed load; the previous catalog and choices stay as they were.
    private(set) var loadError: String?
    private(set) var selection = MarketplaceSelection()

    mutating func catalogLoaded(_ catalog: MarketplaceCatalog, in context: MarketplaceContext, at date: Date) {
        self.catalog = catalog
        catalogContext = context
        loadedAt = date
        loadError = nil
    }

    mutating func catalogFailed(_ message: String) {
        loadError = message
    }

    /// Chooses an application from the shown catalog; only selectable applications and their listed plans.
    mutating func choose(_ application: CivoMarketplaceApplication, plan: String?) {
        guard let catalogContext, application.availability == .selectable,
              plan.map { application.plans.contains($0) } ?? application.plans.isEmpty else { return }
        selection.choose(application, plan: plan, context: catalogContext)
    }

    mutating func remove(_ id: String) {
        selection.remove(id)
    }

    /// Chooses the application again as the shown catalog lists it now, which resolves `.detailsChanged` and
    /// `.contextChanged`.
    mutating func acceptAgain(_ id: String) {
        guard let choice = selection.choice(for: id), let app = catalog?.application(withID: id) else { return }
        choose(app, plan: choice.plan)
    }

    var issues: [String: MarketplaceSelectionIssue] {
        guard let catalog, let catalogContext else { return [:] }
        return selection.issues(against: catalog, loadedIn: catalogContext)
    }

    /// Whether the cluster can be created with the current choices; an empty selection always can.
    var canSubmit: Bool { issues.isEmpty }

    /// The `applications` value to send for a cluster created under `context`, nil to leave the field out.
    func applicationsField(in context: MarketplaceContext) throws(MarketplaceSelectionError) -> String? {
        guard canSubmit else { throw .needsReview }
        if selection.choices.contains(where: { $0.context != context }) { throw .contextChanged }
        return try selection.serialized()
    }
}

// MARK: - Installed applications

/// What Civo reports about an application listed in a cluster's `installed_applications`. Nothing is inferred
/// about the pods or workloads in the cluster.
enum InstalledApplicationState: Equatable, Sendable {
    /// `installed` is true.
    case installed
    /// `installed` is false.
    case installing
    /// `installed` is missing, so the status is unknown.
    case listed

    init(installedFlag: Bool?) {
        switch installedFlag {
        case .some(true): self = .installed
        case .some(false): self = .installing
        case nil: self = .listed
        }
    }

    var label: String {
        switch self {
        case .installed: String(localized: "Installed")
        case .installing: String(localized: "Installing (reported by Civo)")
        case .listed: String(localized: "Listed by Civo")
        }
    }
}

// MARK: - Safe errors

/// The message shown for a failed marketplace or cluster request. Civo's error bodies can echo request details,
/// so only the fixed text for the status class is shown, or Civo's `reason` when it is a short plain sentence.
enum MarketplaceFailure {
    static let maximumReasonLength = 200
    static let minimumKeyLikeLength = 24

    /// nil for a cancelled request, which shows nothing.
    static func message(for error: Error) -> String? {
        if CivoAPIError.isCancelled(error) { return nil }
        if let catalogError = error as? MarketplaceCatalogError { return catalogError.message }
        if let selectionError = error as? MarketplaceSelectionError { return selectionError.message }
        guard let apiError = error as? CivoAPIError else {
            return String(localized: "The request to Civo failed.")
        }
        switch apiError {
        case .noAPIKey:
            return String(localized: "No Civo API key configured. Add your API key in Settings.")
        case .noRegion:
            return String(localized: "No region selected. Choose a region in Settings.")
        case .httpError(let code, let body):
            return message(forStatus: code, body: body)
        case .decodingError:
            return String(localized: "Civo's answer could not be read.")
        case .networkError, .incompleteList:
            return String(localized: "Civo could not be reached. Check your connection and try again.")
        case .cancelled:
            return nil
        }
    }

    private static func message(forStatus code: Int, body: String) -> String {
        switch code {
        case 401:
            return String(localized: "Authentication failed. Check your API key in Settings.")
        case 403:
            return String(localized: "Civo did not accept the request for this account.")
        case 404:
            return String(localized: "Civo could not find what was requested.")
        case 429:
            return String(localized: "Civo is limiting requests right now. Please wait a moment and try again.")
        case 500...599:
            return String(localized: "Civo is experiencing issues (HTTP \(code)). Please try again later.")
        default:
            if let reason = plainReason(in: body) {
                return String(localized: "Civo says: \(reason)")
            }
            return String(localized: "Civo refused the request (HTTP \(code)).")
        }
    }

    /// Civo's `reason`, only when it is one short line without markup or anything shaped like a credential.
    static func plainReason(in body: String) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any],
              let reason = (object["reason"] as? String)?.trimmingCharacters(in: .whitespaces),
              !reason.isEmpty, reason.count <= maximumReasonLength,
              !reason.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !reason.contains(where: { "<>{}=".contains($0) })
        else { return nil }
        let lowered = reason.lowercased()
        let credentialWords = ["password", "secret", "token", "apikey", "api_key", "api key", "key:", "bearer", "authorization", "credential"]
        guard !credentialWords.contains(where: { lowered.contains($0) }),
              !containsKeyLikeRun(reason) else { return nil }
        return reason
    }

    /// Civo API keys and generated passwords are long unbroken runs of letters and digits; ordinary words are not.
    private static func containsKeyLikeRun(_ text: String) -> Bool {
        let keyCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_+/"))
        return text.unicodeScalars.split { !keyCharacters.contains($0) }.contains { $0.count >= minimumKeyLikeLength }
    }
}
