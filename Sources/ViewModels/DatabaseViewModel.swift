import Foundation

@Observable
@MainActor
final class DatabaseViewModel {
    var databases: [CivoDatabase] = []
    var isLoading = false
    var error: String?

    private let service = CivoDatabaseService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            databases = try await service.listDatabases()
        } catch {
            self.error = error.localizedDescription
            Log.error("Database list failed: \(error.localizedDescription)")
        }
    }

    func removeDatabase(_ name: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await service.removeDatabase(name)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
