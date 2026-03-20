import Foundation

final class CivoSSHKeyService: Sendable {
    private let api = CivoAPIClient.shared

    func listSSHKeys() async throws -> [CivoSSHKey] {
        try await api.getArray(path: "/sshkeys", regionRequired: false)
    }

    func createSSHKey(_ body: [String: Any]) async throws -> CivoSSHKey {
        try await api.post(path: "/sshkeys", body: body, regionRequired: false)
    }

    func removeSSHKey(_ id: String) async throws {
        try await api.delete(path: "/sshkeys/\(id)", regionRequired: false)
    }
}
