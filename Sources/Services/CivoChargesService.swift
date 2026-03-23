import Foundation

struct CivoChargesService: Sendable {
    private let api = CivoAPIClient.shared
    private static let cacheKey = "CivoChargesCache"

    // MARK: - Cache

    private func cachedCharges(for key: String) -> [CivoCharge]? {
        guard let data = UserDefaults.standard.data(forKey: "\(Self.cacheKey).\(key)"),
              let charges = try? JSONDecoder().decode([CivoCharge].self, from: data) else { return nil }
        return charges
    }

    private func cacheCharges(_ charges: [CivoCharge], for key: String) {
        if let data = try? JSONEncoder().encode(charges) {
            UserDefaults.standard.set(data, forKey: "\(Self.cacheKey).\(key)")
        }
    }

    private func monthKey(from date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return "\(y)-\(String(format: "%02d", m))"
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(date, equalTo: Date(), toGranularity: .month)
    }

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

    /// Fetches charges for a month range. Uses cache for past months, live API for current month.
    func getChargesForRange(from start: Date, to end: Date) async throws -> [CivoCharge] {
        let cal = Calendar.current
        var allCharges: [CivoCharge] = []

        // Build list of months to fetch
        var cursor = cal.date(from: cal.dateComponents([.year, .month], from: start))!
        while cursor < end {
            let monthEnd = min(cal.date(byAdding: .month, value: 1, to: cursor)!, end)
            let key = monthKey(from: cursor)

            if !isCurrentMonth(cursor), let cached = cachedCharges(for: key) {
                allCharges.append(contentsOf: cached)
            } else {
                let charges = try await getCharges(from: cursor, to: monthEnd)
                if !isCurrentMonth(cursor) {
                    cacheCharges(charges, for: key)
                }
                allCharges.append(contentsOf: charges)
            }

            cursor = cal.date(byAdding: .month, value: 1, to: cursor)!
        }

        return allCharges
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
