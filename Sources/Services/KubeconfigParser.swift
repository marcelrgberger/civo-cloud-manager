import Foundation

struct KubeconfigCredentials: Sendable {
    let server: String
    let caCertPEM: Data
    let clientCertPEM: Data
    let clientKeyPEM: Data
}

enum KubeconfigParser {
    static func parse(_ yaml: String) throws -> KubeconfigCredentials {
        guard let server = extractValue(yaml, key: "server") else {
            throw KubeconfigError.missingField("server")
        }
        guard let caB64 = extractValue(yaml, key: "certificate-authority-data") else {
            throw KubeconfigError.missingField("certificate-authority-data")
        }
        guard let certB64 = extractValue(yaml, key: "client-certificate-data") else {
            throw KubeconfigError.missingField("client-certificate-data")
        }
        guard let keyB64 = extractValue(yaml, key: "client-key-data") else {
            throw KubeconfigError.missingField("client-key-data")
        }

        // Base64 decode → PEM text (keep as-is for curl)
        guard let caPEM = Data(base64Encoded: caB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("certificate-authority-data")
        }
        guard let certPEM = Data(base64Encoded: certB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("client-certificate-data")
        }
        guard let keyPEM = Data(base64Encoded: keyB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("client-key-data")
        }

        return KubeconfigCredentials(
            server: server,
            caCertPEM: caPEM,
            clientCertPEM: certPEM,
            clientKeyPEM: keyPEM
        )
    }

    private static func extractValue(_ yaml: String, key: String) -> String? {
        let pattern = "\(key):\\s*(.+)"
        guard let range = yaml.range(of: pattern, options: .regularExpression) else { return nil }
        let match = String(yaml[range])
        let value = match.replacingOccurrences(of: "\(key):", with: "").trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }
}

enum KubeconfigError: LocalizedError {
    case missingField(String)
    case invalidBase64(String)

    var errorDescription: String? {
        switch self {
        case .missingField(let field): return "Missing kubeconfig field: \(field)"
        case .invalidBase64(let field): return "Invalid base64 in kubeconfig: \(field)"
        }
    }
}
