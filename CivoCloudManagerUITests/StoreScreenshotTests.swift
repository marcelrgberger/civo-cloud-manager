import AppKit
import XCTest

/// Captures the eight store screenshots of one UI language from the demo-data app (see docs/store-screenshots.md).
///
/// Environment (set through `TEST_RUNNER_` variables by scripts/capture_store_screenshots.sh):
/// - `CCM_CAPTURE_LANG`: the UI language folder, for example `de`
/// - `CCM_CAPTURE_OUT`: the directory that receives `<lang>/NN-<screen>.png`
/// - `CCM_STRINGS_PATH`: the app's Localizable.xcstrings, to check that the UI really is in that language
@MainActor
final class StoreScreenshotTests: XCTestCase {
    private static let windowSize = CGSize(width: 1440, height: 900)
    private static let pixelSize = CGSize(width: 2880, height: 1800)
    private static let locales = [
        "en": "en_US", "de": "de_DE", "fr": "fr_FR", "es": "es_ES", "it": "it_IT", "ja": "ja_JP", "ko": "ko_KR",
        "nl": "nl_NL", "pl": "pl_PL", "pt": "pt_PT", "ru": "ru_RU", "tr": "tr_TR", "zh-Hans": "zh_CN",
        "ar": "ar_SA", "hi": "hi_IN", "id": "id_ID",
    ]
    private static let timeout: TimeInterval = 20

    private var app: XCUIApplication!
    private var language = "en"
    private var outputDirectory: URL!

    override func setUp() async throws {
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        language = environment["CCM_CAPTURE_LANG"] ?? "en"
        let locale = try XCTUnwrap(Self.locales[language], "unsupported language \(language)")
        let output = try XCTUnwrap(environment["CCM_CAPTURE_OUT"], "CCM_CAPTURE_OUT is not set")
        outputDirectory = URL(fileURLWithPath: output).appendingPathComponent(language, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        app = XCUIApplication()
        app.launchArguments = [
            "-CCMDemoData", "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            "-ApplePersistenceIgnoreState", "YES", "-NSAutomaticWindowAnimationsEnabled", "NO",
        ]
        app.launch()
        XCTAssertTrue(window.waitForExistence(timeout: Self.timeout), "the main window did not open")
    }

    override func tearDown() async throws {
        app.terminate()
    }

    // MARK: - Screens

    func test01Dashboard() throws {
        try assertInterfaceLanguage()
        wait(for: AccessibilityID.dashboardResources)
        wait(for: AccessibilityID.dashboardQuota)
        try capture("01-dashboard")
    }

    func test02FirewallChange() throws {
        openFirstInstance(named: "web-01")
        element(AccessibilityID.instanceChangeFirewall).click()
        wait(for: AccessibilityID.firewallOption("internal-only")).click()
        try capture("02-firewall-change")
    }

    func test03FirewallRules() throws {
        open(section: "firewalls")
        wait(for: AccessibilityID.firewallRow("web-frontend")).click()
        wait(for: AccessibilityID.ruleRow(3)).rightClick()
        app.menuItems.element(boundBy: 0).click()
        let port = wait(for: AccessibilityID.ruleStartPort)
        port.click()
        port.typeKey("a", modifierFlags: .command)
        port.typeText("9443")
        wait(for: AccessibilityID.ruleChanges)
        try capture("03-firewall-rules")
    }

    func test04Resize() throws {
        openFirstInstance(named: "web-01")
        element(AccessibilityID.instanceResize).click()
        wait(for: AccessibilityID.size("g3.large")).click()
        wait(for: AccessibilityID.resizeCostEstimate)
        try capture("04-resize")
    }

    func test05KubernetesUpgrade() throws {
        open(section: "clusters")
        wait(for: AccessibilityID.clusterRow("demo-cluster")).click()
        wait(for: AccessibilityID.clusterUpgrade).click()
        wait(for: AccessibilityID.upgradeVersionPicker).click()
        XCTAssertTrue(app.menuItems.element(boundBy: 2).waitForExistence(timeout: Self.timeout), "the version list did not load")
        try capture("05-k8s-upgrade")
    }

    func test06ReservedIPs() throws {
        open(section: "reservedIPs")
        wait(for: AccessibilityID.reservedIPRow("ip-spare-a")).click()
        wait(for: AccessibilityID.reservedIPAssign).click()
        wait(for: AccessibilityID.reservedIPInstancePicker)
        try capture("06-reserved-ips")
    }

    func test07TagFilter() throws {
        open(section: "instances")
        wait(for: AccessibilityID.instanceRow("api-01"))
        let filter = element(AccessibilityID.instancesTagFilter)
        filter.click()
        filter.typeText("web")
        wait(for: AccessibilityID.instanceRow("web-03"))
        XCTAssertTrue(waitForAbsence(of: AccessibilityID.instanceRow("api-01")), "the tag filter did not narrow the list")
        try capture("07-tag-filter")
    }

    func test08Billing() throws {
        open(section: "costs")
        wait(for: AccessibilityID.costsTotal)
        wait(for: AccessibilityID.costsBreakdown)
        try capture("08-billing")
    }

    // MARK: - Navigation

    private var window: XCUIElement { app.windows.firstMatch }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @discardableResult
    private func wait(for identifier: String) -> XCUIElement {
        let match = element(identifier)
        XCTAssertTrue(match.waitForExistence(timeout: Self.timeout), "\(identifier) did not appear")
        return match
    }

    private func waitForAbsence(of identifier: String) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element(identifier))
        return XCTWaiter().wait(for: [gone], timeout: Self.timeout) == .completed
    }

    private func open(section: String) {
        wait(for: AccessibilityID.sidebar(section)).click()
    }

    private func openFirstInstance(named name: String) {
        open(section: "instances")
        wait(for: AccessibilityID.instanceRow(name)).click()
    }

    // MARK: - Capture

    /// The sidebar must show the language under test, not the English fallback: three titles are compared with the
    /// catalogue. A title the catalogue leaves untranslated is expected in English.
    private func assertInterfaceLanguage() throws {
        let path = try XCTUnwrap(ProcessInfo.processInfo.environment["CCM_STRINGS_PATH"], "CCM_STRINGS_PATH is not set")
        let catalogue = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as? [String: Any]
        let strings = try XCTUnwrap(catalogue?["strings"] as? [String: [String: Any]])
        for key in ["Dashboard", "Instances", "Cost Estimate"] {
            let localizations = strings[key]?["localizations"] as? [String: [String: [String: String]]]
            let expected = localizations?[language]?["stringUnit"]?["value"] ?? key
            XCTAssertTrue(app.staticTexts[expected].firstMatch.waitForExistence(timeout: Self.timeout), "sidebar title \(expected) for \(key)")
        }
    }

    /// Waits for animations to settle, checks that demo mode served every request and showed no error,
    /// then saves the window as an exact 2880 x 1800 px PNG.
    private func capture(_ name: String) throws {
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(window.frame.size, Self.windowSize, "window size in points")
        let status = try XCTUnwrap(element(AccessibilityID.demoStatus).value as? String)
        XCTAssertEqual(status, "unrouted=0 blocked=0", "demo traffic before \(name)")
        XCTAssertFalse(element(AccessibilityID.errorBanner).exists, "an error banner is visible in \(name)")

        let png = window.screenshot().pngRepresentation
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: png))
        XCTAssertEqual(CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh), Self.pixelSize, "pixel size of \(name)")
        try png.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }
}
