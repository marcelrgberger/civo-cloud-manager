import Foundation

struct CivoChargesService: Sendable {
    private let api = CivoAPIClient.shared

    /// Fetches charges for the given period. Civo API: GET /v2/charges?from=...&to=...
    func getCharges(from: Date, to: Date) async throws -> [CivoCharge] {
        let formatter = ISO8601DateFormatter()
        let queryItems = [
            URLQueryItem(name: "from", value: formatter.string(from: from)),
            URLQueryItem(name: "to", value: formatter.string(from: to)),
        ]
        // Try to get raw response first for debugging, then decode
        let raw = try await api.getRaw(path: "/charges", queryItems: queryItems, regionRequired: false)
        Log.info("Charges API raw response (first 500 chars): \(String(raw.prefix(500)))")

        guard let data = raw.data(using: .utf8) else { return [] }

        // Try decoding as array first, then as paginated
        if let array = try? JSONDecoder().decode([CivoCharge].self, from: data) {
            return array
        }
        if let paginated = try? JSONDecoder().decode(PaginatedResponse<CivoCharge>.self, from: data) {
            return paginated.items
        }

        // Last resort: try to decode the top-level keys
        Log.error("Charges API: could not decode response")
        return []
    }

    /// Fetches charges for the current month.
    func getCurrentMonthCharges() async throws -> [CivoCharge] {
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return try await getCharges(from: startOfMonth, to: now)
    }

    /// Fetches charges for the last 30 days.
    func getLast30DaysCharges() async throws -> [CivoCharge] {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        return try await getCharges(from: thirtyDaysAgo, to: now)
    }

    /// Fetches invoices.
    func getInvoices() async throws -> [CivoInvoice] {
        do {
            return try await api.getArray(path: "/invoices", regionRequired: false)
        } catch {
            return try await api.getPaginatedList(path: "/invoices", regionRequired: false)
        }
    }
}
