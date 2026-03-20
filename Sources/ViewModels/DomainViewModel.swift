import Foundation

@Observable
@MainActor
final class DomainViewModel {
    var domains: [CivoDomain] = []
    var records: [CivoDomainRecord] = []
    var selectedDomainId: String?
    var isLoading = false
    var error: String?

    var isCreatingDomain = false
    var isCreatingRecord = false
    var isSaving = false
    var saveError: String?
    var showSuccess = false

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
        selectedDomainId = domain
        defer { isLoading = false }

        do {
            records = try await service.listRecords(domain)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createDomain(_ body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.createDomain(body)
            isCreatingDomain = false
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func updateDomain(_ id: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.updateDomain(id, body: body)
            showSuccess = true
            await refresh()
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func createRecord(_ domainId: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.createRecord(domainId, body: body)
            isCreatingRecord = false
            showSuccess = true
            await loadRecords(for: domainId)
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func updateRecord(_ domainId: String, recordId: String, body: sending [String: Any]) async -> Bool {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            _ = try await service.updateRecord(domainId, recordId: recordId, body: body)
            showSuccess = true
            await loadRecords(for: domainId)
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }

    func removeRecord(_ domainId: String, recordId: String) async {
        do {
            try await service.removeRecord(domainId, recordId: recordId)
            await loadRecords(for: domainId)
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
