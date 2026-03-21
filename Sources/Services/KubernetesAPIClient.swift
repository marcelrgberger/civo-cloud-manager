import Foundation
import Security

final class KubernetesAPIClient: NSObject, @unchecked Sendable, URLSessionDelegate {
    private let server: String
    private let identity: SecIdentity
    private let caCert: SecCertificate
    private lazy var session: URLSession = {
        URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    }()

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        // Import CA cert
        var caItems: CFArray?
        var caFormat = SecExternalFormat.formatPEMSequence
        var caType = SecExternalItemType.itemTypeCertificate
        let caStatus = SecItemImport(credentials.caCertPEM as CFData, nil, &caFormat, &caType, [], nil, nil, &caItems)
        guard caStatus == errSecSuccess, let caCerts = caItems as? [SecCertificate], let ca = caCerts.first else {
            throw K8sAPIError.invalidCertificate("CA import failed: \(caStatus)")
        }
        self.caCert = ca

        // Create PKCS#12 from cert+key via openssl, then import identity
        self.identity = try Self.createIdentityViaPKCS12(
            certPEM: credentials.clientCertPEM,
            keyPEM: credentials.clientKeyPEM
        )

        super.init()
    }

    deinit {
        session.invalidateAndCancel()
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
    func listPVs() async throws -> K8sPVList { try await get("/api/v1/persistentvolumes") }
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

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw K8sAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, msg)
        }
        return data
    }

    // MARK: - URLSessionDelegate

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

    // MARK: - PKCS#12 Identity Creation

    private static func createIdentityViaPKCS12(certPEM: Data, keyPEM: Data) throws -> SecIdentity {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("civo-k8s-p12-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let certPath = tmpDir.appendingPathComponent("cert.pem")
        let keyPath = tmpDir.appendingPathComponent("key.pem")
        let p12Path = tmpDir.appendingPathComponent("client.p12")
        let password = UUID().uuidString

        try certPEM.write(to: certPath)
        try keyPEM.write(to: keyPath)

        // Create PKCS#12 via openssl
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        process.arguments = [
            "pkcs12", "-export",
            "-out", p12Path.path,
            "-inkey", keyPath.path,
            "-in", certPath.path,
            "-passout", "pass:\(password)",
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw K8sAPIError.invalidCertificate("openssl pkcs12 failed: exit \(process.terminationStatus)")
        }

        // Import PKCS#12
        let p12Data = try Data(contentsOf: p12Path)
        var items: CFArray?
        let status = SecPKCS12Import(
            p12Data as CFData,
            [kSecImportExportPassphrase as String: password] as CFDictionary,
            &items
        )

        guard status == errSecSuccess,
              let dicts = items as? [[String: Any]],
              let dict = dicts.first,
              let identity = dict[kSecImportItemIdentity as String] else {
            throw K8sAPIError.invalidCertificate("PKCS#12 import failed: \(status)")
        }

        return (identity as! SecIdentity)
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
