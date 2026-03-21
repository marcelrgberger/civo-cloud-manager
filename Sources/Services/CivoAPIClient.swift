import Foundation

enum CivoAPIError: LocalizedError {
    case noAPIKey
    case noRegion
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Civo API key configured. Add your API key in Settings."
        case .noRegion:
            return "No region selected. Choose a region in Settings."
        case .httpError(let code, let message):
            return "API error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Failed to parse API response: \(detail)"
        case .networkError(let detail):
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

/// Simple result from DELETE operations.
struct CivoResult: Decodable, Sendable {
    let result: String?
}

final class CivoAPIClient: Sendable {
    static let shared = CivoAPIClient()

    private let baseURL = "https://api.civo.com/v2"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// GET raw string response from the API.
    func getRaw(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true
    ) async throws -> String {
        let apiKey = CivoConfig.shared.apiKey
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }

        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw CivoAPIError.networkError("Invalid API path: \(path)")
        }
        var items = queryItems ?? []
        if regionRequired {
            let region = CivoConfig.shared.region
            guard !region.isEmpty else { throw CivoAPIError.noRegion }
            items.append(URLQueryItem(name: "region", value: region))
        }
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
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true
    ) async throws -> T {
        try await execute("GET", path: path, queryItems: queryItems, regionRequired: regionRequired)
    }

    /// GET a paginated list (API returns `{ items: [...] }`).
    func getPaginatedList<T: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true
    ) async throws -> [T] {
        let response: PaginatedResponse<T> = try await execute(
            "GET", path: path, queryItems: queryItems, regionRequired: regionRequired
        )
        return response.items
    }

    /// GET a plain array list (API returns `[...]`).
    func getArray<T: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        regionRequired: Bool = true
    ) async throws -> [T] {
        try await execute("GET", path: path, queryItems: queryItems, regionRequired: regionRequired)
    }

    /// POST with a JSON body.
    func post<T: Decodable>(
        path: String,
        body: [String: Any],
        regionRequired: Bool = true
    ) async throws -> T {
        try await execute("POST", path: path, body: body, regionRequired: regionRequired)
    }

    /// PUT with a JSON body.
    func put<T: Decodable>(
        path: String,
        body: [String: Any],
        regionRequired: Bool = true
    ) async throws -> T {
        try await execute("PUT", path: path, body: body, regionRequired: regionRequired)
    }

    /// DELETE a resource.
    func delete(path: String, regionRequired: Bool = true) async throws {
        let _: CivoResult = try await execute("DELETE", path: path, regionRequired: regionRequired)
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

    // MARK: - Core

    private func execute<T: Decodable>(
        _ method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: [String: Any]? = nil,
        regionRequired: Bool = true
    ) async throws -> T {
        let apiKey = CivoConfig.shared.apiKey
        guard !apiKey.isEmpty else { throw CivoAPIError.noAPIKey }

        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw CivoAPIError.networkError("Invalid API path: \(path)")
        }
        var items = queryItems ?? []
        if regionRequired {
            let region = CivoConfig.shared.region
            guard !region.isEmpty else { throw CivoAPIError.noRegion }
            items.append(URLQueryItem(name: "region", value: region))
        }
        if !items.isEmpty { components.queryItems = items }

        guard let url = components.url else {
            throw CivoAPIError.networkError("Invalid URL for path: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
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

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Log.error("Decoding error for \(path): \(error)")
            throw CivoAPIError.decodingError(error.localizedDescription)
        }
    }
}
