import Foundation

/// Why comma-separated tag input cannot be sent.
enum InstanceTagInputError: Error, Equatable {
    /// No tag was entered. Removing all tags is a separate, confirmed action.
    case empty
    /// Civo separates tags by spaces, so each of these would be split into several tags.
    case containsWhitespace([String])

    var message: String {
        switch self {
        case .empty:
            String(localized: "Enter at least one tag. To remove all tags, use Remove All Tags.")
        case .containsWhitespace(let tags):
            String(localized: "Tags cannot contain spaces: \(tags.joined(separator: ", ")). Use a hyphen instead.")
        }
    }
}

/// The `tags` parameter of `PUT /v2/instances/:id/tags` (https://www.civo.com/api/instances).
/// Civo removes all tags when the parameter is empty or missing, so the only empty change is
/// `removeAll`, which the user starts and confirms on its own.
struct InstanceTagChange: Equatable, Sendable {
    /// In the order entered, without duplicates; empty only for `removeAll`.
    let tags: [String]

    private init(tags: [String]) {
        self.tags = tags
    }

    static let removeAll = InstanceTagChange(tags: [])

    /// Splits comma-separated input, trims every tag and drops empty entries and duplicates.
    static func replacing(with input: String) throws(InstanceTagInputError) -> InstanceTagChange {
        var tags: [String] = []
        for part in input.split(separator: ",") {
            let tag = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tag.isEmpty, !tags.contains(tag) { tags.append(tag) }
        }
        let withWhitespace = tags.filter { $0.rangeOfCharacter(from: .whitespacesAndNewlines) != nil }
        guard withWhitespace.isEmpty else { throw .containsWhitespace(withWhitespace) }
        guard !tags.isEmpty else { throw .empty }
        return InstanceTagChange(tags: tags)
    }

    /// Space-separated, as Civo expects it.
    var parameter: String { tags.joined(separator: " ") }
}

extension CivoInstance {
    /// Whether one of the tags contains `filter`, ignoring case. An empty filter matches every instance.
    func hasTag(matching filter: String) -> Bool {
        let filter = filter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filter.isEmpty else { return true }
        return (tags ?? []).contains { $0.localizedStandardContains(filter) }
    }
}
