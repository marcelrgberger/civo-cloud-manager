import Foundation

/// Which sizes an instance may be resized to.
///
/// Civo resizes an instance "upwards, providing it's within their quota" (https://www.civo.com/api/instances),
/// and its CLI states that downgrades are not possible. Neither says how CPU, RAM and disk are weighed, so a
/// size is offered only when none of them is smaller and at least one is larger than the instance has now.
/// Quota and region are checked by Civo, whose error is shown.
enum InstanceResize {
    /// App policy, not a Civo rule: neither the Civo API documentation, its CLI nor its Terraform provider
    /// states which statuses allow a resize, so the app offers it only for ACTIVE instances.
    static func isAllowed(status: String?) -> Bool {
        status?.caseInsensitiveCompare("active") == .orderedSame
    }

    /// Selectable, larger instance sizes, smallest first. Empty unless the current CPU, RAM and disk are
    /// all known, because otherwise no size can be shown not to be smaller.
    static func eligibleSizes(_ sizes: [CivoSize], for instance: CivoInstance) -> [CivoSize] {
        let currentSize = sizes.first { $0.name == instance.size }
        guard let cpu = instance.cpuCores ?? currentSize?.effectiveCpu,
              let ram = instance.ramMb ?? currentSize?.effectiveRam,
              let disk = instance.diskGb ?? currentSize?.effectiveDisk else { return [] }
        let current = [cpu, ram, disk]

        return sizes
            .compactMap { size in dimensions(of: size).map { (size, $0) } }
            .filter { size, offered in
                size.selectable != false
                    && size.name != instance.size
                    && isInstanceSize(size)
                    && zip(offered, current).allSatisfy(>=)
                    && offered != current
            }
            .sorted { $0.1.lexicographicallyPrecedes($1.1) }
            .map(\.0)
    }

    /// The documented size payload has no `type`. Without one, a size counts as an instance size unless
    /// its name carries Civo's Kubernetes or database marker, for example `g4s.kube.small` or `g3.db.small`.
    private static func isInstanceSize(_ size: CivoSize) -> Bool {
        if let type = size.type, !type.isEmpty {
            return type.caseInsensitiveCompare("instance") == .orderedSame
        }
        let name = size.name.lowercased()
        return !name.contains(".kube.") && !name.contains(".db.")
    }

    /// nil when CPU, RAM or disk is unknown: such a size cannot be shown not to be smaller.
    private static func dimensions(of size: CivoSize) -> [Int]? {
        guard let cpu = size.effectiveCpu, let ram = size.effectiveRam, let disk = size.effectiveDisk else { return nil }
        return [cpu, ram, disk]
    }
}

/// Estimated cost change of a resize, from the editable hourly rates.
struct ResizeCostEstimate: Equatable {
    let currentHourly: Double
    let newHourly: Double

    /// nil when either rate is unknown, so a missing rate is never shown as $0.
    init?(currentHourly: Double?, newHourly: Double?) {
        guard let currentHourly, let newHourly else { return nil }
        self.currentHourly = currentHourly
        self.newHourly = newHourly
    }

    var hourlyDifference: Double { newHourly - currentHourly }
    var monthlyDifference: Double { hourlyDifference * CivoCharge.hoursPerMonth }
}
