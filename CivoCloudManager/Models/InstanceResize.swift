import Foundation

/// Which sizes an instance may be resized to.
///
/// Civo resizes an instance "upwards, providing it's within their quota" (https://www.civo.com/api/instances),
/// and its CLI states that downgrades are not possible. Neither says how CPU, RAM and disk are weighed, so a
/// size is offered only when none of them is smaller and at least one is larger than the instance has now.
/// Quota and region are checked by Civo, whose error is shown.
enum InstanceResize {
    /// Product policy recorded on ticket #89 (2026-11-22): the app offers a resize only for ACTIVE instances.
    /// This is the app's own conservative choice, not a Civo rule. Neither the Civo API documentation, its CLI
    /// nor its Terraform provider states which statuses allow a resize, and civogo's API error
    /// `instance_state_must_be_active_or_shutoff` does not say which actions return it, so other statuses such
    /// as SHUTOFF are not offered until a source establishes them.
    static func isAllowed(status: String?) -> Bool {
        status?.caseInsensitiveCompare("active") == .orderedSame
    }

    /// The selectable, larger instance sizes, or `.comparisonUnavailable` unless the current CPU, RAM and disk
    /// are all known, because otherwise no size can be shown not to be smaller.
    static func options(_ sizes: [CivoSize], for instance: CivoInstance) -> ResizeOptions {
        let currentSize = sizes.first { $0.name == instance.size }
        guard let cpu = instance.cpuCores ?? currentSize?.effectiveCpu,
              let ram = instance.ramMb ?? currentSize?.effectiveRam,
              let disk = instance.diskGb ?? currentSize?.effectiveDisk else { return .comparisonUnavailable }
        let current = [cpu, ram, disk]

        return .larger(sizes
            .compactMap { size in dimensions(of: size).map { (size, $0) } }
            .filter { size, offered in
                size.selectable != false
                    && size.name != instance.size
                    && isInstanceSize(size)
                    && zip(offered, current).allSatisfy(>=)
                    && offered != current
            }
            .sorted { $0.1.lexicographicallyPrecedes($1.1) }
            .map(\.0))
    }

    /// `/v2/sizes` also lists Kubernetes and database sizes: a live LON1 response on 2026-11-22 typed them
    /// `Kubernetes` and `Database` and named them `g4s.kube.small`, `g3.k3s.small` or `g3.db.small`. Only those are
    /// left out. Any other or missing `type` counts as an instance size, so a type the app does not know yet,
    /// or the untyped documented payload, never empties the picker.
    private static func isInstanceSize(_ size: CivoSize) -> Bool {
        if let type = size.type?.lowercased(), otherProductTypes.contains(type) { return false }
        let name = size.name.lowercased()
        return !otherProductNameMarkers.contains { name.contains($0) }
    }

    private static let otherProductTypes: Set<String> = ["kubernetes", "database"]
    private static let otherProductNameMarkers = [".kube.", ".k3s.", ".db."]

    /// nil when CPU, RAM or disk is unknown: such a size cannot be shown not to be smaller.
    private static func dimensions(of size: CivoSize) -> [Int]? {
        guard let cpu = size.effectiveCpu, let ram = size.effectiveRam, let disk = size.effectiveDisk else { return nil }
        return [cpu, ram, disk]
    }
}

/// What the resize sheet can offer an instance.
enum ResizeOptions: Equatable {
    /// Selectable, larger instance sizes, smallest first. Empty only when the comparison found none.
    case larger([CivoSize])
    /// The current CPU, RAM or disk of the instance is unknown, so no size can be shown not to be smaller.
    case comparisonUnavailable

    var sizes: [CivoSize] {
        if case .larger(let sizes) = self { sizes } else { [] }
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
