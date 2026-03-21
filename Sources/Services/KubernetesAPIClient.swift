import Foundation
import Security

final class KubernetesAPIClient: @unchecked Sendable {
    private let server: String
    private let caCertPath: String
    private let clientCertPath: String
    private let clientKeyPath: String

    init(credentials: KubeconfigCredentials) throws {
        self.server = credentials.server

        // Write certs to temp files for curl
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("civo-k8s-\(ProcessInfo.processInfo.processIdentifier)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let caPath = tmpDir.appendingPathComponent("ca.pem")
        let certPath = tmpDir.appendingPathComponent("client.pem")
        let keyPath = tmpDir.appendingPathComponent("client-key.pem")

        // Convert DER back to PEM for curl
        try Self.writePEM(credentials.caCertDER, label: "CERTIFICATE", to: caPath)
        try Self.writePEM(credentials.clientCertDER, label: "CERTIFICATE", to: certPath)
        try credentials.clientKeyPEM.write(to: keyPath)

        self.caCertPath = caPath.path
        self.clientCertPath = certPath.path
        self.clientKeyPath = keyPath.path
    }

    deinit {
        // Cleanup temp files
        let tmpDir = URL(fileURLWithPath: caCertPath).deletingLastPathComponent()
        try? FileManager.default.removeItem(at: tmpDir)
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

    // MARK: - HTTP via curl

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await execute(path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func getRaw(_ path: String) async throws -> String {
        let data = try await execute(path)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func execute(_ path: String) async throws -> Data {
        let url = "\(server)\(path)"

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [caCertPath, clientCertPath, clientKeyPath] in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
                process.arguments = [
                    "-s", "--fail-with-body",
                    "--cacert", caCertPath,
                    "--cert", clientCertPath,
                    "--key", clientKeyPath,
                    "-H", "Accept: application/json",
                    "--max-time", "30",
                    url,
                ]

                let pipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = pipe
                process.standardError = errorPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: data)
                    } else {
                        let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errMsg = String(data: errData, encoding: .utf8) ?? ""
                        let bodyMsg = String(data: data, encoding: .utf8) ?? ""
                        continuation.resume(throwing: K8sAPIError.httpError(
                            Int(process.terminationStatus),
                            "curl exit \(process.terminationStatus): \(bodyMsg) \(errMsg)".trimmingCharacters(in: .whitespaces)
                        ))
                    }
                } catch {
                    continuation.resume(throwing: K8sAPIError.httpError(0, "curl failed: \(error.localizedDescription)"))
                }
            }
        }
    }

    // MARK: - PEM Helpers

    private static func writePEM(_ derData: Data, label: String, to url: URL) throws {
        let base64 = derData.base64EncodedString(options: .lineLength76Characters)
        let pem = "-----BEGIN \(label)-----\n\(base64)\n-----END \(label)-----\n"
        try pem.write(to: url, atomically: true, encoding: .utf8)
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
