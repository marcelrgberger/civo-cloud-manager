import Foundation

/// Identifies a console window. Contains no secrets: SwiftUI may persist window values.
struct ConsoleTarget: Codable, Hashable, Sendable {
    let instanceId: String
    let instanceName: String
    /// Region the instance was fetched from, captured when the console is requested.
    let region: String

    // One window per instance and region; a renamed instance must not open a second window.
    static func == (lhs: ConsoleTarget, rhs: ConsoleTarget) -> Bool {
        lhs.instanceId == rhs.instanceId && lhs.region == rhs.region
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(instanceId)
        hasher.combine(region)
    }
}

/// Response of `PUT /v2/instances/{id}/vnc`.
struct ConsoleSessionResponse: Decodable, Sendable {
    let uri: String
    let duration: String?
}

/// Response of `POST /v2/auth/exchange`. Only the fields the console needs.
struct AuthTokenExchangeResponse: Decodable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    let accessToken: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }

    var description: String { "AuthTokenExchangeResponse(<redacted>)" }
    var debugDescription: String { description }
}

/// Builds and validates console URLs. The tokenized URL is a credential and must stay in memory only.
enum ConsoleURL {
    struct InvalidURL: Error, Equatable {}

    static let tokenParameter = "token"

    static func expectedHost(region: String) -> String {
        "vnc.\(region.lowercased()).civo.com"
    }

    /// Appends the JWT as `token` to the API-returned `uri` after validating its origin and path.
    static func make(uri: String, token: String, target: ConsoleTarget) throws -> URL {
        guard !token.isEmpty,
              var components = URLComponents(string: uri),
              isTrustedConsoleLocation(components, target: target),
              !carriesToken(components)
        else { throw InvalidURL() }
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: tokenParameter, value: token)]
        // URLComponents leaves "+" unescaped in queries, which servers may decode as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        guard let url = components.url else { throw InvalidURL() }
        return url
    }

    /// Navigation and redirect guard: the session URL itself, or same-origin console pages
    /// that carry no token of their own.
    static func isAllowedNavigation(_ url: URL, sessionURL: URL, target: ConsoleTarget) -> Bool {
        if url == sessionURL { return true }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return isTrustedConsoleLocation(components, target: target) && !carriesToken(components)
    }

    /// Token-free fallback that relies on the user's own dashboard login.
    static func dashboardURL(instanceId: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dashboard.civo.com"
        components.path = "/instances/\(instanceId)/console"
        return components.url
    }

    private static func carriesToken(_ components: URLComponents) -> Bool {
        (components.queryItems ?? []).contains { $0.name.lowercased() == tokenParameter }
    }

    private static func isTrustedConsoleLocation(_ components: URLComponents, target: ConsoleTarget) -> Bool {
        guard components.scheme?.lowercased() == "https",
              components.host?.lowercased() == expectedHost(region: target.region),
              components.user == nil, components.password == nil,
              components.port == nil || components.port == 443,
              !target.instanceId.isEmpty, !target.region.isEmpty
        else { return false }
        // Reject dot segments and encoded or alternative separators so the token cannot be
        // attached to a path that normalizes outside the instance.
        let rawPath = components.percentEncodedPath.lowercased()
        guard !rawPath.contains("%2f"), !rawPath.contains("%5c"), !rawPath.contains("%2e"),
              !rawPath.contains("\\")
        else { return false }
        let segments = rawPath.split(separator: "/", omittingEmptySubsequences: false)
        guard segments.count >= 3, segments.first == "", segments[1] == Substring(target.instanceId.lowercased()),
              !segments.contains(where: { $0 == "." || $0 == ".." })
        else { return false }
        return true
    }
}

/// Sanitized console failure. Never carries response bodies, URLs or underlying error text,
/// because console URLs contain the JWT.
enum ConsoleError: Error, Equatable, Sendable {
    case noAPIKey
    case noRegion
    case accountChanged
    case accessRevoked
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case server(Int)
    case unexpectedStatus(Int)
    case timedOut
    case offline
    case network(Int)
    case invalidResponse
    case invalidConsoleURL
    case notReady
    case pageLoadFailed
    case cancelled

    static func http(_ status: Int) -> ConsoleError {
        switch status {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 429: return .rateLimited
        case 500...599: return .server(status)
        default: return .unexpectedStatus(status)
        }
    }

    /// Maps any thrown error to a sanitized case. Underlying descriptions are discarded.
    static func sanitize(_ error: Error) -> ConsoleError {
        if let consoleError = error as? ConsoleError { return consoleError }
        if error is CancellationError { return .cancelled }
        if error is ConsoleURL.InvalidURL { return .invalidConsoleURL }
        if error is DecodingError { return .invalidResponse }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled: return .cancelled
            case .timedOut: return .timedOut
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: return .offline
            default: return .network(urlError.code.rawValue)
            }
        }
        return .network(0)
    }

    /// Fixed, non-sensitive text for `Log`.
    var logDescription: String {
        switch self {
        case .server(let code), .unexpectedStatus(let code): return "http-\(code)"
        case .network(let code): return "network-\(code)"
        default: return "\(self)"
        }
    }

    /// Localized text for the console window, or nil when nothing should be shown.
    var userMessage: String? {
        switch self {
        case .cancelled:
            return nil
        case .noAPIKey:
            return String(localized: "No Civo API key configured. Add your API key in Settings.")
        case .noRegion:
            return String(localized: "No region selected. Choose a region in Settings.")
        case .accountChanged:
            return String(localized: "The API key changed while this console was open. Close this window and open the console again.")
        case .accessRevoked:
            return String(localized: "The console requires Full Access.")
        case .unauthorized:
            return String(localized: "Authentication failed. Check your API key in Settings.")
        case .forbidden:
            return String(localized: "Your API key is not permitted to open a console for this instance.")
        case .notFound:
            return String(localized: "Resource not found. It may have been deleted.")
        case .rateLimited:
            return String(localized: "Rate limit exceeded. Please wait a moment and try again.")
        case .server:
            return String(localized: "Civo is experiencing issues. Please try again in a few minutes.")
        case .unexpectedStatus, .invalidResponse, .invalidConsoleURL:
            return String(localized: "Civo returned an unexpected console response.")
        case .timedOut:
            return String(localized: "Request timed out. The Civo API may be slow. Try again.")
        case .offline:
            return String(localized: "No internet connection. Check your network and try again.")
        case .network:
            return String(localized: "The console could not be reached. Check your network and try again.")
        case .notReady:
            return String(localized: "Console is not reachable yet. Try again in a moment.")
        case .pageLoadFailed:
            return String(localized: "The console page could not be loaded.")
        }
    }
}
