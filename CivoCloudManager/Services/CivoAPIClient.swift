import Foundation

enum CivoAPIError: LocalizedError {
    case noAPIKey
    case noRegion
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)
    case cancelled
    /// Paging stopped before the last page; the detail is the reason, if any.
    case incompleteList(String?)

    static var incompleteListMessage: String {
        String(localized: "Some results may be missing because not all pages could be loaded from Civo.")
    }

    /// Returns true if this error should be silently ignored (e.g. request cancelled during navigation)
    static func isCancelled(_ error: Error) -> Bool {
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        if let apiError = error as? CivoAPIError, case .cancelled = apiError { return true }
        if error is CancellationError { return true }
        return false
    }

    /// Returns the error description only if it should be shown to the user (filters cancelled)
    static func userMessage(_ error: Error) -> String? {
        if isCancelled(error) { return nil }
        let msg = error.localizedDescription
        if msg.isEmpty || msg.contains("CivoAPIError") { return nil }
        return msg
    }

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Civo API key configured. Add your API key in Settings."
        case .noRegion:
            return "No region selected. Choose a region in Settings."
        case .httpError(let code, let message):
            switch code {
            case 401:
                return "Authentication failed. Check your API key in Settings."
            case 403:
                return "Access denied. Your API key may not have permission for this action."
            case 404:
                return "Resource not found. It may have been deleted."
            case 429:
                return "Rate limit exceeded. Please wait a moment and try again."
            case 500...599:
                return "Civo is experiencing issues (HTTP \(code)). Please try again in a few minutes. Check status.civo.com for updates."
            default:
                return "API error (\(code)): \(message)"
            }
        case .decodingError(let detail):
            return "Failed to parse API response: \(detail)"
        case .cancelled:
            return ""  // Empty = suppress in UI
        case .incompleteList(let detail):
            let message = Self.incompleteListMessage
            guard let detail, !detail.isEmpty else { return message }
            return "\(message) \(detail)"
        case .networkError(let detail):
            if detail.contains("cancelled") {
                return ""  // Empty = suppress in UI
            }
            if detail.contains("offline") || detail.contains("not connected") {
                return "No internet connection. Check your network and try again."
            }
            if detail.contains("timed out") {
                return "Request timed out. The Civo API may be slow. Try again."
            }
            return "Network error: \(detail)"
        }
    }
}

/// Paginated response wrapper from the Civo API.
struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let page: Int?
    let perPage: Int?
    let pages: Int?

    enum CodingKeys: String, CodingKey {
        case items, page, pages
        case perPage = "per_page"
    }
}

/// A list gathered from all pages of a paginated endpoint.
struct PaginatedList<T: Sendable>: Sendable {
    let items: [T]
    /// False when paging stopped early (page cap, repeated or non-advancing page), so items may be missing.
    let isComplete: Bool

    /// The items, or an error for callers that must not act on a partial list.
    func completeItems() throws -> [T] {
        guard isComplete else { throw CivoAPIError.incompleteList(nil) }
        return items
    }
}

/// Whether the list a screen shows may be missing entries, carried from one load attempt to the next.
struct ListCompleteness: Equatable, Sendable {
    private(set) var mayBeMissingItems = false

    /// A finished load states exactly whether every page arrived.
    mutating func update<T>(with list: PaginatedList<T>) {
        mayBeMissingItems = !list.isComplete
    }

    /// A cancelled load never confirmed the shown list, so it stays flagged until a later load finishes.
    /// Other failures are reported as errors and keep the last state.
    mutating func update(after error: Error) {
        if CivoAPIError.isCancelled(error) { mayBeMissingItems = true }
    }
}

/// Simple result from DELETE operations.
struct CivoResult: Decodable, Sendable {
    let result: String?
}

final class CivoAPIClient: Sendable {
    static let shared = CivoAPIClient()

    private let baseURL = "https://api.civo.com/v2"
    private let session: URLSession
    private let sensitiveSession: URLSession

    private let settingsAPIKey: @Sendable () -> String
    private let settingsRegion: @Sendable () -> String
    private let diagnostic: @Sendable (String) -> Void

    convenience init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let sensitive = URLSessionConfiguration.ephemeral
        sensitive.timeoutIntervalForRequest = 30
        sensitive.timeoutIntervalForResource = 60
        sensitive.urlCache = nil
        sensitive.httpCookieStorage = nil
        sensitive.urlCredentialStorage = nil
        self.init(session: URLSession(configuration: config), sensitiveSession: URLSession(configuration: sensitive))
    }

    init(
        session: URLSession,
        sensitiveSession: URLSession? = nil,
        settingsAPIKey: @escaping @Sendable () -> String = { CivoConfig.shared.apiKey },
        settingsRegion: @escaping @Sendable () -> String = { CivoConfig.shared.region },
        diagnostic: @escaping @Sendable (String) -> Void = { Log.error($0) }
    ) {
        self.session = session
        self.sensitiveSession = sensitiveSession ?? session
        self.settingsAPIKey = settingsAPIKey
        self.settingsRegion = settingsRegion
        self.diagnostic = diagnostic
    }

    // MARK: - Public API

    /// GET raw string response from the API.
    func getRaw(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true
    ) async throws -> String {
        let apiKey = settingsAPIKey()
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }

        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw CivoAPIError.networkError("Invalid API path: \(path)")
        }
        let items = try Self.resolvedQueryItems(queryItems, defaultRegion: settingsRegion(), regionRequired: regionRequired)
        if !items.isEmpty { components.queryItems = items }

        guard let url = components.url else {
            throw CivoAPIError.networkError("Invalid URL for path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CivoAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0, message)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw CivoAPIError.decodingError("Invalid text encoding")
        }
        return text
    }

    /// GET a decoded response from the API.
    /// `apiKey` pins the request to one account instead of reading the current key.
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true,
        apiKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> T {
        try await execute("GET", path: path, queryItems: queryItems, regionRequired: regionRequired, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
    }

    /// GET every page of a paginated list (API returns `{ page, per_page, pages, items }`).
    /// Region and API key are fixed before the first page, so a Settings change mid-way cannot mix accounts or regions.
    func getPaginatedList<T: Decodable & Identifiable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true,
        apiKey pinnedAPIKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> PaginatedList<T> {
        let apiKey = pinnedAPIKey ?? settingsAPIKey()
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }
        if pinnedAPIKey != nil && !(queryItems ?? []).contains(where: { $0.name == "region" && !($0.value ?? "").isEmpty }) {
            throw CivoAPIError.noRegion
        }
        let filters = try Self.resolvedQueryItems(queryItems, defaultRegion: pinnedAPIKey == nil ? settingsRegion() : "", regionRequired: regionRequired)
        do {
            return try await Self.collectPages(filters: filters) { pageQuery in
                try await self.execute("GET", path: path, queryItems: pageQuery, regionRequired: regionRequired, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
            }
        } catch CivoAPIError.incompleteList where redactDiagnostics {
            throw CivoAPIError.incompleteList(nil)
        }
    }

    func patch<T: Decodable>(
        path: String,
        body: [String: Any],
        queryItems: [URLQueryItem],
        apiKey: String,
        redactDiagnostics: Bool = false
    ) async throws -> T {
        try await execute("PATCH", path: path, queryItems: queryItems, body: body, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
    }

    /// GET a plain array list (API returns `[...]`).
    /// `apiKey` pins the request to one account instead of reading the current key.
    func getArray<T: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true,
        apiKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> [T] {
        try await execute("GET", path: path, queryItems: queryItems, regionRequired: regionRequired, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
    }

    /// POST with a JSON body.
    /// `apiKey` pins the request to one account instead of reading the current key.
    func post<T: Decodable>(
        path: String,
        body: [String: Any],
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true,
        apiKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> T {
        try await execute("POST", path: path, queryItems: queryItems, body: body, regionRequired: regionRequired, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
    }

    /// PUT with a JSON body.
    /// `apiKey` pins the request to one account instead of reading the current key.
    func put<T: Decodable>(
        path: String,
        body: [String: Any],
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true,
        apiKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> T {
        try await execute("PUT", path: path, queryItems: queryItems, body: body, regionRequired: regionRequired, apiKey: apiKey, redactDiagnostics: redactDiagnostics)
    }

    /// Any method with an optional JSON body, for callers that choose the method per request.
    func send<T: Decodable>(
        _ method: String,
        path: String,
        body: [String: Any]?,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        try await execute(method, path: path, queryItems: queryItems, body: body)
    }

    /// PUT with a JSON body, discarding the response body.
    func putDiscarding(
        path: String,
        body: [String: Any],
        regionRequired: Bool = true
    ) async throws {
        try await executeRaw("PUT", path: path, body: body, regionRequired: regionRequired)
    }

    /// DELETE a resource.
    func delete(path: String, queryItems: [URLQueryItem]? = nil, regionRequired: Bool = true) async throws {
        let _: CivoResult = try await execute("DELETE", path: path, queryItems: queryItems, regionRequired: regionRequired)
    }

    /// Validate an API key by making a test request.
    func validateAPIKey(_ key: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/regions") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Pagination

    /// Page size and page cap follow Civo's own Go client (civogo): 100 per page, at most 100 pages.
    static let pageSize = 100
    static let maxPages = 100

    /// Fetches pages from 1 on, each with the same filters, until the last page.
    /// Without `pages` metadata only an empty page proves the end. A repeated or non-advancing page,
    /// or reaching `maxPages`, returns the items so far as incomplete. A failed page throws; nothing partial is returned.
    static func collectPages<T: Identifiable & Sendable>(
        filters: [URLQueryItem],
        maxPages: Int = maxPages,
        fetchPage: ([URLQueryItem]) async throws -> PaginatedResponse<T>
    ) async throws -> PaginatedList<T> {
        let baseQuery = filters.filter { $0.name != "page" && $0.name != "per_page" }
        var items: [T] = []
        var seenIDs = Set<T.ID>()
        for page in 1...max(maxPages, 1) {
            let response: PaginatedResponse<T>
            do {
                response = try await fetchPage(baseQuery + [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "per_page", value: String(pageSize)),
                ])
            } catch where page > 1 && !CivoAPIError.isCancelled(error) {
                throw CivoAPIError.incompleteList(error.localizedDescription)
            }
            if Task.isCancelled { throw CivoAPIError.cancelled }
            if let reportedPage = response.page, reportedPage != page {
                return PaginatedList(items: items, isComplete: false)
            }
            let newItems = response.items.filter { seenIDs.insert($0.id).inserted }
            if newItems.isEmpty && !response.items.isEmpty {
                return PaginatedList(items: items, isComplete: false)
            }
            items += newItems
            let isLastPage = response.pages.map { page >= $0 } ?? response.items.isEmpty
            if isLastPage { return PaginatedList(items: items, isComplete: true) }
        }
        return PaginatedList(items: items, isComplete: false)
    }

    // MARK: - Core

    static func resolvedQueryItems(_ queryItems: [URLQueryItem]?, defaultRegion: String, regionRequired: Bool) throws -> [URLQueryItem] {
        let supplied = queryItems ?? []
        let explicitRegions = supplied.filter { $0.name == "region" }
        guard regionRequired || !explicitRegions.isEmpty else { return supplied }
        let region = explicitRegions.first?.value ?? (explicitRegions.isEmpty ? defaultRegion : "")
        guard !region.isEmpty else { throw CivoAPIError.noRegion }
        guard explicitRegions.allSatisfy({ $0.value == region }) else {
            throw CivoAPIError.networkError("Conflicting regions in API request")
        }
        return supplied.filter { $0.name != "region" } + [URLQueryItem(name: "region", value: region)]
    }

    private func execute<T: Decodable>(
        _ method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        regionRequired: Bool = true,
        apiKey pinnedAPIKey: String? = nil,
        redactDiagnostics: Bool = false
    ) async throws -> T {
        let apiKey = pinnedAPIKey ?? settingsAPIKey()
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }

        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw CivoAPIError.networkError("Invalid API path: \(path)")
        }
        let items = try Self.resolvedQueryItems(queryItems, defaultRegion: settingsRegion(), regionRequired: regionRequired)
        if !items.isEmpty { components.queryItems = items }

        guard let url = components.url else {
            throw CivoAPIError.networkError("Invalid URL for path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if redactDiagnostics { request.cachePolicy = .reloadIgnoringLocalCacheData }
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await (redactDiagnostics ? sensitiveSession : session).data(for: request)
        } catch is CancellationError {
            throw CivoAPIError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CivoAPIError.cancelled
        } catch {
            throw CivoAPIError.networkError(redactDiagnostics ? "" : error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CivoAPIError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = redactDiagnostics ? "" : (String(data: data, encoding: .utf8) ?? "Unknown error")
            throw CivoAPIError.httpError(httpResponse.statusCode, message)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            diagnostic(redactDiagnostics ? "Unable to decode sensitive API response" : "Decoding error for \(path): \(error)")
            throw CivoAPIError.decodingError(redactDiagnostics ? "" : error.localizedDescription)
        }
    }

    /// Execute a request, returning raw Data without JSON decoding.
    private func executeRaw(
        _ method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        regionRequired: Bool = true
    ) async throws {
        let apiKey = settingsAPIKey()
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }

        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw CivoAPIError.networkError("Invalid API path: \(path)")
        }
        let items = try Self.resolvedQueryItems(queryItems, defaultRegion: settingsRegion(), regionRequired: regionRequired)
        if !items.isEmpty { components.queryItems = items }

        guard let url = components.url else {
            throw CivoAPIError.networkError("Invalid URL for path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CivoAPIError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CivoAPIError.cancelled
        } catch {
            throw CivoAPIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CivoAPIError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CivoAPIError.httpError(httpResponse.statusCode, message)
        }
    }
}
