import Foundation

struct KubeconfigCredentials: Sendable {
    let server: String
    let caCertDER: Data
    let clientCertDER: Data
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

        // Base64 decode → PEM text
        guard let caRaw = Data(base64Encoded: caB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("certificate-authority-data")
        }
        guard let certRaw = Data(base64Encoded: certB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("client-certificate-data")
        }
        guard let keyRaw = Data(base64Encoded: keyB64, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("client-key-data")
        }

        // Convert PEM → DER for certificates
        let caDER = try pemToDER(caRaw, label: "CERTIFICATE")
        let certDER = try pemToDER(certRaw, label: "CERTIFICATE")

        return KubeconfigCredentials(
            server: server,
            caCertDER: caDER,
            clientCertDER: certDER,
            clientKeyPEM: keyRaw
        )
    }

    private static func pemToDER(_ data: Data, label: String) throws -> Data {
        guard let pemString = String(data: data, encoding: .utf8) else {
            // Already DER
            return data
        }

        let header = "-----BEGIN \(label)-----"
        let footer = "-----END \(label)-----"

        guard pemString.contains(header) else {
            // Not PEM, assume DER
            return data
        }

        let base64Content = pemString
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("-----") }
            .joined()

        guard let der = Data(base64Encoded: base64Content, options: .ignoreUnknownCharacters) else {
            throw KubeconfigError.invalidBase64("PEM to DER conversion failed for \(label)")
        }
        return der
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
