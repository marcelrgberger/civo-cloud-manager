import Foundation

enum IPDetectorError: LocalizedError {
    case noIPReturned
    case invalidIP(String)
    case allProvidersFailed
    case privateIP(String)
    case ipv6NotSupported(String)

    var errorDescription: String? {
        switch self {
        case .noIPReturned:
            return "No IP address returned"
        case .invalidIP(let ip):
            return "Invalid IP address: \(ip)"
        case .allProvidersFailed:
            return "All IP detection providers failed"
        case .privateIP(let ip):
            return "Detected private IP (\(ip)), not usable for firewall rules. Connect to a public network."
        case .ipv6NotSupported(let ip):
            return "IPv6 address detected (\(ip)). Civo firewall rules require IPv4. Connect to an IPv4 network."
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
                      httpResponse.statusCode == 200
                else {
                    continue
                }

                guard let ip = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                    !ip.isEmpty
                else {
                    continue
                }

                // Detect IPv6 (contains colon)
                if ip.contains(":") {
                    Log.warning("IPv6 address detected from \(provider): \(ip)")
                    throw IPDetectorError.ipv6NotSupported(ip)
                }

                // IPv4 validation
                let parts = ip.split(separator: ".")
                let octets = parts.compactMap { Int($0) }
                if parts.count == 4, octets.count == 4,
                    octets.allSatisfy({ $0 >= 0 && $0 <= 255 })
                {
                    // Check for private/reserved IP ranges
                    if isPrivateIP(ip) {
                        Log.warning("Private IP detected from \(provider): \(ip)")
                        throw IPDetectorError.privateIP(ip)
                    }

                    Log.info("Detected public IP: \(ip) via \(provider)")
                    return ip
                } else {
                    Log.warning("Invalid IP format from \(provider): \(ip)")
                    continue
                }
            } catch let error as IPDetectorError {
                // Re-throw our own errors immediately (IPv6, private IP)
                throw error
            } catch {
                lastError = error
                Log.warning("IP detection failed for \(provider): \(error.localizedDescription)")
                continue
            }
        }

        throw lastError
    }

    /// Check if an IPv4 address is in a private/reserved range.
    private func isPrivateIP(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }

        let first = parts[0]
        let second = parts[1]

        // 127.x.x.x (loopback)
        if first == 127 { return true }
        // 10.x.x.x (Class A private)
        if first == 10 { return true }
        // 172.16.0.0 - 172.31.255.255 (Class B private)
        if first == 172 && (16...31).contains(second) { return true }
        // 192.168.x.x (Class C private)
        if first == 192 && second == 168 { return true }
        // 169.254.x.x (link-local)
        if first == 169 && second == 254 { return true }

        return false
    }
}
