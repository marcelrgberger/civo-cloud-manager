import Foundation

/// A change of an instance's power state. Civo answers each request with `{ "result": "success" }`.
enum InstancePowerAction: Equatable, Sendable {
    case start, stop, softReboot, hardReboot

    struct Request: Equatable {
        /// Below `/v2`, see https://www.civo.com/api/instances.
        let method: String
        let path: String
        let queryItems: [URLQueryItem]
    }

    /// The request for the instance in the region it was listed from.
    func request(instanceId: String, region: String) -> Request {
        let (method, endpoint) = switch self {
        case .start: ("PUT", "start")
        case .stop: ("PUT", "stop")
        case .softReboot: ("POST", "soft_reboots")
        case .hardReboot: ("POST", "reboots")
        }
        return Request(method: method, path: "/instances/\(instanceId)/\(endpoint)", queryItems: CivoInstanceService.pinned(region))
    }
}

/// Requests for one existing instance. Each takes the region the instance was listed from,
/// never the current Settings region, so a later region change cannot redirect them.
protocol InstanceAPI: Sendable {
    func listInstances(region: String?) async throws -> PaginatedList<CivoInstance>
    func updateInstance(_ id: String, body: sending [String: Any], region: String) async throws
    func changePower(_ action: InstancePowerAction, of id: String, region: String) async throws
    func resizeInstance(_ id: String, size: String, region: String) async throws
    func removeInstance(_ id: String, region: String) async throws
}

final class CivoInstanceService: InstanceAPI {
    private let api = CivoAPIClient.shared

    func listInstances(region: String? = nil) async throws -> PaginatedList<CivoInstance> {
        var queryItems: [URLQueryItem]? = nil
        if let region { queryItems = [URLQueryItem(name: "region", value: region)] }
        return try await api.getPaginatedList(path: "/instances", queryItems: queryItems)
    }

    func createInstance(_ body: [String: Any]) async throws -> CivoInstance {
        try await api.post(path: "/instances", body: body)
    }

    func updateInstance(_ id: String, body: sending [String: Any], region: String) async throws {
        let _: CivoInstance = try await api.put(path: "/instances/\(id)", body: body, queryItems: Self.pinned(region))
    }

    func changePower(_ action: InstancePowerAction, of id: String, region: String) async throws {
        let request = action.request(instanceId: id, region: region)
        let _: CivoResult = try await api.send(request.method, path: request.path, body: [:], queryItems: request.queryItems)
    }

    func resizeInstance(_ id: String, size: String, region: String) async throws {
        let _: CivoResult = try await api.put(path: "/instances/\(id)/resize", body: ["size": size], queryItems: Self.pinned(region))
    }

    func setFirewall(_ instanceId: String, firewallId: String) async throws {
        let _: CivoInstance = try await api.put(path: "/instances/\(instanceId)/firewall", body: ["firewall_id": firewallId])
    }

    func removeInstance(_ id: String, region: String) async throws {
        try await api.delete(path: "/instances/\(id)", queryItems: Self.pinned(region))
    }

    /// An empty region stays empty, so the client throws `noRegion` instead of using Settings.
    fileprivate static func pinned(_ region: String) -> [URLQueryItem] {
        [URLQueryItem(name: "region", value: region)]
    }
}
