import Foundation
import Security

final class KubernetesAPIClient: NSObject, @unchecked Sendable {
    private let server: String
    private let caCert: SecCertificate
    private let clientCert: SecCertificate
    private let clientKey: SecKey

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        guard let ca = SecCertificateCreateWithData(nil, credentials.caCertDER as CFData) else {
            throw K8sAPIError.invalidCertificate("CA certificate: invalid DER data")
        }
        self.caCert = ca

        guard let cert = SecCertificateCreateWithData(nil, credentials.clientCertDER as CFData) else {
            throw K8sAPIError.invalidCertificate("Client certificate: invalid DER data")
        }
        self.clientCert = cert

        self.clientKey = try Self.importPrivateKey(credentials.clientKeyPEM)

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

        let delegate = K8sSessionDelegate(
            caCert: caCert,
            clientCert: clientCert,
            clientKey: clientKey
        )
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
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

    // MARK: - Private Key Import

    private static func importPrivateKey(_ pemData: Data) throws -> SecKey {
        guard let pemString = String(data: pemData, encoding: .utf8) else {
            throw K8sAPIError.invalidCertificate("Private key: invalid encoding")
        }

        // Strip PEM headers and decode to DER
        let stripped = pemString
            .components(separatedBy: "\n")
            .filter { !$0.hasPrefix("-----") }
            .joined()

        guard let derData = Data(base64Encoded: stripped, options: .ignoreUnknownCharacters) else {
            throw K8sAPIError.invalidCertificate("Private key: base64 decode failed")
        }

        // Try EC key first (k3s uses EC), then RSA
        let keyTypes: [(SecAttrKeyType: CFString, name: String)] = [
            (kSecAttrKeyTypeECSECPrimeRandom, "EC"),
            (kSecAttrKeyTypeRSA, "RSA"),
        ]

        for keyType in keyTypes {
            let attrs: [String: Any] = [
                kSecAttrKeyType as String: keyType.SecAttrKeyType,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            ]
            var error: Unmanaged<CFError>?
            if let key = SecKeyCreateWithData(derData as CFData, attrs as CFDictionary, &error) {
                return key
            }
        }

        // Fallback: use SecItemImport for PKCS#8 wrapped keys
        var items: CFArray?
        var format = SecExternalFormat.formatUnknown
        var type = SecExternalItemType.itemTypePrivateKey
        let status = SecItemImport(
            derData as CFData,
            nil,
            &format,
            &type,
            [],
            nil,
            nil,
            &items
        )

        if status == errSecSuccess, let arr = items as? [Any], let key = arr.first {
            return (key as! SecKey)
        }

        throw K8sAPIError.invalidCertificate("Private key: unsupported format (tried EC, RSA, PKCS#8)")
    }
}

// MARK: - Session Delegate

final class K8sSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let caCert: SecCertificate
    private let clientCert: SecCertificate
    private let clientKey: SecKey

    init(caCert: SecCertificate, clientCert: SecCertificate, clientKey: SecKey) {
        self.caCert = caCert
        self.clientCert = clientCert
        self.clientKey = clientKey
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async
        -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        let method = challenge.protectionSpace.authenticationMethod

        if method == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust
        {
            SecTrustSetAnchorCertificates(serverTrust, [caCert] as CFArray)
            SecTrustSetAnchorCertificatesOnly(serverTrust, true)
            return (.useCredential, URLCredential(trust: serverTrust))
        }

        if method == NSURLAuthenticationMethodClientCertificate {
            // Create identity from cert + key using keychain
            let credential = try? createClientCredential()
            if let credential {
                return (.useCredential, credential)
            }
            return (.cancelAuthenticationChallenge, nil)
        }

        return (.performDefaultHandling, nil)
    }

    private func createClientCredential() throws -> URLCredential {
        // Add cert to keychain temporarily
        let certLabel = "civo-k8s-tmp-\(UUID().uuidString)"
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: clientCert,
            kSecAttrLabel as String: certLabel,
        ]
        SecItemDelete(certQuery as CFDictionary)
        SecItemAdd(certQuery as CFDictionary, nil)

        // Add key to keychain temporarily
        let keyLabel = "civo-k8s-key-\(UUID().uuidString)"
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: clientKey,
            kSecAttrLabel as String: keyLabel,
            kSecAttrApplicationTag as String: "de.berger-rosenstock.k8s".data(using: .utf8)!,
        ]
        SecItemDelete(keyQuery as CFDictionary)
        SecItemAdd(keyQuery as CFDictionary, nil)

        // Find identity
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(identityQuery as CFDictionary, &result)

        // Cleanup temporary items
        SecItemDelete(certQuery as CFDictionary)
        SecItemDelete(keyQuery as CFDictionary)

        guard status == errSecSuccess, let identity = result else {
            throw K8sAPIError.invalidCertificate("Could not create identity from cert+key")
        }

        return URLCredential(
            identity: identity as! SecIdentity,
            certificates: [clientCert],
            persistence: .forSession
        )
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
