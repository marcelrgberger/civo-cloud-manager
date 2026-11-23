import Foundation

/// The instance a reserved IP is assigned to. Civo names it in `assigned_to`; the id is what identifies it.
struct ReservedIPTarget: Equatable, Sendable {
    let id: String
    let name: String

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

/// What is known about the target of a reserved IP. Anything Civo reports that is not recognized as an instance
/// is `unrecognized`, never `unassigned`, and the public address is never used to guess a target.
enum ReservedIPAssignment: Equatable, Sendable {
    /// Civo did not report an assignment: a list entry without `assigned_to`, or a detail that is not loaded.
    case unknown
    /// Civo reported an empty `assigned_to`.
    case unassigned
    case assigned(ReservedIPTarget)
    /// Civo reported a target that is not an instance with an id, a type and a name. The fingerprint is what Civo
    /// reported, so a different unrecognized target is told apart from this one.
    case unrecognized(fingerprint: String)

    /// The only target type Civo accepted and reported back when the assignment was verified.
    static let instanceType = "instance"
}

struct CivoReservedIP: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// Missing until Civo has allocated the address.
    let ip: String?
    let assignment: ReservedIPAssignment

    private enum CodingKeys: String, CodingKey {
        case id, name, ip
        case assignedTo = "assigned_to"
    }

    /// Any JSON, kept only to tell two reported targets apart. Integers that fit 64 bits keep their exact value. Any
    /// other number cannot be compared exactly after decoding, so it gets a mark that is unique to this decoding:
    /// two reports of it never match and release is refused rather than guessed.
    private enum AnyJSON: Decodable {
        case null, bool(Bool), integer(String), inexactNumber(UUID), string(String), array([AnyJSON]), object([String: AnyJSON])

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() {
                self = .null
            } else if let value = try? c.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? c.decode(Int64.self) {
                self = .integer(String(value))
            } else if let value = try? c.decode(UInt64.self) {
                self = .integer(String(value))
            } else if (try? c.decode(Double.self)) != nil {
                self = .inexactNumber(UUID())
            } else if let value = try? c.decode(String.self) {
                self = .string(value)
            } else if let value = try? c.decode([AnyJSON].self) {
                self = .array(value)
            } else {
                self = .object(try c.decode([String: AnyJSON].self))
            }
        }

        /// The same content gives the same text, whatever the order of the keys, and different content never does:
        /// quotes and backslashes inside strings and keys are escaped, so they cannot imitate the structure.
        var canonical: String {
            switch self {
            case .null: "null"
            case .bool(let value): String(value)
            case .integer(let digits): digits
            case .inexactNumber(let mark): "inexact-\(mark.uuidString)"
            case .string(let value): Self.quoted(value)
            case .array(let values): "[" + values.map(\.canonical).joined(separator: ",") + "]"
            case .object(let fields): "{" + fields.sorted { $0.key < $1.key }.map { "\(Self.quoted($0.key)):\($0.value.canonical)" }.joined(separator: ",") + "}"
            }
        }

        private static func quoted(_ text: String) -> String {
            let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
    }

    private struct AnyKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(id: String, name: String, ip: String?, assignment: ReservedIPAssignment) {
        self.id = id
        self.name = name
        self.ip = ip
        self.assignment = assignment
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        ip = try c.decodeIfPresent(String.self, forKey: .ip)
        assignment = try Self.assignment(in: c)
    }

    private static func assignment(in c: KeyedDecodingContainer<CodingKeys>) throws -> ReservedIPAssignment {
        guard c.contains(.assignedTo), try !c.decodeNil(forKey: .assignedTo) else { return .unknown }
        let reported = try c.decode(AnyJSON.self, forKey: .assignedTo)
        guard let fields = try? c.nestedContainer(keyedBy: AnyKey.self, forKey: .assignedTo) else {
            return .unrecognized(fingerprint: reported.canonical)
        }
        guard !fields.allKeys.isEmpty else { return .unassigned }
        let type = try? fields.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "type"))
        let id = try? fields.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "id"))
        let name = try? fields.decodeIfPresent(String.self, forKey: AnyKey(stringValue: "name"))
        guard type == ReservedIPAssignment.instanceType, let id, !id.isEmpty, let name else {
            return .unrecognized(fingerprint: reported.canonical)
        }
        return .assigned(ReservedIPTarget(id: id, name: name))
    }
}

/// Civo's answer to creating or renaming a reserved IP. The address follows only on a later `GET`.
struct ReservedIPAck: Decodable, Equatable, Sendable {
    let id: String
    let name: String
}

/// Civo's answer to assigning, unassigning or releasing: `{ "result": "success" }`.
/// A missing or different result is not accepted as success.
struct ReservedIPActionResult: Decodable, Equatable, Sendable {
    let result: String?

    var isSuccess: Bool { result == "success" }
}

/// An instance the user can pick as the target. Only what the picker shows is decoded.
struct ReservedIPInstanceChoice: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let hostname: String?
    let publicIp: String?

    var name: String { hostname ?? id }

    private enum CodingKeys: String, CodingKey {
        case id, hostname
        case publicIp = "public_ip"
    }
}

extension ReservedIPAssignment {
    /// Shown for the assignment. Only `unassigned` ever reads "Not assigned", and nothing here calls it free.
    var summary: String {
        switch self {
        case .unknown: String(localized: "Assignment unknown")
        case .unassigned: String(localized: "Not assigned")
        case .assigned(let target): String(localized: "Assigned to \(target.name)")
        case .unrecognized: String(localized: "Assigned (target not recognized)")
        }
    }
}
