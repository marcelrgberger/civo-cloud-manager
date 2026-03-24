import Foundation

struct CivoChargesService: Sendable {
    private let api = CivoAPIClient.shared
    private static let cacheKey = "CivoChargesCache"

    // MARK: - API

    func getCharges(from: Date, to: Date) async throws -> [CivoCharge] {
        let formatter = ISO8601DateFormatter()
        let queryItems = [
            URLQueryItem(name: "from", value: formatter.string(from: from)),
            URLQueryItem(name: "to", value: formatter.string(from: to)),
        ]
        return try await api.getArray(path: "/charges", queryItems: queryItems, regionRequired: false)
    }

    /// Fetches charges for a period, splitting into monthly requests (max 31 days each).
    /// Past months are cached locally.
    func getChargesForRange(from start: Date, to end: Date) async throws -> [CivoCharge] {
        let cal = Calendar.current
        var allCharges: [CivoCharge] = []

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
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
}
