import Foundation

final class CivoNetworkService: Sendable {
    private let api = CivoAPIClient.shared

    func listNetworks() async throws -> [CivoNetwork] {
        try await api.getArray(path: "/networks")
    }
}
