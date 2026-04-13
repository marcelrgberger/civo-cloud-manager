import Foundation

final class CivoRegionService: Sendable {
    private let api = CivoAPIClient.shared

    func listRegions() async throws -> [CivoRegion] {
        try await api.getArray(path: "/regions", regionRequired: false)
    }
}
