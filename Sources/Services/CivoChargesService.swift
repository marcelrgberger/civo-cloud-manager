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
        let raw = try await api.getRaw(path: "/charges", queryItems: queryItems, regionRequired: false)
        Log.info("Charges raw (\(raw.count) chars): \(String(raw.prefix(500)))")

        guard let data = raw.data(using: .utf8), !raw.isEmpty else {
            Log.error("Charges API: empty response")
            return []
        }

        // Try array
        do {
            let array = try JSONDecoder().decode([CivoCharge].self, from: data)
            Log.info("Charges decoded as array: \(array.count) items")
            return array
        } catch {
            Log.info("Charges not array: \(error.localizedDescription)")
        }

        // Try paginated { items: [...] }
        do {
            let paginated = try JSONDecoder().decode(PaginatedResponse<CivoCharge>.self, from: data)
            Log.info("Charges decoded as paginated: \(paginated.items.count) items")
            return paginated.items
        } catch {
            Log.info("Charges not paginated: \(error.localizedDescription)")
        }

        // Try as wrapper with different key names
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            Log.info("Charges is array of dicts, first keys: \(json.first?.keys.sorted() ?? [])")
        } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            Log.info("Charges is dict with keys: \(json.keys.sorted())")
        }

        Log.error("Charges API: could not decode - showing raw in error")
        throw CivoAPIError.decodingError("Charges API returned unexpected format. Check Console for details.")
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
