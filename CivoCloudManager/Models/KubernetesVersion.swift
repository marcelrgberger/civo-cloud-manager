import Foundation

/// One entry of `GET /v2/kubernetes/versions` (https://www.civo.com/api/kubernetes), documented as
/// `{"version": "1.20.0+k3s1", "flat_version": "1.20.0-k3s1", "label": "v1.20.0+k3s1", "type": "stable", "default": true}`.
/// The live API capitalises the keys (`Version`, `Label`, `Type`, `Default`, `ClusterType`), so both spellings are read from
/// a fixed list. `clusterType` follows Civo's Go client `civogo`.
///
/// Only `version` and `type` decide what is offered. A record without a readable `version`, or one that gives two
/// different values for `version` or `type` or a `type` that is not text, is rejected; the other fields only inform
/// and read as nil when missing, mistyped or contradictory. `version` is kept exactly as listed, since it is also
/// what is sent back to upgrade or create a cluster.
struct CivoKubernetesVersion: Decodable, Equatable, Identifiable, Sendable {
    let version: String
    let flatVersion: String?
    let label: String?
    let type: String?
    let isDefault: Bool?
    let clusterType: String?

    var id: String { version }

    var isDeprecated: Bool { type?.lowercased() == "deprecated" }

    var number: KubernetesVersionNumber? { KubernetesVersionNumber(version) }

    init(version: String, flatVersion: String?, label: String?, type: String?, isDefault: Bool?, clusterType: String?) {
        self.version = version
        self.flatVersion = flatVersion
        self.label = label
        self.type = type
        self.isDefault = isDefault
        self.clusterType = clusterType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let versions = try Self.values(String.self, for: ["version", "Version"], in: container)
        guard let version = versions.first, Set(versions).count == 1,
              !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "No usable version"))
        }
        let types = try Self.values(String.self, for: ["type", "Type"], in: container)
        guard Set(types).count <= 1 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Contradicting types"))
        }
        self.version = version
        type = types.first
        flatVersion = Self.informative(String.self, for: ["flat_version"], in: container)
        label = Self.informative(String.self, for: ["label", "Label"], in: container)
        isDefault = Self.informative(Bool.self, for: ["default", "Default"], in: container)
        clusterType = Self.informative(String.self, for: ["clusterType", "ClusterType"], in: container)
    }

    private struct Key: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    /// The non-null values under `names`; a value of the wrong type throws.
    private static func values<T: Decodable>(_ type: T.Type, for names: [String], in container: KeyedDecodingContainer<Key>) throws -> [T] {
        try names.map(Key.init(stringValue:)).compactMap { key in
            guard container.contains(key), try !container.decodeNil(forKey: key) else { return nil }
            return try container.decode(T.self, forKey: key)
        }
    }

    /// The single value under `names`, or nil when it is missing, mistyped or contradictory.
    private static func informative<T: Decodable & Hashable>(_ type: T.Type, for names: [String], in container: KeyedDecodingContainer<Key>) -> T? {
        guard let found = try? values(type, for: names, in: container), Set(found).count == 1 else { return nil }
        return found.first
    }
}

/// A K3s version such as `1.20.0+k3s1`. Civo lists versions with `+` and reports a cluster's version with `-`
/// (`1.22.2-k3s1`); both, with or without a leading `v`, read as the same version. Anything else is an unknown format.
struct KubernetesVersionNumber: Equatable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int
    /// The distribution of the build suffix, `k3s` for `+k3s1`; nil without a suffix.
    let distribution: String?
    let build: Int

    init?(_ text: String) {
        var rest = Substring(text.trimmingCharacters(in: .whitespaces))
        if rest.first == "v" || rest.first == "V" { rest = rest.dropFirst() }
        guard let separator = rest.firstIndex(where: { $0 == "+" || $0 == "-" }) else {
            guard let core = Self.core(rest) else { return nil }
            (major, minor, patch) = core
            distribution = nil
            build = 0
            return
        }
        guard let core = Self.core(rest[..<separator]),
              let suffix = Self.buildSuffix(rest[rest.index(after: separator)...]) else { return nil }
        (major, minor, patch) = core
        (distribution, build) = suffix
    }

    /// The order of two versions of the same distribution; nil when they cannot be compared.
    func compare(to other: KubernetesVersionNumber) -> ComparisonResult? {
        guard distribution == other.distribution else { return nil }
        let lhs = [major, minor, patch, build]
        let rhs = [other.major, other.minor, other.patch, other.build]
        guard lhs != rhs else { return .orderedSame }
        return lhs.lexicographicallyPrecedes(rhs) ? .orderedAscending : .orderedDescending
    }

    func isNewer(than other: KubernetesVersionNumber) -> Bool {
        compare(to: other) == .orderedDescending
    }

    /// `1.20.0`: exactly three plain numbers.
    private static func core(_ text: Substring) -> (Int, Int, Int)? {
        let numbers = text.split(separator: ".", omittingEmptySubsequences: false).map(number)
        guard numbers.count == 3, let major = numbers[0], let minor = numbers[1], let patch = numbers[2] else { return nil }
        return (major, minor, patch)
    }

    /// `k3s1` is the distribution `k3s` with build 1: a name of letters and digits, ending in the build number.
    private static func buildSuffix(_ text: Substring) -> (String, Int)? {
        let digitCount = text.reversed().prefix(while: isDigit).count
        let name = text.dropLast(digitCount)
        guard let build = number(text.suffix(digitCount)), let first = name.first, first.isASCII, first.isLetter,
              name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else { return nil }
        return (name.lowercased(), build)
    }

    private static let maxDigits = 6

    private static func number(_ text: Substring) -> Int? {
        guard (1...maxDigits).contains(text.count), text.allSatisfy(isDigit) else { return nil }
        return Int(text)
    }

    private static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }
}

/// Why no upgrade can be offered or sent. Nothing was sent in any of these cases.
enum KubernetesUpgradeError: Error, Equatable {
    case accessRevoked
    case noRegion
    case regionChanged
    case accountChanged
    case unknownVersionFormat(String)
    case noNewerVersion
    case clusterNotActive(String)
    case upgradeInProgress
    case upgradeAlreadyRequested(String)
    case clusterChanged
    case clusterRemoved
    case targetUnavailable(String)

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Upgrading a cluster requires Full Access.")
        case .noRegion:
            String(localized: "The region of this cluster is unknown. Reload the cluster and try again.")
        case .regionChanged:
            String(localized: "The region changed, so the cluster upgrade was cancelled. Nothing was sent.")
        case .accountChanged:
            String(localized: "The API key changed, so the cluster upgrade was cancelled. Nothing was sent.")
        case .unknownVersionFormat(let version):
            String(localized: "The version \"\(version)\" has an unknown format, so no upgrade can be offered.")
        case .noNewerVersion:
            String(localized: "Civo currently offers no newer version for this cluster.")
        case .clusterNotActive(let status):
            String(localized: "The cluster is not active (status \(status)). Wait until it is active, then try again.")
        case .upgradeInProgress:
            String(localized: "The cluster is not on its desired version yet. An upgrade is still running.")
        case .upgradeAlreadyRequested(let version):
            String(localized: "An upgrade to \(version) was already requested. Wait until the cluster reports this version.")
        case .clusterChanged:
            String(localized: "The cluster version changed in the meantime, so nothing was sent. Check the current version and try again.")
        case .clusterRemoved:
            String(localized: "The cluster no longer exists, so nothing was sent.")
        case .targetUnavailable(let version):
            String(localized: "Civo no longer offers \(version) as an upgrade for this cluster, so nothing was sent.")
        }
    }
}

enum KubernetesVersionCatalog {
    /// The versions a cluster on `current` may be upgraded to, newest first: listed, not deprecated,
    /// of the same distribution and strictly newer. Downgrades and versions of an unknown format are never offered.
    /// Civo decides on the upgrade path itself and may still refuse a listed version.
    static func upgradeTargets(from current: String, in catalog: [CivoKubernetesVersion]) -> Result<[CivoKubernetesVersion], KubernetesUpgradeError> {
        guard let currentNumber = KubernetesVersionNumber(current) else { return .failure(.unknownVersionFormat(current)) }
        let targets = newestFirst(catalog.filter { entry in
            guard !entry.isDeprecated, let number = entry.number else { return false }
            return number.isNewer(than: currentNumber)
        })
        return targets.isEmpty ? .failure(.noNewerVersion) : .success(targets)
    }

    /// The versions a new cluster can be created with, newest first. The create request sends no cluster type,
    /// and Civo documents its `kubernetes_version` as "the version of K3s to install".
    static func createOptions(in catalog: [CivoKubernetesVersion]) -> [CivoKubernetesVersion] {
        newestFirst(catalog.filter { !$0.isDeprecated && $0.number?.distribution == "k3s" })
    }

    /// Why `cluster` cannot be upgraded right now, nil while it can.
    static func upgradeBlocker(for cluster: CivoKubernetesCluster) -> KubernetesUpgradeError? {
        guard cluster.status.lowercased() == "active" else { return .clusterNotActive(cluster.status) }
        return cluster.isUpgradeRunning ? .upgradeInProgress : nil
    }

    /// Sorted by version; an entry listed again in another spelling is kept once.
    private static func newestFirst(_ entries: [CivoKubernetesVersion]) -> [CivoKubernetesVersion] {
        var unique: [CivoKubernetesVersion] = []
        for entry in entries where !unique.contains(where: { $0.number == entry.number }) {
            unique.append(entry)
        }
        return unique.sorted { lhs, rhs in
            guard let left = lhs.number, let right = rhs.number else { return false }
            return left.compare(to: right) == .orderedDescending
        }
    }
}
