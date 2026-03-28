import Foundation

final class CivoQuotaService: Sendable {
    private let api = CivoAPIClient.shared

    func getQuota() async throws -> CivoQuota {
        try await api.get(path: "/quota", regionRequired: false)
    }

    func requestQuotaChange(_ body: [String: Any]) async throws {
        let _: CivoResult = try await api.put(path: "/quota", body: body, regionRequired: false)
    }
}
