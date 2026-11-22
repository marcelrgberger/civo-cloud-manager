import CryptoKit
import Foundation

/// Lifecycle of one console window.
///
/// - Closing the window only disconnects locally; the Civo session stays active until it expires.
/// - "End session" sends DELETE, which ends the session for everyone, including the dashboard.
/// - Every close, end or reconnect first cancels the running preparation, starts unloading the page
///   and drops the tokenized URL, before any network cleanup is awaited. Late responses from a
///   superseded attempt are ignored.
/// - End session sends DELETE only after the page has unloaded, so the noVNC WebSocket is closed by
///   the app instead of being cut off by the server.
@Observable
@MainActor
final class ConsoleViewModel {
    enum Phase: Equatable {
        case idle
        case starting
        case preparing(attempt: Int, of: Int)
        /// URL handed to the web view; page not loaded yet.
        case loading
        /// noVNC page loaded. This does not prove that the VNC connection works.
        case pageLoaded
        case disconnected
        case ending
        case ended(ConsoleEndResult)
        /// Local console closed, but DELETE failed: the server session may still be active.
        case endFailed(ConsoleError)
        case failed(ConsoleError)
    }

    struct Timing: Sendable {
        var maxAttempts = 5
        var retryInterval: Duration = .seconds(7)
        var sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    }

    /// A published console attempt. `id` lets web view callbacks from a superseded attempt be ignored.
    struct Connection: Equatable {
        let id: Int
        /// Tokenized console URL. In memory only.
        let url: URL
    }

    let target: ConsoleTarget
    private(set) var phase: Phase = .idle
    /// nil whenever no console is attached.
    private(set) var connection: Connection?

    private let api: any ConsoleAPI
    private let timing: Timing
    private let apiKeyProvider: @MainActor () -> String
    private let isAccessAllowed: @MainActor () -> Bool
    private let recordActivity: @MainActor (String) -> Void
    private var openedKeyFingerprint: SHA256.Digest?
    private var generation = 0
    private var task: Task<Void, Never>?
    /// Registered by the view, so detaching does not wait for a SwiftUI update.
    private var pageUnloader: (any ConsolePageUnloading)?

    init(
        target: ConsoleTarget,
        api: any ConsoleAPI = CivoConsoleService(),
        timing: Timing = Timing(),
        apiKeyProvider: @escaping @MainActor () -> String = { CivoConfig.shared.apiKey },
        isAccessAllowed: @escaping @MainActor () -> Bool = { StoreManager.shared.isFullAccessUnlocked },
        recordActivity: (@MainActor (String) -> Void)? = nil
    ) {
        self.target = target
        self.api = api
        self.timing = timing
        self.apiKeyProvider = apiKeyProvider
        self.isAccessAllowed = isAccessAllowed
        self.recordActivity = recordActivity ?? { action in
            ActivityLog.shared.log(action, resourceType: "Instance", resourceName: target.instanceName, resourceId: target.instanceId)
        }
    }

    var isBusy: Bool {
        switch phase {
        case .starting, .preparing, .ending: return true
        default: return false
        }
    }

    /// Starts or re-checks the server session (PUT returns the active session or starts a new one),
    /// fetches a fresh JWT and waits until the console answers. Also used for Reconnect.
    func connect() {
        detach()
        guard isAccessAllowed() else { return fail(.accessRevoked) }
        guard !target.region.isEmpty else { return fail(.noRegion) }
        phase = .starting
        let current = generation
        task = Task { await run(generation: current) }
    }

    /// Window closed: disconnect locally only. No DELETE, because it would end the session for everyone.
    func closeLocally() {
        detach()
        if !isTerminal { phase = .disconnected }
    }

    /// The stored API key changed. A window never continues with a different account.
    func apiKeyDidChange() {
        guard openedKeyFingerprint != nil else { return }
        do {
            _ = try currentAPIKey()
        } catch {
            fail(ConsoleError.sanitize(error))
        }
    }

    /// Full Access expired while the window is open.
    func revokeAccess() {
        detach()
        phase = .failed(.accessRevoked)
    }

    /// Ends the server-side session for everyone. A 404 counts as already stopped.
    func endSession() async {
        guard phase != .ending else { return }
        let unloading = detach()
        guard isAccessAllowed() else { return fail(.accessRevoked) }
        let apiKey: String
        do { apiKey = try currentAPIKey() } catch { return fail(ConsoleError.sanitize(error)) }

        phase = .ending
        let current = generation
        // The user confirmed the end, so DELETE is sent even if the window closes during the wait.
        await unloading?.waitUntilUnloaded()
        do {
            let result = try await api.endSession(target, apiKey: apiKey)
            guard current == generation else { return }
            phase = .ended(result)
            Log.info("Console session ended for instance \(target.instanceId)")
            recordActivity(result == .ended ? "Ended console session" : "Console session already ended")
        } catch {
            guard current == generation else { return }
            let sanitized = ConsoleError.sanitize(error)
            phase = .endFailed(sanitized)
            Log.warning("Ending console session failed for instance \(target.instanceId): \(sanitized.logDescription)")
        }
    }

    // MARK: - Web view callbacks

    func webViewDidAttach(connectionID: Int, unloader: any ConsolePageUnloading) {
        guard connectionID == connection?.id else { return unloader.start() }
        pageUnloader = unloader
    }

    func pageDidLoad(connectionID: Int) {
        guard connectionID == connection?.id, phase == .loading else { return }
        phase = .pageLoaded
    }

    func pageDidFail(connectionID: Int) {
        guard connectionID == connection?.id else { return }
        detach()
        phase = .failed(.pageLoadFailed)
    }

    // MARK: - Private

    private var isTerminal: Bool {
        switch phase {
        case .ended, .endFailed, .failed(.accessRevoked), .failed(.accountChanged): return true
        default: return false
        }
    }

    /// Cancels preparation, starts unloading the page and drops the console URL immediately;
    /// invalidates in-flight results and callbacks. Returns the unloader of the detached page.
    @discardableResult
    private func detach() -> (any ConsolePageUnloading)? {
        generation += 1
        task?.cancel()
        task = nil
        let unloader = pageUnloader
        unloader?.start()
        pageUnloader = nil
        connection = nil
        return unloader
    }

    private func fail(_ error: ConsoleError) {
        detach()
        phase = error == .cancelled ? .disconnected : .failed(error)
    }

    /// Returns the current API key, refusing to continue with a different account than the one
    /// this window was opened with.
    private func currentAPIKey() throws -> String {
        let key = apiKeyProvider()
        guard !key.isEmpty else { throw ConsoleError.noAPIKey }
        let fingerprint = SHA256.hash(data: Data(key.utf8))
        if let openedKeyFingerprint, openedKeyFingerprint != fingerprint {
            throw ConsoleError.accountChanged
        }
        openedKeyFingerprint = fingerprint
        return key
    }

    private func run(generation current: Int) async {
        // Every suspension point is followed by this check before any further request or state change.
        func isCurrent() -> Bool { current == generation && !Task.isCancelled }
        guard isCurrent() else { return }
        do {
            let apiKey = try currentAPIKey()
            let session = try await api.startSession(target, apiKey: apiKey)
            guard isCurrent() else { return }

            var url = try await tokenizedURL(uri: session.uri, apiKey: apiKey)
            guard isCurrent() else { return }

            // Bounded wait: at most `maxAttempts` probes (10 s timeout each) with cancellable delays.
            // A JWT renewal happens at most once and consumes the attempt that triggered it.
            var renewedToken = false
            for attempt in 1...timing.maxAttempts {
                phase = .preparing(attempt: attempt, of: timing.maxAttempts)
                let probe = try await api.probe(url, target: target)
                guard isCurrent() else { return }
                switch probe {
                case .ready:
                    guard isAccessAllowed() else { return fail(.accessRevoked) }
                    _ = try currentAPIKey()
                    connection = Connection(id: current, url: url)
                    phase = .loading
                    Log.info("Console session ready for instance \(target.instanceId)")
                    recordActivity("Opened console")
                    return
                case .tokenRejected where !renewedToken:
                    renewedToken = true
                    _ = try currentAPIKey()
                    url = try await tokenizedURL(uri: session.uri, apiKey: apiKey)
                    guard isCurrent() else { return }
                case .tokenRejected, .notReady:
                    break
                }
                if attempt < timing.maxAttempts { try await timing.sleep(timing.retryInterval) }
                guard isCurrent() else { return }
            }
            fail(.notReady)
        } catch {
            guard current == generation else { return }
            let sanitized = ConsoleError.sanitize(error)
            if sanitized != .cancelled {
                Log.warning("Console preparation failed for instance \(target.instanceId): \(sanitized.logDescription)")
            }
            fail(sanitized)
        }
    }

    private func tokenizedURL(uri: String, apiKey: String) async throws -> URL {
        let token = try await api.exchangeToken(region: target.region, apiKey: apiKey)
        return try ConsoleURL.make(uri: uri, token: token, target: target)
    }
}

/// Unloads the console page of one web view, which makes WebKit close the page's WebSocket.
@MainActor
protocol ConsolePageUnloading: AnyObject {
    /// Detaches callbacks and starts the unload immediately. Repeated calls have no effect.
    func start()
    /// Returns once the page has unloaded, or after a bounded timeout.
    func waitUntilUnloaded() async
}
