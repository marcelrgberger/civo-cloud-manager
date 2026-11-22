import Foundation

/// Why a load balancer request failed, in a closed set of cases. Civo's answer text, request URLs and decoding
/// details are never kept, so nothing a response or error carries reaches the screen, the log or the activity history.
enum LoadBalancerFailure: Error, Equatable, Sendable {
    case noAPIKey
    case noRegion
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    /// Any other refusal of the request (4xx): Civo changed nothing.
    case rejected
    case serverIssue
    case network
    /// Civo answered, but not in a form the app can read.
    case unreadableAnswer
    case cancelled

    init(_ error: Error) {
        if CivoAPIError.isCancelled(error) {
            self = .cancelled
            return
        }
        switch error as? CivoAPIError {
        case .noAPIKey?: self = .noAPIKey
        case .noRegion?: self = .noRegion
        case .httpError(401, _)?: self = .unauthorized
        case .httpError(403, _)?: self = .forbidden
        case .httpError(404, _)?: self = .notFound
        case .httpError(429, _)?: self = .rateLimited
        case .httpError(let status, _)? where (400..<500).contains(status) && status != 408: self = .rejected
        case .httpError(let status, _)? where (500..<600).contains(status): self = .serverIssue
        case .decodingError?: self = .unreadableAnswer
        default: self = .network
        }
    }

    /// Whether the refusal proves Civo did not apply the request. A timeout (408), a server error, a lost
    /// connection or an unreadable answer may follow a change Civo already made.
    var provesNothingChanged: Bool {
        switch self {
        case .noAPIKey, .noRegion, .unauthorized, .forbidden, .notFound, .rateLimited, .rejected: true
        case .serverIssue, .network, .unreadableAnswer, .cancelled: false
        }
    }

    /// The text shown to the user, nil for a cancelled request.
    var message: String? {
        switch self {
        case .noAPIKey:
            String(localized: "No Civo API key configured. Add your API key in Settings.")
        case .noRegion:
            String(localized: "No region selected. Choose a region in Settings.")
        case .unauthorized:
            String(localized: "Authentication failed. Check your API key in Settings.")
        case .forbidden:
            String(localized: "Access denied. Your API key may not have permission for this action.")
        case .notFound:
            String(localized: "Resource not found. It may have been deleted.")
        case .rateLimited:
            String(localized: "Rate limit exceeded. Please wait a moment and try again.")
        case .rejected:
            String(localized: "Civo refused the request. Check the name, network, backends and your quota in the Civo dashboard.")
        case .serverIssue:
            String(localized: "Civo is experiencing issues. Please try again in a few minutes.")
        case .network:
            String(localized: "Civo could not be reached. Check your connection and try again.")
        case .unreadableAnswer:
            String(localized: "Civo's answer could not be read.")
        case .cancelled:
            nil
        }
    }

    /// The case name for the log, without any detail of the request or answer.
    var diagnosticName: String { String(describing: self) }
}
