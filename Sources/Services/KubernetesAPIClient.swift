import Foundation
import Security

final class KubernetesAPIClient: NSObject, @unchecked Sendable {
    private let server: String
    private let caCertDER: Data
    private let clientCertDER: Data
    private let clientKeyPEM: Data

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server
        self.caCertDER = credentials.caCertDER
        self.clientCertDER = credentials.clientCertDER
        self.clientKeyPEM = credentials.clientKeyPEM
        super.init()
    }

    // MARK: - K8s API

    func listNodes() async throws -> K8sNodeList {
        try await get("/api/v1/nodes")
    }

    func getNode(_ name: String) async throws -> K8sNode {
        try await get("/api/v1/nodes/\(name)")
    }

    func listPods(nodeName: String? = nil) async throws -> K8sPodList {
        if let nodeName, !nodeName.isEmpty {
            return try await get("/api/v1/pods?fieldSelector=spec.nodeName=\(nodeName)")
        }
        return try await get("/api/v1/pods")
    }

    func getPodLogs(namespace: String, pod: String, tailLines: Int = 200) async throws -> String {
        try await getRaw("/api/v1/namespaces/\(namespace)/pods/\(pod)/log?tailLines=\(tailLines)")
    }

    func getNodeMetrics() async throws -> K8sNodeMetricsList {
        try await get("/apis/metrics.k8s.io/v1beta1/nodes")
    }

    func getPodMetrics(nodeName: String) async throws -> K8sPodMetricsList {
        try await get("/apis/metrics.k8s.io/v1beta1/pods?fieldSelector=spec.nodeName=\(nodeName)")
    }

    func listEvents(limit: Int = 50) async throws -> K8sEventList {
        try await get("/api/v1/events?limit=\(limit)")
    }

    func listDeployments() async throws -> K8sDeploymentList {
        try await get("/apis/apps/v1/deployments")
    }

    func listDaemonSets() async throws -> K8sDaemonSetList {
        try await get("/apis/apps/v1/daemonsets")
    }

    func listStatefulSets() async throws -> K8sStatefulSetList {
        try await get("/apis/apps/v1/statefulsets")
    }

    func listCronJobs() async throws -> K8sCronJobList {
        try await get("/apis/batch/v1/cronjobs")
    }

    func listServices() async throws -> K8sServiceList {
        try await get("/api/v1/services")
    }

    func listIngresses() async throws -> K8sIngressList {
        try await get("/apis/networking.k8s.io/v1/ingresses")
    }

    func listNamespaces() async throws -> K8sNamespaceList {
        try await get("/api/v1/namespaces")
    }

    func listPVCs() async throws -> K8sPVCList {
        try await get("/api/v1/persistentvolumeclaims")
    }

    func getNodeMetric(_ name: String) async throws -> K8sNodeMetrics {
        try await get("/apis/metrics.k8s.io/v1beta1/nodes/\(name)")
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, _) = try await execute(path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func getRaw(_ path: String) async throws -> String {
        let (data, _) = try await execute(path)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func execute(_ path: String) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "\(server)\(path)") else {
            throw K8sAPIError.invalidCertificate("Invalid URL: \(server)\(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        // Use curl-style approach: write certs to temp files, use URLSession with trust-all delegate
        let identity = try createIdentity()
        let delegate = K8sSessionDelegate(identity: identity, caCertDER: caCertDER)
        let config = URLSessionConfiguration.ephemeral
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw K8sAPIError.httpError(0, "Invalid response")
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError(http.statusCode, msg)
        }

        return (data, http)
    }

    // MARK: - Identity Creation

    private func createIdentity() throws -> SecIdentity {
        // Create cert
        guard let cert = SecCertificateCreateWithData(nil, clientCertDER as CFData) else {
            throw K8sAPIError.invalidCertificate("Client certificate: invalid DER (\(clientCertDER.count) bytes)")
        }

        // Import private key
        let key = try Self.importPrivateKey(clientKeyPEM)

        // Add to keychain to create identity
        let tag = "de.berger-rosenstock.CivoCloudManager.k8s-\(ProcessInfo.processInfo.processIdentifier)".data(using: .utf8)!

        // Clean up any previous entries with this tag
        SecItemDelete([
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "civo-k8s-client",
        ] as CFDictionary)
        SecItemDelete([
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
        ] as CFDictionary)

        // Add certificate
        let certStatus = SecItemAdd([
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrLabel as String: "civo-k8s-client",
        ] as CFDictionary, nil)
        guard certStatus == errSecSuccess || certStatus == errSecDuplicateItem else {
            throw K8sAPIError.invalidCertificate("Keychain cert add failed: \(certStatus)")
        }

        // Add private key
        let keyStatus = SecItemAdd([
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: key,
            kSecAttrApplicationTag as String: tag,
        ] as CFDictionary, nil)
        guard keyStatus == errSecSuccess || keyStatus == errSecDuplicateItem else {
            throw K8sAPIError.invalidCertificate("Keychain key add failed: \(keyStatus)")
        }

        // Find identity
        var identityRef: CFTypeRef?
        let findStatus = SecItemCopyMatching([
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ] as CFDictionary, &identityRef)

        guard findStatus == errSecSuccess, let identity = identityRef else {
            throw K8sAPIError.invalidCertificate("Identity not found: \(findStatus)")
        }

        return (identity as! SecIdentity)
    }

    private static func importPrivateKey(_ pemData: Data) throws -> SecKey {
        guard let pemString = String(data: pemData, encoding: .utf8) else {
            throw K8sAPIError.invalidCertificate("Private key: invalid encoding")
        }

        let stripped = pemString
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-----") }
            .joined()

        guard let derData = Data(base64Encoded: stripped, options: .ignoreUnknownCharacters) else {
            throw K8sAPIError.invalidCertificate("Private key: base64 decode failed")
        }

        // Try EC first (k3s uses EC), then RSA
        for keyType in [kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyTypeRSA] {
            var error: Unmanaged<CFError>?
            if let key = SecKeyCreateWithData(derData as CFData, [
                kSecAttrKeyType as String: keyType,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            ] as CFDictionary, &error) {
                return key
            }
        }

        // Fallback: SecItemImport
        var items: CFArray?
        var format = SecExternalFormat.formatUnknown
        var type = SecExternalItemType.itemTypePrivateKey
        let status = SecItemImport(derData as CFData, nil, &format, &type, [], nil, nil, &items)
        if status == errSecSuccess, let arr = items as? [Any], let key = arr.first {
            return (key as! SecKey)
        }

        throw K8sAPIError.invalidCertificate("Private key import failed (EC/RSA/PKCS#8)")
    }
}

// MARK: - Session Delegate

final class K8sSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let identity: SecIdentity
    private let caCertDER: Data

    init(identity: SecIdentity, caCertDER: Data) {
        self.identity = identity
        self.caCertDER = caCertDER
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let method = challenge.protectionSpace.authenticationMethod

        if method == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust
        {
            // Trust the server using our CA cert
            if let caCert = SecCertificateCreateWithData(nil, caCertDER as CFData) {
                SecTrustSetAnchorCertificates(serverTrust, [caCert] as CFArray)
                SecTrustSetAnchorCertificatesOnly(serverTrust, true)
            }
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
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
