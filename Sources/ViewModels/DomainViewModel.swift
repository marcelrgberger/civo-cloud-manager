import Foundation

@Observable
@MainActor
final class DomainViewModel {
    var domains: [CivoDomain] = []
    var records: [CivoDomainRecord] = []
    var isLoading = false
    var error: String?

    private let service = CivoDomainService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            domains = try await service.listDomains()
        } catch {
            self.error = error.localizedDescription
            Log.error("Domain list failed: \(error.localizedDescription)")
        }
    }

    func loadRecords(for domain: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            records = try await service.listRecords(domain)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeDomain(_ name: String) async {
        do {
            try await service.removeDomain(name)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
