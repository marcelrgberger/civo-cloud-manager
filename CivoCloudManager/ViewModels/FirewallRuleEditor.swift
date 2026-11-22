import Foundation

/// The rule an edit was started for, with the account and region it was listed in.
struct FirewallRuleTarget: Equatable, Sendable {
    let firewallId: String
    let firewallName: String
    let ruleId: String
    let region: String
    /// The account the rule was listed from, so an edit never reaches another account.
    let account: CivoAccount
}

/// Why a rule edit was refused. Nothing was sent in any of these cases.
enum FirewallRuleEditError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case accountChanged
    case ruleRemoved
    case ruleChanged
    case noChanges
    case notEditable(FirewallRuleEditability)

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Editing firewall rules requires Full Access.")
        case .noRegion:
            String(localized: "The region of this firewall is unknown. Reload the rules and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the rule edit was cancelled. Nothing was sent.")
        case .accountChanged:
            String(localized: "The API key changed, so the rule edit was cancelled. Nothing was sent.")
        case .ruleRemoved:
            String(localized: "The rule no longer exists, so nothing was changed.")
        case .ruleChanged:
            String(localized: "The rule was changed elsewhere in the meantime. Check the comparison against its current values and save again.")
        case .noChanges:
            String(localized: "Nothing was changed.")
        case .notEditable(let editability):
            // Only refusals are reported, and every refusal has a message.
            editability.message ?? ""
        }
    }
}

/// How a save ended. The editor stays open, and `saveError` explains why, when `save` returns nil.
enum FirewallRuleSaveOutcome: Equatable {
    case saved
    /// The request was sent but no refusal came back, or Civo's answer could not be read; the rule may have been changed.
    case uncertain
    /// The edit was closed without a change; `notice` explains why.
    case cancelled
}

/// Edits one firewall rule at a time. Before the update the rule is loaded again: a rule that was removed
/// is reported and never recreated, and a rule changed elsewhere must be confirmed again.
@Observable
@MainActor
final class FirewallRuleEditor {
    struct Session: Equatable {
        /// Tells this edit apart from a later one of the same rule.
        let id = UUID()
        let target: FirewallRuleTarget
        /// The rule as last loaded; the comparison and the conflict check use it.
        var original: CivoRule
    }

    private(set) var session: Session?
    private(set) var isSaving = false
    /// The session whose update is on its way to Civo. It can no longer be called back.
    private var sendingSessionId: UUID?
    private(set) var saveError: String?
    /// Why the last edit was closed without saving, shown above the rule list.
    private(set) var notice: String?
    /// This Mac's public IP, nil until detected. While nil a possible lockout is warned about.
    private(set) var currentIP: String?

    private let api: any FirewallRuleAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let detectIP: @Sendable () async throws -> String
    private let notificationCenter: NotificationCenter
    private let recordActivity: @MainActor (FirewallRuleTarget) -> Void
    @ObservationIgnored nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(
        api: any FirewallRuleAPI = CivoFirewallService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        detectIP: @escaping @Sendable () async throws -> String = { try await IPDetector().detectIP() },
        notificationCenter: NotificationCenter = .default,
        recordActivity: @escaping @MainActor (FirewallRuleTarget) -> Void = { target in
            ActivityLog.shared.log("Updated firewall rule", resourceType: "Firewall", resourceName: target.firewallName, resourceId: target.firewallId)
        }
    ) {
        self.api = api
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.apiKey = apiKey
        self.detectIP = detectIP
        self.notificationCenter = notificationCenter
        self.recordActivity = recordActivity
        observers = [Notification.Name.civoAPIKeyDidChange, .civoRegionDidChange].map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.dropInvalidSession() }
            }
        }
    }

    deinit {
        observers.forEach(notificationCenter.removeObserver)
    }

    // MARK: - Session

    /// Opens the editor for `rule` of `firewall`, listed from `region` with `account`, with the target captured now.
    func begin(
        editing rule: CivoRule,
        of firewall: CivoFirewall,
        region: String,
        account: CivoAccount?,
        isScheduledForClosure: (_ firewallId: String, _ ruleId: String) -> Bool
    ) {
        notice = nil
        saveError = nil
        currentIP = nil
        let editability = FirewallRuleEditability(rule: rule, isScheduledForClosure: isScheduledForClosure(firewall.id, rule.id))
        guard editability == .editable else {
            notice = FirewallRuleEditError.notEditable(editability).message
            return
        }
        guard let account else {
            notice = FirewallRuleEditError.accountChanged.message
            return
        }
        let target = FirewallRuleTarget(firewallId: firewall.id, firewallName: firewall.name, ruleId: rule.id, region: region, account: account)
        if let problem = targetError(for: target) {
            notice = problem.message
            return
        }
        session = Session(target: target, original: rule)
    }

    func cancel() {
        if let session, session.id == sendingSessionId {
            notice = Self.awaitingAnswerMessage(for: session.target)
        }
        session = nil
        saveError = nil
    }

    /// Why `target` may no longer be used, nil while it may. Checked before and after every request.
    func targetError(for target: FirewallRuleTarget) -> FirewallRuleEditError? {
        guard isAccessAllowed() else { return .accessRevoked }
        guard !target.region.isEmpty else { return .noRegion }
        guard target.account == CivoAccount(apiKey: apiKey()) else { return .accountChanged }
        guard target.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else { return .regionChanged }
        return nil
    }

    /// Detects this Mac's public IP for the lockout warning. A failure leaves it unknown, which is warned about.
    func detectCurrentIP() async {
        currentIP = try? await detectIP()
    }

    // MARK: - Save

    /// Sends `draft` once the rule, loaded again, still matches what the user compared against.
    /// `isScheduledForClosure` is asked again with the reloaded rule, since a timer may have been set meanwhile.
    func save(_ draft: FirewallRuleDraft, isScheduledForClosure: (_ firewallId: String, _ ruleId: String) -> Bool) async -> FirewallRuleSaveOutcome? {
        guard let session, !isSaving else { return nil }
        let target = session.target
        saveError = nil
        if let problem = targetError(for: target) { return close(problem) }
        if let invalid = draft.problem {
            saveError = invalid.message
            return nil
        }
        // One key for the reload and the update, so both reach the same account.
        let key = apiKey()
        guard !key.isEmpty else {
            saveError = CivoAPIError.userMessage(CivoAPIError.noAPIKey)
            return nil
        }

        isSaving = true
        defer { isSaving = false }

        let current: CivoRule
        do {
            let rules = try await api.getRulesForFirewall(target.firewallId, region: target.region, apiKey: key)
            // Cancelled, or closed by a region or key change, while the rules were loading.
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem) }
            guard let rule = rules.first(where: { $0.id == target.ruleId }) else { return close(.ruleRemoved) }
            current = rule
        } catch {
            guard self.session?.id == session.id else { return nil }
            if let problem = targetError(for: target) { return close(problem) }
            saveError = CivoAPIError.userMessage(error)
            return nil
        }

        let editability = FirewallRuleEditability(rule: current, isScheduledForClosure: isScheduledForClosure(target.firewallId, target.ruleId))
        guard editability == .editable else { return close(.notEditable(editability)) }
        guard current == session.original else {
            self.session?.original = current
            saveError = FirewallRuleEditError.ruleChanged.message
            return nil
        }
        guard !draft.changes(from: current).isEmpty else {
            saveError = FirewallRuleEditError.noChanges.message
            return nil
        }

        // From here on the editor may be closed, and another one opened, before Civo answers. The answer then
        // leaves the later editor alone and is reported as a notice naming the firewall.
        sendingSessionId = session.id
        defer { sendingSessionId = nil }
        do {
            try await api.updateRule(target.ruleId, of: target.firewallId, body: draft.requestBody(region: target.region), region: target.region, apiKey: key)
        } catch CivoAPIError.decodingError {
            if self.session?.id == session.id { self.session = nil }
            notice = Self.unreadableUpdateMessage(for: target)
            return .uncertain
        } catch let refusal as CivoAPIError where Self.provesRuleUnchanged(refusal) {
            let reason = refusal.localizedDescription
            guard self.session?.id == session.id else {
                notice = Self.notSavedMessage(for: target, reason: reason)
                return .cancelled
            }
            saveError = reason
            return nil
        } catch {
            // A lost connection, a cancelled request or a server error may follow a change Civo already applied.
            if self.session?.id == session.id { self.session = nil }
            notice = Self.unknownResultMessage(for: target)
            return .uncertain
        }
        recordActivity(target)
        if self.session?.id == session.id {
            self.session = nil
        } else {
            notice = Self.savedMessage(for: target)
        }
        return .saved
    }

    static func unreadableUpdateMessage(for target: FirewallRuleTarget) -> String {
        String(localized: "Civo accepted the rule change in firewall “\(target.firewallName)”, but its answer could not be read. Check the rule in the list.")
    }

    static func awaitingAnswerMessage(for target: FirewallRuleTarget) -> String {
        String(localized: "The rule change in firewall “\(target.firewallName)” was already sent and can no longer be cancelled. Its result is shown here once Civo answers.")
    }

    static func savedMessage(for target: FirewallRuleTarget) -> String {
        String(localized: "The rule change in firewall “\(target.firewallName)” was saved.")
    }

    static func unknownResultMessage(for target: FirewallRuleTarget) -> String {
        String(localized: "The result of the rule change in firewall “\(target.firewallName)” is unknown. Check the rule in the list.")
    }

    static func notSavedMessage(for target: FirewallRuleTarget, reason: String) -> String {
        String(localized: "The rule change in firewall “\(target.firewallName)” was not saved: \(reason)")
    }

    /// Only a refusal of the request proves that Civo left the rule as it was.
    private static func provesRuleUnchanged(_ error: CivoAPIError) -> Bool {
        guard case .httpError(let status, _) = error else { return false }
        return (400..<500).contains(status)
    }

    private func close(_ problem: FirewallRuleEditError) -> FirewallRuleSaveOutcome {
        session = nil
        saveError = nil
        notice = problem.message
        return .cancelled
    }

    private func dropInvalidSession() {
        guard let session, let problem = targetError(for: session.target) else { return }
        if session.id == sendingSessionId {
            cancel()
        } else {
            _ = close(problem)
        }
    }
}
