import CryptoKit
import Foundation

// MARK: - Periods and request windows

/// Civo bills in UTC, so every period and every request window uses UTC calendar boundaries.
/// Local-time boundaries sent as UTC made a full 31-day month span 31 days plus the UTC offset,
/// which Civo rejects with HTTP 400 `parameter_date_range_too_long`.
enum ChargeCalendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func startOfMonth(_ date: Date) -> Date {
        utc.date(from: utc.dateComponents([.year, .month], from: date))!
    }

    static func monthKey(_ date: Date) -> String {
        let components = utc.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year!, components.month!)
    }
}

enum ChargePeriod: String, CaseIterable, Sendable {
    case currentMonth = "This Month"
    case lastMonth = "Last Month"
    case lastQuarter = "Last Quarter"
    case thisYear = "This Year"

    /// Half-open range `[from, to)` in UTC.
    func dateRange(now: Date) -> (from: Date, to: Date) {
        let cal = ChargeCalendar.utc
        let startOfThisMonth = ChargeCalendar.startOfMonth(now)
        switch self {
        case .currentMonth:
            return (startOfThisMonth, now)
        case .lastMonth:
            return (cal.date(byAdding: .month, value: -1, to: startOfThisMonth)!, startOfThisMonth)
        case .lastQuarter:
            return (cal.date(byAdding: .month, value: -3, to: startOfThisMonth)!, now)
        case .thisYear:
            return (cal.date(from: cal.dateComponents([.year], from: now))!, now)
        }
    }
}

/// One `/charges` request covering the half-open range `[from, to)`.
struct ChargeWindow: Hashable, Sendable {
    let from: Date
    let to: Date
}

enum ChargeWindowPlanner {
    /// Civo accepts `to - from` up to exactly 31 days and rejects one second more.
    static let maxSpan: TimeInterval = 31 * 24 * 60 * 60

    /// Splits `[from, to)` at UTC month boundaries. No UTC month exceeds `maxSpan`.
    static func monthlyWindows(from: Date, to: Date) -> [ChargeWindow] {
        var windows: [ChargeWindow] = []
        var monthStart = ChargeCalendar.startOfMonth(from)
        while monthStart < to {
            let nextMonth = ChargeCalendar.utc.date(byAdding: .month, value: 1, to: monthStart)!
            let window = ChargeWindow(from: max(from, monthStart), to: min(to, nextMonth))
            if window.from < window.to { windows.append(window) }
            monthStart = nextMonth
        }
        return windows
    }

    static func isFullMonth(_ window: ChargeWindow) -> Bool {
        window.from == ChargeCalendar.startOfMonth(window.from)
            && window.to == ChargeCalendar.utc.date(byAdding: .month, value: 1, to: window.from)
    }
}

// MARK: - Local cache

protocol ChargesCacheStore: Sendable {
    func load(scope: String, month: String) -> [CivoCharge]?
    func save(_ charges: [CivoCharge], scope: String, month: String)
}

/// Stores the charges of completed UTC months as `<directory>/<scope>/<yyyy-MM>.json`.
/// The scope is derived from the API key, so another account never sees these files.
struct FileChargesCacheStore: ChargesCacheStore {
    let directory: URL

    static let standard = FileChargesCacheStore(directory: URL.applicationSupportDirectory
        .appending(path: "CivoCloudManager/ChargesCache", directoryHint: .isDirectory))

    func load(scope: String, month: String) -> [CivoCharge]? {
        guard let data = try? Data(contentsOf: fileURL(scope: scope, month: month)) else { return nil }
        // An unreadable entry is treated like a missing one and fetched again.
        return try? JSONDecoder().decode([CivoCharge].self, from: data)
    }

    func save(_ charges: [CivoCharge], scope: String, month: String) {
        let url = fileURL(scope: scope, month: month)
        // A failed write only costs a re-fetch next time, so it must not fail the estimate.
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(charges).write(to: url, options: .atomic)
        } catch {
            Log.warning("Charges cache write failed for \(month)")
        }
    }

    private func fileURL(scope: String, month: String) -> URL {
        directory.appending(path: scope, directoryHint: .isDirectory).appending(path: "\(month).json")
    }
}

// MARK: - Service

struct CivoChargesService: Sendable {
    typealias Fetch = @Sendable (ChargeWindow) async throws -> [CivoCharge]

    private let fetch: Fetch
    private let store: any ChargesCacheStore
    private let cacheScope: @Sendable () -> String?
    private let now: @Sendable () -> Date

    init(
        fetch: @escaping Fetch,
        store: any ChargesCacheStore,
        cacheScope: @escaping @Sendable () -> String?,
        now: @escaping @Sendable () -> Date
    ) {
        self.fetch = fetch
        self.store = store
        self.cacheScope = cacheScope
        self.now = now
    }

    init() {
        _ = Self.legacyCachePurge
        self.init(
            fetch: { window in try await Self.requestCharges(window) },
            store: FileChargesCacheStore.standard,
            cacheScope: { Self.scope(forAPIKey: CivoConfig.shared.apiKey) },
            now: { Date() }
        )
    }

    var currentDate: Date { now() }

    /// Loads all charges of `period`. Completed months come from the local cache when present;
    /// the open month and anything missing is fetched in windows Civo accepts.
    func charges(for period: ChargePeriod) async throws -> [CivoCharge] {
        let now = now()
        let range = period.dateRange(now: now)
        let scope = cacheScope()
        var result: [CivoCharge] = []

        for window in ChargeWindowPlanner.monthlyWindows(from: range.from, to: range.to) {
            let month = ChargeCalendar.monthKey(window.from)
            let isCompletedMonth = ChargeWindowPlanner.isFullMonth(window) && window.to <= now
            if isCompletedMonth, let scope, let cached = store.load(scope: scope, month: month) {
                result += cached
                continue
            }
            let fetched = try await fetch(window)
            if isCompletedMonth, let scope {
                store.save(fetched, scope: scope, month: month)
            }
            result += fetched
        }
        return result
    }

    /// Hashed so the key itself is never written to disk; nil disables caching.
    static func scope(forAPIKey apiKey: String) -> String? {
        guard !apiKey.isEmpty else { return nil }
        let digest = SHA256.hash(data: Data(apiKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func requestCharges(_ window: ChargeWindow) async throws -> [CivoCharge] {
        let formatter = ISO8601DateFormatter()
        let queryItems = [
            URLQueryItem(name: "from", value: formatter.string(from: window.from)),
            URLQueryItem(name: "to", value: formatter.string(from: window.to)),
        ]
        return try await CivoAPIClient.shared.getArray(path: "/charges", queryItems: queryItems, regionRequired: false)
    }

    /// Earlier versions cached months in UserDefaults without an account scope and with
    /// local-time boundaries; those entries are neither safe nor correct to reuse.
    private static let legacyCachePurge: Void = {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("CivoChargesCache.") {
            defaults.removeObject(forKey: key)
        }
    }()
}

// MARK: - Errors

enum ChargesLoadError {
    /// Localized text for the cost estimate, or nil when nothing should be shown.
    /// Never includes the Civo response body.
    static func userMessage(_ error: Error) -> String? {
        if CivoAPIError.isCancelled(error) { return nil }
        switch error as? CivoAPIError {
        case .noAPIKey:
            return String(localized: "No Civo API key configured. Add your API key in Settings.")
        case .httpError(401, _), .httpError(403, _):
            return String(localized: "Authentication failed. Check your API key in Settings.")
        case .httpError(429, _):
            return String(localized: "Rate limit exceeded. Please wait a moment and try again.")
        case .httpError(500...599, _):
            return String(localized: "Civo is experiencing issues. Please try again in a few minutes.")
        default:
            return String(localized: "Charges for this period could not be loaded. Please try again.")
        }
    }
}
