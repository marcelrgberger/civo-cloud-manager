#if DEBUG
import Foundation

/// How many requests demo mode could not serve; a screen that shows fixtures must leave both at zero.
final class DemoTraffic: @unchecked Sendable {
    static let shared = DemoTraffic()

    private let lock = NSLock()
    private var unroutedCount = 0
    private var blockedCount = 0

    var unrouted: Int { lock.withLock { unroutedCount } }
    var blocked: Int { lock.withLock { blockedCount } }

    func record(_ kind: DemoResponse.Kind) {
        lock.withLock {
            switch kind {
            case .unrouted, .rejectedWrite: unroutedCount += 1
            case .blockedExternal: blockedCount += 1
            case .served: break
            }
        }
    }

    /// The accessibility value the UI test reads; it carries counts only, never a path or a header.
    var summary: String { "unrouted=\(unrouted) blocked=\(blocked)" }
}

/// Answers every request locally. Never forwards, so a request without a fixture fails here and cannot reach a server.
final class DemoURLProtocol: URLProtocol, @unchecked Sendable {
    /// Points a session configuration at this protocol only, with no cache, cookies or stored credentials.
    static func isolate(_ configuration: URLSessionConfiguration) {
        configuration.protocolClasses = [DemoURLProtocol.self]
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    }

    /// Covers `URLSession.shared` and sessions built from default configurations. Custom sessions are not covered by
    /// global registration; each of them takes `DemoNetwork.configuration(_:)` explicitly.
    static func registerGlobally() {
        URLProtocol.registerClass(DemoURLProtocol.self)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = DemoRouter.respond(method: request.httpMethod ?? "GET", url: url)
        DemoTraffic.shared.record(response.kind)
        let http = HTTPURLResponse(
            url: url, statusCode: response.status, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        guard let http else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
#endif
