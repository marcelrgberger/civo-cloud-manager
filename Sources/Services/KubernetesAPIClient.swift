import Foundation
import Security

final class KubernetesAPIClient: NSObject, @unchecked Sendable {
    private let server: String
    private let identity: SecIdentity
    private let caCert: SecCertificate

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        // Import CA cert via SecItemImport (handles PEM natively)
        var caItems: CFArray?
        var caFormat = SecExternalFormat.formatPEMSequence
        var caType = SecExternalItemType.itemTypeCertificate
        let caStatus = SecItemImport(credentials.caCertPEM as CFData, nil, &caFormat, &caType, [], nil, nil, &caItems)
        guard caStatus == errSecSuccess, let caCerts = caItems as? [SecCertificate], let ca = caCerts.first else {
            throw K8sAPIError.invalidCertificate("CA import failed: \(caStatus)")
        }
        self.caCert = ca

        // Import client cert
        var certItems: CFArray?
        var certFormat = SecExternalFormat.formatPEMSequence
        var certType = SecExternalItemType.itemTypeCertificate
        let certStatus = SecItemImport(credentials.clientCertPEM as CFData, nil, &certFormat, &certType, [], nil, nil, &certItems)
        guard certStatus == errSecSuccess, let certs = certItems as? [SecCertificate], let clientCert = certs.first else {
            throw K8sAPIError.invalidCertificate("Client cert import failed: \(certStatus)")
        }

        // Import private key via SecItemImport with OpenSSL format
        var keyItems: CFArray?
        var keyFormat = SecExternalFormat.formatOpenSSL
        var keyType = SecExternalItemType.itemTypePrivateKey
        let keyStatus = SecItemImport(credentials.clientKeyPEM as CFData, nil, &keyFormat, &keyType, [], nil, nil, &keyItems)
        guard keyStatus == errSecSuccess, let keys = keyItems as? [Any], let privateKey = keys.first else {
            throw K8sAPIError.invalidCertificate("Key import failed: \(keyStatus)")
        }

        // Create identity: add cert+key to keychain, find matching identity
        let tag = "de.berger-rosenstock.civo.k8s"

        // Cleanup previous
        SecItemDelete([kSecClass as String: kSecClassCertificate, kSecAttrLabel as String: tag] as CFDictionary)
        SecItemDelete([kSecClass as String: kSecClassKey, kSecAttrLabel as String: tag] as CFDictionary)

        // Add cert
        let addCertStatus = SecItemAdd([
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: clientCert,
            kSecAttrLabel as String: tag,
        ] as CFDictionary, nil)
        guard addCertStatus == errSecSuccess || addCertStatus == errSecDuplicateItem else {
            throw K8sAPIError.invalidCertificate("Keychain cert add: \(addCertStatus)")
        }

        // Add key
        let addKeyStatus = SecItemAdd([
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrLabel as String: tag,
        ] as CFDictionary, nil)
        guard addKeyStatus == errSecSuccess || addKeyStatus == errSecDuplicateItem else {
            throw K8sAPIError.invalidCertificate("Keychain key add: \(addKeyStatus)")
        }

        // Find identity
        var identityRef: CFTypeRef?
        let findStatus = SecItemCopyMatching([
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ] as CFDictionary, &identityRef)
        guard findStatus == errSecSuccess, let id = identityRef else {
            throw K8sAPIError.invalidCertificate("Identity not found: \(findStatus)")
        }
        self.identity = (id as! SecIdentity)

        super.init()
    }

    // MARK: - K8s API

    func listNodes() async throws -> K8sNodeList { try await get("/api/v1/nodes") }
    func getNode(_ name: String) async throws -> K8sNode { try await get("/api/v1/nodes/\(name)") }
    func listPods(nodeName: String? = nil) async throws -> K8sPodList {
        if let nodeName, !nodeName.isEmpty {
            return try await get("/api/v1/pods?fieldSelector=spec.nodeName=\(nodeName)")
        }
        return try await get("/api/v1/pods")
    }
    func getPodLogs(namespace: String, pod: String, tailLines: Int = 200) async throws -> String {
        try await getRaw("/api/v1/namespaces/\(namespace)/pods/\(pod)/log?tailLines=\(tailLines)")
    }
    func getNodeMetrics() async throws -> K8sNodeMetricsList { try await get("/apis/metrics.k8s.io/v1beta1/nodes") }
    func getPodMetrics(nodeName: String) async throws -> K8sPodMetricsList { try await get("/apis/metrics.k8s.io/v1beta1/pods?fieldSelector=spec.nodeName=\(nodeName)") }
    func listEvents(limit: Int = 50) async throws -> K8sEventList { try await get("/api/v1/events?limit=\(limit)") }
    func listDeployments() async throws -> K8sDeploymentList { try await get("/apis/apps/v1/deployments") }
    func listDaemonSets() async throws -> K8sDaemonSetList { try await get("/apis/apps/v1/daemonsets") }
    func listStatefulSets() async throws -> K8sStatefulSetList { try await get("/apis/apps/v1/statefulsets") }
    func listCronJobs() async throws -> K8sCronJobList { try await get("/apis/batch/v1/cronjobs") }
    func listServices() async throws -> K8sServiceList { try await get("/api/v1/services") }
    func listIngresses() async throws -> K8sIngressList { try await get("/apis/networking.k8s.io/v1/ingresses") }
    func listNamespaces() async throws -> K8sNamespaceList { try await get("/api/v1/namespaces") }
    func listPVCs() async throws -> K8sPVCList { try await get("/api/v1/persistentvolumeclaims") }
    func getNodeMetric(_ name: String) async throws -> K8sNodeMetrics { try await get("/apis/metrics.k8s.io/v1beta1/nodes/\(name)") }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await execute(path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func getRaw(_ path: String) async throws -> String {
        let data = try await execute(path)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func execute(_ path: String) async throws -> Data {
        guard let url = URL(string: "\(server)\(path)") else {
            throw K8sAPIError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let delegate = K8sSessionDelegate(identity: identity, caCert: caCert)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }
        return data
    }
}

// MARK: - Session Delegate

final class K8sSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let identity: SecIdentity
    private let caCert: SecCertificate

    init(identity: SecIdentity, caCert: SecCertificate) {
        self.identity = identity
        self.caCert = caCert
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
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
