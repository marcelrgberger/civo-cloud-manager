import Foundation

final class CivoDomainService: Sendable {
    private let api = CivoAPIClient.shared

    func listDomains() async throws -> [CivoDomain] {
        try await api.getArray(path: "/dns", regionRequired: false)
    }

    func listRecords(_ domainId: String) async throws -> [CivoDomainRecord] {
        try await api.getArray(path: "/dns/\(domainId)/records", regionRequired: false)
    }

    func createDomain(_ body: [String: Any]) async throws -> CivoDomain {
        try await api.post(path: "/dns", body: body, regionRequired: false)
    }

    func updateDomain(_ id: String, body: [String: Any]) async throws -> CivoDomain {
        try await api.put(path: "/dns/\(id)", body: body, regionRequired: false)
    }

    func createRecord(_ domainId: String, body: [String: Any]) async throws -> CivoDomainRecord {
        try await api.post(path: "/dns/\(domainId)/records", body: body, regionRequired: false)
    }

    func updateRecord(_ domainId: String, recordId: String, body: [String: Any]) async throws -> CivoDomainRecord {
        try await api.put(path: "/dns/\(domainId)/records/\(recordId)", body: body, regionRequired: false)
    }

    func removeRecord(_ domainId: String, recordId: String) async throws {
        try await api.delete(path: "/dns/\(domainId)/records/\(recordId)", regionRequired: false)
    }

    func removeDomain(_ id: String) async throws {
        try await api.delete(path: "/dns/\(id)", regionRequired: false)
    }
}
