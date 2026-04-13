import Foundation

struct ActivityEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let resourceType: String
    let resourceName: String
    let resourceId: String
    let action: String

    init(resourceType: String, resourceName: String, resourceId: String, action: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.resourceType = resourceType
        self.resourceName = resourceName
        self.resourceId = resourceId
        self.action = action
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var icon: String {
        switch action.lowercased() {
        case let a where a.contains("create"): return "plus.circle.fill"
        case let a where a.contains("delete") || a.contains("remove"): return "trash.fill"
        case let a where a.contains("start"): return "play.circle.fill"
        case let a where a.contains("stop"): return "stop.circle.fill"
        case let a where a.contains("reboot") || a.contains("restart"): return "arrow.clockwise.circle.fill"
        case let a where a.contains("resize"): return "arrow.up.right.circle.fill"
        case let a where a.contains("update") || a.contains("set"): return "pencil.circle.fill"
        case let a where a.contains("attach"): return "link.circle.fill"
        case let a where a.contains("detach"): return "link.badge.plus"
        case let a where a.contains("download"): return "arrow.down.circle.fill"
        case let a where a.contains("connect"): return "bolt.circle.fill"
        default: return "circle.fill"
        }
    }
}

@MainActor
final class ActivityLog {
    static let shared = ActivityLog()

    private let key = "CivoActivityLog"
    private let maxEntries = 200

    private(set) var entries: [ActivityEntry] = []

    init() {
        load()
    }

    func log(_ action: String, resourceType: String, resourceName: String, resourceId: String = "") {
        let entry = ActivityEntry(
            resourceType: resourceType,
            resourceName: resourceName,
            resourceId: resourceId,
            action: action
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
