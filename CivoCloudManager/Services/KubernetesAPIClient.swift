import Foundation
import Security

/// Weak-referencing delegate proxy to avoid URLSession → KubernetesAPIClient retain cycle.
/// URLSession retains its delegate strongly; using a proxy with a weak back-reference
/// allows the client to be deallocated normally when no longer referenced.
private final class K8sSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private weak var _client: KubernetesAPIClient?

    var client: KubernetesAPIClient? {
        get { lock.withLock { _client } }
        set { lock.withLock { _client = newValue } }
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let client {
            client.handleChallenge(challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

final class KubernetesAPIClient: NSObject, @unchecked Sendable {
    private let server: String
    fileprivate let identity: SecIdentity
    fileprivate let caCert: SecCertificate
    private let session: URLSession
    private let sessionDelegate: K8sSessionDelegate
    private var _invalidated = false
    private let lock = NSLock()

    /// Whether this client's session has been invalidated. Requests will throw immediately.
    var isInvalidated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _invalidated
    }

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        // Import CA cert from PEM via SecItemImport
        var caItems: CFArray?
        var caFormat = SecExternalFormat.formatPEMSequence
        var caType = SecExternalItemType.itemTypeCertificate
        let caStatus = SecItemImport(credentials.caCertPEM as CFData, nil, &caFormat, &caType, [], nil, nil, &caItems)
        guard caStatus == errSecSuccess, let caCerts = caItems as? [SecCertificate], let ca = caCerts.first else {
            throw K8sAPIError.invalidCertificate("CA import failed: \(caStatus)")
        }
        self.caCert = ca

        // Create identity from PEM cert + key using Security.framework only
        self.identity = try Self.createIdentity(certPEM: credentials.clientCertPEM, keyPEM: credentials.clientKeyPEM)

        // Use a delegate proxy with weak back-reference to avoid retain cycle
        let delegate = K8sSessionDelegate()
        self.sessionDelegate = delegate
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

        super.init()
        delegate.client = self
    }

    /// Invalidates the URLSession, cancelling all in-flight requests.
    func invalidate() {
        lock.lock()
        _invalidated = true
        lock.unlock()
        sessionDelegate.client = nil
        session.invalidateAndCancel()
    }

    deinit {
        lock.lock()
        _invalidated = true
        lock.unlock()
        sessionDelegate.client = nil
        session.invalidateAndCancel()
    }

    // MARK: - Auth Challenge (called by delegate proxy)

    fileprivate func handleChallenge(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let method = challenge.protectionSpace.authenticationMethod

        if method == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust
        {
            SecTrustSetAnchorCertificates(trust, [caCert] as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, true)
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }

        if method == NSURLAuthenticationMethodClientCertificate {
            completionHandler(.useCredential, URLCredential(
                identity: identity,
                certificates: nil,
                persistence: .forSession
            ))
            return
        }

        completionHandler(.performDefaultHandling, nil)
    }

    // MARK: - K8s API

    /// URL-encodes a path segment (namespace, pod name, etc.) for safe inclusion in K8s API paths.
    private func e(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
    }

    func listNodes() async throws -> K8sNodeList { try await get("/api/v1/nodes") }
    func getNode(_ name: String) async throws -> K8sNode { try await get("/api/v1/nodes/\(e(name))") }
    func listPods(nodeName: String? = nil) async throws -> K8sPodList {
        if let nodeName, !nodeName.isEmpty {
            return try await get("/api/v1/pods?fieldSelector=spec.nodeName=\(e(nodeName))")
        }
        return try await get("/api/v1/pods")
    }
    func getPodLogs(namespace: String, pod: String, tailLines: Int = 200) async throws -> String {
        try await getRaw("/api/v1/namespaces/\(e(namespace))/pods/\(e(pod))/log?tailLines=\(tailLines)")
    }
    func deletePod(namespace: String, pod: String) async throws {
        _ = try await execute("/api/v1/namespaces/\(e(namespace))/pods/\(e(pod))", method: "DELETE")
    }
    func scaleDeployment(namespace: String, name: String, replicas: Int) async throws {
        let body = "{\"spec\":{\"replicas\":\(replicas)}}"
        _ = try await execute("/apis/apps/v1/namespaces/\(e(namespace))/deployments/\(e(name))/scale", method: "PATCH", body: body, contentType: "application/merge-patch+json")
    }
    func getNodeMetrics() async throws -> K8sNodeMetricsList { try await get("/apis/metrics.k8s.io/v1beta1/nodes") }
    func getPodMetrics(nodeName: String) async throws -> K8sPodMetricsList { try await get("/apis/metrics.k8s.io/v1beta1/pods?fieldSelector=spec.nodeName=\(e(nodeName))") }
    func listEvents(limit: Int = 50) async throws -> K8sEventList { try await get("/api/v1/events?limit=\(limit)") }
    func listDeployments() async throws -> K8sDeploymentList { try await get("/apis/apps/v1/deployments") }
    func listDaemonSets() async throws -> K8sDaemonSetList { try await get("/apis/apps/v1/daemonsets") }
    func listStatefulSets() async throws -> K8sStatefulSetList { try await get("/apis/apps/v1/statefulsets") }
    func listCronJobs() async throws -> K8sCronJobList { try await get("/apis/batch/v1/cronjobs") }
    func listServices() async throws -> K8sServiceList { try await get("/api/v1/services") }
    func listIngresses() async throws -> K8sIngressList { try await get("/apis/networking.k8s.io/v1/ingresses") }
    func listNamespaces() async throws -> K8sNamespaceList { try await get("/api/v1/namespaces") }
    func listPVCs() async throws -> K8sPVCList { try await get("/api/v1/persistentvolumeclaims") }
    func listPVs() async throws -> K8sPVList { try await get("/api/v1/persistentvolumes") }
    func getNodeMetric(_ name: String) async throws -> K8sNodeMetrics { try await get("/apis/metrics.k8s.io/v1beta1/nodes/\(e(name))") }
    func listConfigMaps(namespace: String? = nil) async throws -> K8sConfigMapList {
        if let ns = namespace {
            return try await get("/api/v1/namespaces/\(e(ns))/configmaps")
        }
        return try await get("/api/v1/configmaps")
    }
    func listSecrets(namespace: String? = nil) async throws -> K8sSecretList {
        if let ns = namespace {
            return try await get("/api/v1/namespaces/\(e(ns))/secrets")
        }
        return try await get("/api/v1/secrets")
    }
    func getSecret(namespace: String, name: String) async throws -> K8sSecret {
        try await get("/api/v1/namespaces/\(e(namespace))/secrets/\(e(name))")
    }

    func listHelmSecrets() async throws -> K8sSecretList {
        try await get("/api/v1/secrets?labelSelector=owner%3Dhelm")
    }

    /// Triggers a rollout restart by patching the deployment with a restart annotation (equivalent to `kubectl rollout restart`).
    func restartDeployment(namespace: String, name: String) async throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let body = """
        {"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt":"\(timestamp)"}}}}}
        """
        _ = try await execute("/apis/apps/v1/namespaces/\(e(namespace))/deployments/\(e(name))", method: "PATCH", body: body, contentType: "application/strategic-merge-patch+json")
    }

    // MARK: - Exec (command execution in pod via SPDY/WebSocket)

    /// Runs a command in an ephemeral job, collects output via pod logs, then cleans up.
    /// This works without WebSocket/SPDY support.
    func runCommandInPod(namespace: String, image: String = "alpine:latest", command: [String]) async throws -> String {
        let jobName = "civo-exec-\(UUID().uuidString.prefix(8).lowercased())"
        let cmdJson = try JSONSerialization.data(withJSONObject: command)
        let cmdStr = String(data: cmdJson, encoding: .utf8) ?? "[]"

        let ns = e(namespace)
        let jobBody = """
        {
            "apiVersion": "batch/v1",
            "kind": "Job",
            "metadata": {"name": "\(jobName)", "namespace": "\(namespace)"},
            "spec": {
                "backoffLimit": 0,
                "ttlSecondsAfterFinished": 10,
                "template": {
                    "spec": {
                        "restartPolicy": "Never",
                        "containers": [{
                            "name": "exec",
                            "image": "\(image)",
                            "command": \(cmdStr)
                        }]
                    }
                }
            }
        }
        """

        // Create job
        _ = try await execute(
            "/apis/batch/v1/namespaces/\(ns)/jobs",
            method: "POST",
            body: jobBody
        )

        // Wait for completion (poll every 2s, max 60s)
        var output = ""
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(2))

            // Check job status
            let statusData = try await execute("/apis/batch/v1/namespaces/\(ns)/jobs/\(jobName)")
            if let statusJson = try? JSONSerialization.jsonObject(with: statusData) as? [String: Any],
               let status = statusJson["status"] as? [String: Any] {
                if status["succeeded"] as? Int == 1 {
                    // Get pod name
                    let podsData = try await execute("/api/v1/namespaces/\(ns)/pods?labelSelector=job-name%3D\(jobName)")
                    if let podsJson = try? JSONSerialization.jsonObject(with: podsData) as? [String: Any],
                       let items = podsJson["items"] as? [[String: Any]],
                       let podMeta = items.first?["metadata"] as? [String: Any],
                       let podName = podMeta["name"] as? String {
                        output = try await getRaw("/api/v1/namespaces/\(ns)/pods/\(e(podName))/log")
                    }
                    break
                }
                if status["failed"] as? Int ?? 0 > 0 {
                    output = "Command failed"
                    break
                }
            }
        }

        // Cleanup
        _ = try? await execute(
            "/apis/batch/v1/namespaces/\(ns)/jobs/\(jobName)?propagationPolicy=Background",
            method: "DELETE"
        )

        return output
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await execute(path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func getRaw(_ path: String) async throws -> String {
        let data = try await execute(path)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func execute(_ path: String, method: String = "GET", body: String? = nil, contentType: String = "application/json") async throws -> Data {
        guard !isInvalidated else {
            throw URLError(.cancelled)
        }
        guard let url = URL(string: "\(server)\(path)") else {
            throw K8sAPIError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        if let body { request.httpBody = body.data(using: .utf8) }

        guard !isInvalidated else {
            throw URLError(.cancelled)
        }
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }
        return data
    }

    // MARK: - Identity via Security.framework (no openssl dependency)

    private static func createIdentity(certPEM: Data, keyPEM: Data) throws -> SecIdentity {
        // Import client certificate from PEM
        var certItems: CFArray?
        var certFormat = SecExternalFormat.formatPEMSequence
        var certType = SecExternalItemType.itemTypeCertificate
        let certStatus = SecItemImport(certPEM as CFData, nil, &certFormat, &certType, [], nil, nil, &certItems)
        guard certStatus == errSecSuccess,
              let certs = certItems as? [SecCertificate],
              let cert = certs.first else {
            throw K8sAPIError.invalidCertificate("Client certificate import failed: \(certStatus)")
        }

        // Import private key from PEM (use formatUnknown to handle RSA, EC, and PKCS#8 keys)
        var keyItems: CFArray?
        var keyFormat = SecExternalFormat.formatUnknown
        var keyType = SecExternalItemType.itemTypePrivateKey
        let keyParams = SecItemImportExportKeyParameters()
        var keyParamsMutable = keyParams
        var keyStatus = SecItemImport(keyPEM as CFData, nil, &keyFormat, &keyType, [], &keyParamsMutable, nil, &keyItems)

        // Fallback: try with .pem file extension hint if auto-detect fails
        if keyStatus != errSecSuccess {
            keyFormat = SecExternalFormat.formatUnknown
            keyType = SecExternalItemType.itemTypePrivateKey
            keyItems = nil
            let pemHint = "key.pem" as CFString
            keyStatus = SecItemImport(keyPEM as CFData, pemHint, &keyFormat, &keyType, [], &keyParamsMutable, nil, &keyItems)
        }

        guard keyStatus == errSecSuccess,
              let keys = keyItems as? [SecKey],
              let privateKey = keys.first else {
            throw K8sAPIError.invalidCertificate("Private key import failed: \(keyStatus)")
        }

        // Create identity directly from certificate + private key (macOS only)
        guard let identity = SecIdentityCreate(nil, cert, privateKey) else {
            throw K8sAPIError.invalidCertificate("Failed to create identity from certificate and key")
        }

        return identity
    }
}

// MARK: - Errors

enum K8sAPIError: LocalizedError {
    case invalidCertificate(String)
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidCertificate(let detail): return "Certificate error: \(detail)"
        case .httpError(let code, let msg): return "K8s API error (\(code)): \(msg)"
        }
    }
}
