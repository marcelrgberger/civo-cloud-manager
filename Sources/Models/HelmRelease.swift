import Foundation

struct HelmRelease: Identifiable, Sendable {
    let name: String
    let namespace: String
    let chart: String
    let version: String
    let appVersion: String
    let status: String
    let revision: Int
    let updated: String

    var id: String { "\(namespace)/\(name)" }
}
