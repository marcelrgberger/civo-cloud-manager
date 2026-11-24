import Foundation

enum ConsoleEndResult: Equatable, Sendable {
    case ended
    case alreadyStopped
}

enum ConsoleProbeResult: Equatable, Sendable {
    case ready
    case notReady
    /// The console host rejected the JWT; a fresh one may help.
    case tokenRejected
}

/// Console and JWT calls. Every method takes the API key explicitly so a window
/// keeps using the account it was opened with.
protocol ConsoleAPI: Sendable {
    func startSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleSessionResponse
    func endSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleEndResult
    func exchangeToken(region: String, apiKey: String) async throws -> String
    func probe(_ url: URL, target: ConsoleTarget) async throws -> ConsoleProbeResult
}

/// Sensitive-request path for console sessions. Unlike `CivoAPIClient` it uses an ephemeral
/// session without cache, cookies or credential storage, refuses API redirects, only follows
/// probe redirects that stay on the console origin, and throws only sanitized `ConsoleError`s.
final class CivoConsoleService: ConsoleAPI {
    static let sessionDuration = "1h"
    private static let apiBase = "https://api.civo.com/v2"

    private let session: URLSession

    init() {
        self.session = URLSession(configuration: Self.sessionConfiguration())
    }

    static func sessionConfiguration() -> URLSessionConfiguration {
        let config = DemoNetwork.configuration(.ephemeral)
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.urlCredentialStorage = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return config
    }

    // MARK: - Request construction

    static func apiRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem],
        apiKey: String,
        body: [String: String]? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: apiBase + path) else { throw ConsoleError.invalidResponse }
        components.queryItems = queryItems
        guard let url = components.url else { throw ConsoleError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        }
        return request
    }

    static func startRequest(_ target: ConsoleTarget, apiKey: String) throws -> URLRequest {
        try apiRequest(
            method: "PUT",
            path: "/instances/\(try pathComponent(target.instanceId))/vnc",
            queryItems: [
                URLQueryItem(name: "region", value: target.region),
                URLQueryItem(name: "duration", value: sessionDuration),
            ],
            apiKey: apiKey,
            body: [:]
        )
    }

    static func endRequest(_ target: ConsoleTarget, apiKey: String) throws -> URLRequest {
        try apiRequest(
            method: "DELETE",
            path: "/instances/\(try pathComponent(target.instanceId))/vnc",
            queryItems: [URLQueryItem(name: "region", value: target.region)],
            apiKey: apiKey
        )
    }

    static func exchangeRequest(region: String, apiKey: String) throws -> URLRequest {
        // Same body and region parameter as civogo's ExchangeAuthToken.
        try apiRequest(
            method: "POST",
            path: "/auth/exchange",
            queryItems: [URLQueryItem(name: "region", value: region)],
            apiKey: apiKey,
            body: ["scope": ""]
        )
    }

    private static func pathComponent(_ id: String) throws -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard !id.isEmpty, id.unicodeScalars.allSatisfy(allowed.contains) else { throw ConsoleError.invalidResponse }
        return id
    }

    // MARK: - ConsoleAPI

    func startSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleSessionResponse {
        try Self.validate(target: target, apiKey: apiKey)
        let data = try await send(try Self.startRequest(target, apiKey: apiKey))
        return try Self.decode(ConsoleSessionResponse.self, from: data)
    }

    func endSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleEndResult {
        try Self.validate(target: target, apiKey: apiKey)
        do {
            _ = try await send(try Self.endRequest(target, apiKey: apiKey))
            return .ended
        } catch ConsoleError.notFound {
            return .alreadyStopped
        }
    }

    func exchangeToken(region: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ConsoleError.noAPIKey }
        let data = try await send(try Self.exchangeRequest(region: region, apiKey: apiKey))
        let token = try Self.decode(AuthTokenExchangeResponse.self, from: data).accessToken
        guard !token.isEmpty else { throw ConsoleError.invalidResponse }
        return token
    }

    func probe(_ url: URL, target: ConsoleTarget) async throws -> ConsoleProbeResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let guardDelegate = RedirectGuard { ConsoleURL.isAllowedNavigation($0, sessionURL: url, target: target) }
        let status = try await statusCode(for: request, delegate: guardDelegate).status
        switch status {
        case 200: return .ready
        case 401, 403: return .tokenRejected
        default: return .notReady
        }
    }

    // MARK: - Transport

    private static func validate(target: ConsoleTarget, apiKey: String) throws {
        guard !apiKey.isEmpty else { throw ConsoleError.noAPIKey }
        guard !target.region.isEmpty else { throw ConsoleError.noRegion }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ConsoleError.invalidResponse
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let (status, data) = try await statusCode(for: request, delegate: RedirectGuard { _ in false })
        guard (200...299).contains(status) else { throw ConsoleError.http(status) }
        return data
    }

    private func statusCode(for request: URLRequest, delegate: RedirectGuard) async throws -> (status: Int, data: Data) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request, delegate: delegate)
        } catch {
            throw ConsoleError.sanitize(error)
        }
        guard let http = response as? HTTPURLResponse else { throw ConsoleError.invalidResponse }
        return (http.statusCode, data)
    }
}

/// Follows a redirect only when `allow` accepts the target; a refused redirect surfaces as its 3xx status.
private final class RedirectGuard: NSObject, URLSessionTaskDelegate, Sendable {
    private let allow: @Sendable (URL) -> Bool

    init(allow: @escaping @Sendable (URL) -> Bool) {
        self.allow = allow
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let url = request.url, allow(url) else { return nil }
        return request
    }
}
