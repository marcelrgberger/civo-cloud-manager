#if DEBUG
import Foundation

/// What the demo API answers for one request.
struct DemoResponse: Equatable {
    enum Kind: Equatable {
        case served
        /// A read of the Civo API that no fixture covers.
        case unrouted
        /// A write; demo data is read-only, so nothing may look like a successful change.
        case rejectedWrite
        /// A request to any host other than the Civo API.
        case blockedExternal
    }

    let status: Int
    let body: Data
    let kind: Kind
}

/// Routes requests on the Civo API to `DemoFixtures`. Pure: the same request and date always give the same answer.
enum DemoRouter {
    static let apiHost = "api.civo.com"
    private static let apiPathPrefix = "/v2"

    static func respond(method: String, url: URL, now: Date = Date()) -> DemoResponse {
        guard url.host == Self.apiHost else {
            return failure(404, "external request blocked in demo mode", .blockedExternal)
        }
        guard method == "GET" else {
            return failure(405, "demo data is read-only", .rejectedWrite)
        }
        let path = url.path.hasPrefix(apiPathPrefix) ? String(url.path.dropFirst(apiPathPrefix.count)) : url.path
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let json = payload(path: path, query: query, now: now) else {
            return failure(404, "no demo fixture for \(path)", .unrouted)
        }
        return DemoResponse(status: 200, body: encode(json), kind: .served)
    }

    private static func payload(path: String, query: [URLQueryItem], now: Date) -> Any? {
        switch path {
        case "/quota": return DemoFixtures.quota
        case "/regions": return DemoFixtures.regions
        case "/networks": return DemoFixtures.networks
        case "/sizes": return DemoFixtures.sizes
        case "/instances": return DemoFixtures.page(DemoFixtures.instances)
        case "/firewalls": return DemoFixtures.firewalls
        case "/ips": return DemoFixtures.page(DemoFixtures.reservedIPs)
        case "/kubernetes/clusters": return DemoFixtures.page(DemoFixtures.clusters)
        case "/kubernetes/versions": return DemoFixtures.kubernetesVersions
        case "/kubernetes/applications", "/dns", "/sshkeys", "/disk_images": return [Any]()
        case "/databases": return DemoFixtures.page(DemoFixtures.databases)
        case "/volumes": return DemoFixtures.volumes
        case "/objectstores": return DemoFixtures.page(DemoFixtures.objectStores)
        case "/objectstore/credentials": return DemoFixtures.page([])
        case "/loadbalancers": return DemoFixtures.loadBalancers
        case "/charges": return charges(query: query, now: now)
        default: return resource(path.split(separator: "/").map(String.init))
        }
    }

    /// Single resources and sub-resources addressed by id.
    private static func resource(_ parts: [String]) -> Any? {
        switch parts.count {
        case 2:
            switch parts[0] {
            case "instances": return DemoFixtures.instances.first { $0["id"] as? String == parts[1] }
            case "ips": return DemoFixtures.reservedIPs.first { $0["id"] as? String == parts[1] }
            default: return nil
            }
        case 3 where parts[0] == "firewalls" && parts[2] == "rules":
            return DemoFixtures.rules(forFirewall: parts[1])
        case 3 where parts[0] == "kubernetes" && parts[1] == "clusters":
            return DemoFixtures.cluster(withID: parts[2])
        default:
            return nil
        }
    }

    private static func charges(query: [URLQueryItem], now: Date) -> [[String: Any]]? {
        let formatter = ISO8601DateFormatter()
        func date(_ name: String) -> Date? {
            query.first { $0.name == name }?.value.flatMap(formatter.date(from:))
        }
        guard let from = date("from"), let to = date("to") else { return nil }
        return DemoFixtures.charges(from: from, to: to, now: now)
    }

    private static func encode(_ json: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])) ?? Data()
    }

    private static func failure(_ status: Int, _ message: String, _ kind: DemoResponse.Kind) -> DemoResponse {
        DemoResponse(status: status, body: encode(["message": message]), kind: kind)
    }
}
#endif
