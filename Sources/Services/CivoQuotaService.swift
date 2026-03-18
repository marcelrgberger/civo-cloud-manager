import Foundation

final class CivoQuotaService: Sendable {
    private let api = CivoAPIClient.shared

    func getQuota() async throws -> CivoQuota {
        try await api.get(path: "/quota", regionRequired: false)
    }
}
