import Foundation

enum IPDetectorError: LocalizedError {
    case noIPReturned
    case invalidIP(String)
    case allProvidersFailed

    var errorDescription: String? {
        switch self {
        case .noIPReturned:
            return "No IP address returned"
        case .invalidIP(let ip):
            return "Invalid IP address: \(ip)"
        case .allProvidersFailed:
            return "All IP detection providers failed"
        }
    }
}

final class IPDetector: Sendable {
    private let providers: [String] = [
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://icanhazip.com",
    ]

    func detectIP() async throws -> String {
        var lastError: Error = IPDetectorError.allProvidersFailed

        for provider in providers {
            do {
                guard let url = URL(string: provider) else { continue }
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    continue
                }

                guard let ip = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                      !ip.isEmpty else {
                    continue
                }

                // Basic IPv4 validation
                let parts = ip.split(separator: ".")
                if parts.count == 4, parts.allSatisfy({ Int($0) != nil && Int($0)! >= 0 && Int($0)! <= 255 }) {
                    Log.info("Detected public IP: \(ip) via \(provider)")
                    return ip
                } else {
                    Log.warning("Invalid IP format from \(provider): \(ip)")
                    continue
                }
            } catch {
                lastError = error
                Log.warning("IP detection failed for \(provider): \(error.localizedDescription)")
                continue
            }
        }

        throw lastError
    }
}
