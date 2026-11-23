import Foundation

enum ReservedIPOperation: Equatable, Sendable {
    case reserve, rename, assign, unassign, release
}

/// Why a reserved IP action may not be started or went no further. Nothing is sent after any of these.
enum ReservedIPError: Equatable, Sendable {
    case accessRevoked
    case noRegion
    case accountChanged
    case regionChanged
    case incompleteList
    case incompleteInstanceList
    case ipGone
    case ipStateUnclear
    case assignmentUnknown
    case alreadyAssigned
    case notAssigned
    case assignmentChanged
    case nameChanged
    case targetNotIdentifiable
    case instanceGone
    case contextChangedWhilePending

    var message: String {
        switch self {
        case .accessRevoked:
            String(localized: "Full Access is no longer active, so nothing was sent to Civo.")
        case .noRegion:
            String(localized: "No region is selected, so nothing was sent to Civo.")
        case .accountChanged:
            String(localized: "The Civo account changed, so nothing was sent to Civo. Open the action again for the current account.")
        case .regionChanged:
            String(localized: "The region changed, so nothing was sent to Civo. Open the action again for the current region.")
        case .incompleteList:
            String(localized: "Reserved IPs can only be changed while the complete list is loaded. Reload and try again.")
        case .incompleteInstanceList:
            String(localized: "The instance list is incomplete, so no instance can be chosen safely. Reload and try again.")
        case .ipGone:
            String(localized: "This reserved IP no longer exists. The list was reloaded and nothing was sent.")
        case .ipStateUnclear:
            String(localized: "Civo could not confirm this reserved IP, so nothing was sent. Reload to see its current state.")
        case .assignmentUnknown:
            String(localized: "The assignment of this reserved IP is not loaded. Reload it before changing it.")
        case .alreadyAssigned:
            String(localized: "This reserved IP is already assigned, so nothing was sent. Unassign it first.")
        case .notAssigned:
            String(localized: "This reserved IP is not assigned, so there is nothing to unassign.")
        case .assignmentChanged:
            String(localized: "The assignment of this reserved IP changed since you opened the action, so nothing was sent. Open the action again.")
        case .nameChanged:
            String(localized: "This reserved IP was renamed since you opened the action, so nothing was sent. Open the action again.")
        case .targetNotIdentifiable:
            String(localized: "Civo reports a target for this reserved IP that the app cannot identify, so it cannot be unassigned from here.")
        case .instanceGone:
            String(localized: "The chosen instance is no longer listed in this region, so nothing was sent.")
        case .contextChangedWhilePending:
            String(localized: "The account or region changed while the request was pending. Switch back to the account and region you used to check the result.")
        }
    }
}

/// The pure rules for what may be done with a reserved IP, given what was loaded about it.
enum ReservedIPRules {
    /// The name without surrounding whitespace, nil when nothing is left.
    static func normalizedName(_ typed: String) -> String? {
        let name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    /// The type-the-name check: exact, so a trailing space or a different case does not confirm.
    static func typedNameMatches(_ typed: String, name: String) -> Bool {
        typed == name
    }

    /// Why `operation` may not be offered for an IP in this `assignment`, nil while it may.
    /// Releasing stays possible for any loaded assignment, so an unused or unidentifiable reservation can be freed.
    static func eligibilityError(for operation: ReservedIPOperation, assignment: ReservedIPAssignment) -> ReservedIPError? {
        switch (operation, assignment) {
        case (.reserve, _), (.rename, _): nil
        case (_, .unknown): .assignmentUnknown
        case (.assign, .unassigned), (.unassign, .assigned), (.release, _): nil
        case (.assign, _): .alreadyAssigned
        case (.unassign, .unassigned): .notAssigned
        case (.unassign, _): .targetNotIdentifiable
        }
    }

    /// Why the reloaded IP no longer matches what the user confirmed, nil while it does.
    /// An unrecognized target is never taken to be the one that was confirmed, not even when it looks the same.
    static func staleError(captured: CivoReservedIP, reloaded: CivoReservedIP) -> ReservedIPError? {
        if reloaded.name != captured.name { return .nameChanged }
        if reloaded.assignment == .unknown { return .assignmentUnknown }
        if captured.assignment == .unrecognized || reloaded.assignment == .unrecognized { return .assignmentChanged }
        return reloaded.assignment == captured.assignment ? nil : .assignmentChanged
    }
}
