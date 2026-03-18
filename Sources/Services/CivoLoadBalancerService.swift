import Foundation

final class CivoLoadBalancerService: Sendable {
    private let api = CivoAPIClient.shared

    func listLoadBalancers() async throws -> [CivoLoadBalancer] {
        try await api.getArray(path: "/loadbalancers")
    }

    func removeLoadBalancer(_ id: String) async throws {
        try await api.delete(path: "/loadbalancers/\(id)")
    }
}
