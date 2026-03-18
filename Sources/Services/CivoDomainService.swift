import Foundation

final class CivoDomainService: Sendable {
    private let api = CivoAPIClient.shared

    func listDomains() async throws -> [CivoDomain] {
        try await api.getArray(path: "/dns", regionRequired: false)
    }

    func listRecords(_ domainId: String) async throws -> [CivoDomainRecord] {
        try await api.getArray(path: "/dns/\(domainId)/records", regionRequired: false)
    }

    func removeDomain(_ id: String) async throws {
        try await api.delete(path: "/dns/\(id)", regionRequired: false)
    }
}
