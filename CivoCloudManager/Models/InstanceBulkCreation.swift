import Foundation

/// Limits and cost of creating several instances with one `POST /v2/instances` (`count`).
enum InstanceBulkCreation {
    /// The upper bound of the count, at least 1: one instance can always be requested, and Civo then reports
    /// an exceeded quota itself. Without a loaded quota, only one instance at a time.
    static func maximumCount(quota: CivoQuota?, size: CivoSize?, createsPublicIp: Bool) -> Int {
        max(1, capacity(quota: quota, size: size, createsPublicIp: createsPublicIp) ?? 1)
    }

    /// How many instances of `size` fit the remaining quota, 0 or less when it is used up, nil without a quota.
    static func capacity(quota: CivoQuota?, size: CivoSize?, createsPublicIp: Bool) -> Int? {
        guard let quota else { return nil }
        var limits = [quota.instanceCountLimit - quota.instanceCountUsage]
        if createsPublicIp {
            limits.append(quota.publicIpAddressLimit - quota.publicIpAddressUsage)
        }
        if let size {
            limits += [
                fitting(quota.cpuCoreLimit - quota.cpuCoreUsage, each: size.effectiveCpu),
                fitting(quota.ramMbLimit - quota.ramMbUsage, each: size.effectiveRam),
                fitting(quota.diskGbLimit - quota.diskGbUsage, each: size.effectiveDisk),
            ].compactMap { $0 }
        }
        return limits.min()
    }

    /// How many instances needing `each` fit into `free`, nil when the size does not state its need.
    private static func fitting(_ free: Int, each: Int?) -> Int? {
        guard let each, each > 0 else { return nil }
        return free / each
    }

    /// The hourly rate of an instance size from the user-editable rates (`CivoCharge.hourlyRates`),
    /// which are keyed like Civo's charge codes (`instance-g3.small`).
    static func hourlyRate(ofSize name: String, rates: [String: Double]) -> Double? {
        rates["instance-\(name)"] ?? rates[name]
    }
}

/// The confirmation shown before more than one instance is created.
struct BulkCreationConfirmation: Equatable {
    let count: Int
    let sizeName: String
    /// `count` times the size's hourly rate, nil when no rate is known. Public IP addresses are not priced.
    let totalHourlyCost: Double?

    /// nil for a single instance, which is created without this confirmation.
    init?(count: Int, size: String, rates: [String: Double]) {
        guard count > 1 else { return nil }
        self.count = count
        sizeName = size
        totalHourlyCost = InstanceBulkCreation.hourlyRate(ofSize: size, rates: rates).map { Double(count) * $0 }
    }

    var title: String {
        String(localized: "Create \(count) instances?")
    }

    var message: String {
        guard let totalHourlyCost else {
            return String(localized: "\(count) instances of size \(sizeName) will be created. No hourly rate is known for this size, so no cost can be estimated.")
        }
        let cost = totalHourlyCost.formatted(.currency(code: "USD").precision(.fractionLength(2...4)))
        return String(localized: "\(count) instances of size \(sizeName) will be created, at an estimated \(cost) per hour in total. Public IP addresses are not included in this estimate.")
    }
}
