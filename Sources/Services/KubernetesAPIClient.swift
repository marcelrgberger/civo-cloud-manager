import Foundation
import Security

final class KubernetesAPIClient: NSObject, @unchecked Sendable, URLSessionDelegate {
    private let server: String
    private let session: URLSession
    private let identity: SecIdentity
    private let caCert: SecCertificate

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        guard let ca = SecCertificateCreateWithData(nil, credentials.caCertData as CFData) else {
            throw K8sAPIError.invalidCertificate("CA certificate")
        }
        self.caCert = ca

        self.identity = try Self.createIdentity(
            certData: credentials.clientCertData,
            keyData: credentials.clientKeyData
        )

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        super.init()
    }

    // MARK: - K8s API

    func listNodes() async throws -> K8sNodeList {
        try await get("/api/v1/nodes")
    }

    func getNode(_ name: String) async throws -> K8sNode {
        try await get("/api/v1/nodes/\(name)")
    }

    func listPods(nodeName: String) async throws -> K8sPodList {
        let query = "spec.nodeName=\(nodeName)"
        return try await get("/api/v1/pods?fieldSelector=\(query)")
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

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(server)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let delegate = K8sSessionDelegate(identity: identity, caCert: caCert)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func getRaw(_ path: String) async throws -> String {
        let url = URL(string: "\(server)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let delegate = K8sSessionDelegate(identity: identity, caCert: caCert)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Identity

    private static func createIdentity(certData: Data, keyData: Data) throws -> SecIdentity {
        guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw K8sAPIError.invalidCertificate("client certificate")
        }

        // Import private key
        let keyDict: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048,
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(keyData as CFData, keyDict as CFDictionary, &error) else {
            throw K8sAPIError.invalidCertificate("private key: \(error?.takeRetainedValue().localizedDescription ?? "unknown")")
        }

        // Add cert and key to keychain temporarily
        let certAddQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrLabel as String: "civo-k8s-client-cert",
        ]
        SecItemDelete(certAddQuery as CFDictionary)
        SecItemAdd(certAddQuery as CFDictionary, nil)

        let keyAddQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrLabel as String: "civo-k8s-client-key",
            kSecAttrApplicationTag as String: "de.berger-rosenstock.CivoCloudManager.k8s".data(using: .utf8)!,
        ]
        SecItemDelete(keyAddQuery as CFDictionary)
        SecItemAdd(keyAddQuery as CFDictionary, nil)

        // Get identity
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(identityQuery as CFDictionary, &result)
        guard status == errSecSuccess, let identity = result else {
            throw K8sAPIError.invalidCertificate("Could not create identity (status: \(status))")
        }

        return (identity as! SecIdentity)
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

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let method = challenge.protectionSpace.authenticationMethod

        if method == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            SecTrustSetAnchorCertificates(serverTrust, [caCert] as CFArray)
            SecTrustSetAnchorCertificatesOnly(serverTrust, true)
            return (.useCredential, URLCredential(trust: serverTrust))
        }

        if method == NSURLAuthenticationMethodClientCertificate {
            return (.useCredential, URLCredential(
                identity: identity,
                certificates: nil,
                persistence: .forSession
            ))
        }

        return (.performDefaultHandling, nil)
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
