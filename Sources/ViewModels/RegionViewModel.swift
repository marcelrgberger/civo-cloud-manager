import Foundation

@Observable
@MainActor
final class RegionViewModel {
    var regions: [CivoRegion] = []
    var isLoading = false
    var error: String?

    private let service = CivoRegionService()

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            regions = try await service.listRegions()
        } catch {
            self.error = error.localizedDescription
            Log.error("Region list failed: \(error.localizedDescription)")
        }
    }

    func useRegion(_ code: String) {
        CivoConfig.shared.region = code
        // Update the list to reflect new current region
        // (regions from API won't change, but we track current locally)
    }
}
