/// Language independent accessibility identifiers of the controls the store screenshot UI test drives.
/// The test target compiles this file as well, so the app and the test cannot drift apart.
enum AccessibilityID {
    static func sidebar(_ section: String) -> String { "sidebar.\(section)" }
    static func instanceRow(_ name: String) -> String { "instance.row.\(name)" }
    static func firewallOption(_ name: String) -> String { "firewall.option.\(name)" }
    static func firewallRow(_ name: String) -> String { "firewall.row.\(name)" }
    static func ruleRow(_ index: Int) -> String { "rule.row.\(index)" }
    static func clusterRow(_ name: String) -> String { "cluster.row.\(name)" }
    static func reservedIPRow(_ name: String) -> String { "reservedIP.row.\(name)" }
    static func size(_ name: String) -> String { "size.\(name)" }

    static let demoStatus = "demo.status"
    static let dashboardQuota = "dashboard.quota"
    static let dashboardResources = "dashboard.resources"
    static let instanceChangeFirewall = "instance.changeFirewall"
    static let instanceResize = "instance.resize"
    static let instancesTagFilter = "instances.tagFilter"
    static let resizeCostEstimate = "resize.costEstimate"
    static let ruleStartPort = "rule.startPort"
    static let ruleChanges = "rule.changes"
    static let clusterUpgrade = "cluster.upgrade"
    static let upgradeVersionPicker = "upgrade.versionPicker"
    static let reservedIPAssign = "reservedIP.assign"
    static let reservedIPInstancePicker = "reservedIP.instancePicker"
    static let costsTotal = "costs.total"
    static let costsBreakdown = "costs.breakdown"
    static let errorBanner = "error.banner"
}
