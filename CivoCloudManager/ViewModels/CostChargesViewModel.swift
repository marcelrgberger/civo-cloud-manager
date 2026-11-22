import Foundation

/// Charges shown by the cost dashboard.
///
/// Every load gets an id; only the latest load may publish. An API key change invalidates
/// the running load and clears the displayed charges, so results of the previous account
/// are never shown for the new one.
@Observable
@MainActor
final class CostChargesViewModel {
    private(set) var charges: [CivoCharge] = []
    private(set) var isLoading = false
    private(set) var error: String?
    /// Changes with every account switch, so the view can restart its load task.
    private(set) var accountGeneration = 0

    private let service: CivoChargesService
    private var latestLoad = 0

    init(service: CivoChargesService = CivoChargesService()) {
        self.service = service
    }

    var currentDate: Date { service.currentDate }

    func load(_ period: ChargePeriod, trigger: ChargeLoadTrigger = .automatic) async {
        latestLoad += 1
        let load = latestLoad
        isLoading = true
        error = nil
        // A superseded load must not end the spinner of the load that replaced it.
        defer { if load == latestLoad { isLoading = false } }

        do {
            let loaded = try await service.charges(for: period, trigger: trigger)
            guard load == latestLoad else { return }
            charges = loaded
        } catch {
            guard load == latestLoad, let message = ChargesLoadError.userMessage(error) else { return }
            charges = []
            self.error = message
        }
    }

    func apiKeyDidChange() {
        latestLoad += 1
        accountGeneration += 1
        charges = []
        error = nil
        isLoading = false
    }
}
