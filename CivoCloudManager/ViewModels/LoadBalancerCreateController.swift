import Foundation

/// How a create request ended.
enum LoadBalancerCreateOutcome: Equatable {
    /// Civo answered with the new load balancer.
    case created(id: String)
    /// Nothing was sent; `error` explains why and the form can be sent again.
    case refused
    /// Civo refused the request, so nothing was created; `error` explains why.
    case rejected
    /// The request was sent, but whether Civo created the load balancer is unknown.
    case unknown
    /// A request of this form is already on its way; nothing more was sent.
    case alreadyInFlight
}

/// A create result the open form could not show, or one that must still be checked in the list.
struct UnresolvedLoadBalancerCreate: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let context: LoadBalancerContext
    let wasCreated: Bool

    var message: String {
        wasCreated
            ? String(localized: "Load balancer \"\(name)\" was created.")
            : String(localized: "Civo may have created load balancer \"\(name)\". Check the list before trying again.")
    }
}

/// One Create Load Balancer form at a time: it is bound to the account and region it was opened with, lists the
/// networks of exactly those, and sends at most one request per confirmation. No request is ever repeated.
@Observable
@MainActor
final class LoadBalancerCreateController {
    enum Phase: Equatable {
        case closed, loadingNetworks, ready, submitting
    }

    struct Form: Equatable {
        let id = UUID()
        let context: LoadBalancerContext
    }

    private(set) var phase = Phase.closed
    private(set) var form: Form?
    private(set) var networks: [CivoNetwork] = []
    private(set) var error: String?
    /// Results to check in the list, kept until dismissed; a refresh cannot prove a load balancer was not created.
    private(set) var unresolved: [UnresolvedLoadBalancerCreate] = []
    /// Counts network loads, so only the answer for the open form is applied.
    private var networkRequest = 0

    private let api: any LoadBalancerAPI
    private let settingsRegion: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let apiKey: @MainActor () -> String
    private let recordActivity: @MainActor (_ action: String, _ name: String, _ id: String) -> Void
    private let diagnostics: @MainActor (String) -> Void

    init(
        api: any LoadBalancerAPI = CivoLoadBalancerService(),
        settingsRegion: @escaping @MainActor () -> String = { CivoConfig.shared.region },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        apiKey: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        recordActivity: @escaping @MainActor (_ action: String, _ name: String, _ id: String) -> Void = { action, name, id in
            ActivityLog.shared.log(action, resourceType: "Load Balancer", resourceName: name, resourceId: id)
        },
        diagnostics: @escaping @MainActor (String) -> Void = { Log.error($0) }
    ) {
        self.api = api
        self.settingsRegion = settingsRegion
        self.isAccessAllowed = isAccessAllowed
        self.apiKey = apiKey
        self.recordActivity = recordActivity
        self.diagnostics = diagnostics
    }

    var isSubmitting: Bool { phase == .submitting }

    /// Opens a new form for the current account and region and loads their networks. While a request is on its
    /// way no new form is opened, so its answer always reaches the form it was sent from.
    func beginForm() async {
        guard phase != .submitting else { return }
        networkRequest += 1
        let request = networkRequest
        let key = apiKey()
        let region = settingsRegion()
        let form = Form(context: LoadBalancerContext(account: CivoAccount(apiKey: key), region: region))
        self.form = form
        networks = []
        error = nil
        phase = .loadingNetworks
        let result: Result<[CivoNetwork], LoadBalancerFailure>
        do {
            result = .success(try await api.listNetworks(region: region, apiKey: key))
        } catch {
            result = .failure(LoadBalancerFailure(error))
        }
        guard request == networkRequest, self.form == form else { return }
        phase = .ready
        switch result {
        case .success(let networks):
            self.networks = networks
        case .failure(let failure):
            diagnostics("Load balancer networks failed: \(failure.diagnosticName)")
            error = failure.message
        }
    }

    /// Closes the form. A request on its way keeps the form open until Civo answers.
    func endForm() {
        guard phase != .submitting else { return }
        networkRequest += 1
        form = nil
        networks = []
        error = nil
        phase = .closed
    }

    /// Why the open form may no longer send, nil while it may. Checked when the user confirms.
    func refusal(for form: Form) -> String? {
        guard isAccessAllowed() else { return String(localized: "Creating load balancers requires Full Access.") }
        guard !form.context.region.isEmpty else { return LoadBalancerFailure.noRegion.message }
        guard form.context.account == CivoAccount(apiKey: apiKey()) else {
            return String(localized: "The API key changed after the form was opened, so nothing was sent. Close the form and open it again.")
        }
        guard form.context.region.caseInsensitiveCompare(settingsRegion()) == .orderedSame else {
            return String(localized: "The region changed after the form was opened, so nothing was sent. Close the form and open it again.")
        }
        return nil
    }

    /// Sends `draft` once to the account and region of the open form.
    func create(_ draft: LoadBalancerDraft) async -> LoadBalancerCreateOutcome {
        guard phase != .submitting else { return .alreadyInFlight }
        guard let form, phase == .ready else { return .refused }
        error = nil
        if let problem = draft.problems().first {
            error = problem.message
            return .refused
        }
        if let refusal = refusal(for: form) {
            error = refusal
            return .refused
        }
        guard networks.contains(where: { $0.id == draft.networkId }) else {
            error = LoadBalancerDraftProblem.noNetwork.message
            return .refused
        }
        let key = apiKey()
        guard !Task.isCancelled else { return .refused }

        // Set before the request, so a second confirmation finds it on its way.
        phase = .submitting
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let outcome: LoadBalancerCreateOutcome
        var failureMessage: String?
        do {
            let created = try await api.createLoadBalancer(body: draft.createBody(region: form.context.region), region: form.context.region, apiKey: key)
            outcome = created.id.isEmpty ? .unknown : .created(id: created.id)
        } catch {
            let failure = LoadBalancerFailure(error)
            diagnostics("Load balancer create failed: \(failure.diagnosticName)")
            if failure.provesNothingChanged {
                outcome = .rejected
                failureMessage = failure == .rejected
                    ? String(localized: "Civo refused to create the load balancer, so nothing was created. Check the name, network, backends and your quota in the Civo dashboard.")
                    : failure.message
            } else {
                outcome = .unknown
            }
        }
        phase = .ready

        switch outcome {
        case .created(let id):
            recordActivity("Created load balancer", name, id)
        case .unknown:
            recordActivity("Create load balancer not confirmed", name, "")
        default:
            break
        }
        // The answer is shown in the form only while the form is still bound to the current account and region.
        let isShownHere = self.form == form && refusal(for: form) == nil
        switch outcome {
        case .created where isShownHere:
            endForm()
        case .created:
            unresolved.append(UnresolvedLoadBalancerCreate(name: name, context: form.context, wasCreated: true))
            endForm()
        case .unknown:
            unresolved.append(UnresolvedLoadBalancerCreate(name: name, context: form.context, wasCreated: false))
            endForm()
        default:
            error = failureMessage
        }
        return outcome
    }

    /// The results to check for the list loaded under `context`.
    func unresolved(in context: LoadBalancerContext?) -> [UnresolvedLoadBalancerCreate] {
        unresolved.filter { $0.context == context }
    }

    func dismiss(_ id: UUID) {
        unresolved.removeAll { $0.id == id }
    }
}
