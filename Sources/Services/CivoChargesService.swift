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
        return try await api.getArray(path: "/charges", queryItems: queryItems, regionRequired: false)
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
        try await api.getArray(path: "/invoices", regionRequired: false)
    }
}
