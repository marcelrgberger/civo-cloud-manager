#if DEBUG
import Foundation
import Testing

@testable import CivoCloudManager

private func body(_ path: String, query: String = "") -> Data {
    DemoRouter.respond(method: "GET", url: URL(string: "https://api.civo.com/v2\(path)\(query)")!).body
}

private let decoder = JSONDecoder()

@Suite("Demo fixtures")
struct DemoFixtureTests {
    @Test("Every fixture decodes with the real models, so a model change cannot blank a store screenshot")
    func fixturesDecodeWithRealModels() throws {
        #expect(try decoder.decode(PaginatedResponse<CivoInstance>.self, from: body("/instances")).items.count == 12)
        #expect(try decoder.decode(CivoQuota.self, from: body("/quota")).instanceCountUsage == 12)
        #expect(try decoder.decode([CivoRegion].self, from: body("/regions")).count == 3)
        #expect(try decoder.decode([CivoNetwork].self, from: body("/networks")).count == 2)
        #expect(try decoder.decode([CivoSize].self, from: body("/sizes")).count == 6)
        let firewalls = try decoder.decode([CivoFirewall].self, from: body("/firewalls"))
        #expect(firewalls.map(\.name) == ["web-frontend", "internal-only", "admin-access", "default"])
        #expect(try decoder.decode([CivoRule].self, from: body("/firewalls/\(firewalls[0].id)/rules")).count == 9)
        #expect(try decoder.decode(PaginatedResponse<CivoReservedIP>.self, from: body("/ips")).items.count == 5)
        #expect(try decoder.decode(PaginatedResponse<CivoKubernetesCluster>.self, from: body("/kubernetes/clusters")).items.count == 2)
        #expect(try decoder.decode(PaginatedResponse<CivoDatabase>.self, from: body("/databases")).items.count == 2)
        #expect(try decoder.decode(PaginatedResponse<CivoObjectStore>.self, from: body("/objectstores")).items.count == 2)
        #expect(try decoder.decode([CivoVolume].self, from: body("/volumes")).count == 3)
        #expect(try decoder.decode([CivoLoadBalancer].self, from: body("/loadbalancers")).count == 1)
    }

    @Test("The data shows what each screenshot needs: a narrowing tag filter, larger sizes, upgrade targets and free reserved IPs")
    func screensHaveContent() throws {
        let instances = try decoder.decode(PaginatedResponse<CivoInstance>.self, from: body("/instances")).items
        #expect(instances.filter { $0.hasTag(matching: "web") }.count == 3)

        let sizes = try decoder.decode([CivoSize].self, from: body("/sizes"))
        let web = try #require(instances.first { $0.name == "web-01" })
        #expect(InstanceResize.options(sizes, for: web).sizes.count >= 3)
        #expect(InstanceResize.isAllowed(status: web.status))

        let cluster = try #require(
            decoder.decode(PaginatedResponse<CivoKubernetesCluster>.self, from: body("/kubernetes/clusters")).items.first)
        #expect(KubernetesVersionCatalog.upgradeBlocker(for: cluster) == nil)
        let versions = try decoder.decode([CivoKubernetesVersion].self, from: body("/kubernetes/versions"))
        let targets = try KubernetesVersionCatalog.upgradeTargets(from: try #require(cluster.kubernetesVersion), in: versions).get()
        #expect(targets.count >= 2)

        let ips = try decoder.decode(PaginatedResponse<CivoReservedIP>.self, from: body("/ips")).items
        #expect(ips.filter { $0.assignment == .unassigned }.count == 2)
    }

    @Test("Charges cover any requested month up to now and never lie in the future")
    func chargesFollowTheWindow() throws {
        let formatter = ISO8601DateFormatter()
        let from = try #require(formatter.date(from: "2026-11-01T00:00:00Z"))
        let now = try #require(formatter.date(from: "2026-11-11T00:00:00Z"))
        let charges = DemoFixtures.charges(from: from, to: try #require(formatter.date(from: "2026-11-30T23:59:59Z")), now: now)
        #expect(charges.count == 9)
        #expect(charges.allSatisfy { $0["num_hours"] as? Double == 240 })
        #expect(DemoFixtures.charges(from: now.addingTimeInterval(86_400), to: now.addingTimeInterval(172_800), now: now).isEmpty)
    }

    @Test("No fixture carries an initial password, token or an address outside the documentation and private ranges")
    func noSecretsOrRealAddresses() throws {
        let paths = ["/instances", "/ips", "/kubernetes/clusters", "/databases", "/loadbalancers", "/firewalls/x/rules", "/networks"]
        let allowed = ["192.0.2.", "198.51.100.", "203.0.113.", "10.0.", "0.0.0.0"]
        let address = try Regex(#"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"#)
        for path in paths {
            let text = String(decoding: body(path), as: UTF8.self)
            #expect(!text.contains("initial_password") && !text.contains("kubeconfig") && !text.contains("password"))
            for match in text.matches(of: address) {
                #expect(allowed.contains { String(text[match.range]).hasPrefix($0) }, "\(path): \(text[match.range])")
            }
        }
    }
}

@Suite("Demo router")
struct DemoRouterTests {
    private let api = "https://api.civo.com/v2"

    @Test("Writes are rejected, so a mistaken click can never look like a successful change")
    func writesAreRejected() throws {
        for method in ["POST", "PUT", "PATCH", "DELETE"] {
            let response = DemoRouter.respond(method: method, url: try #require(URL(string: "\(api)/instances/abc")))
            #expect(response.status == 405)
            #expect(response.kind == .rejectedWrite)
        }
    }

    @Test("A path without fixture answers 404 locally and a console session cannot start")
    func unknownPathsAreUnrouted() throws {
        for path in ["/nonsense", "/instances/\(DemoFixtures.id(4, 1))/vnc"] {
            let response = DemoRouter.respond(method: "GET", url: try #require(URL(string: "\(api)\(path)")))
            #expect(response.status == 404)
            #expect(response.kind == .unrouted)
        }
    }

    @Test("The recovery status is served for a demo instance only and cannot be changed")
    func recoveryStatusIsServedForKnownInstances() throws {
        let known = DemoFixtures.id(4, 1)
        let status = DemoRouter.respond(method: "GET", url: try #require(URL(string: "\(api)/instances/\(known)/recovery?region=lon1")))
        #expect(status.kind == .served)
        #expect(try decoder.decode(InstanceRecoveryStatus.self, from: status.body).isEnabled == false)

        let unknown = DemoRouter.respond(method: "GET", url: try #require(URL(string: "\(api)/instances/\(DemoFixtures.id(4, 99))/recovery")))
        #expect(unknown.kind == .unrouted)
        let change = DemoRouter.respond(method: "PUT", url: try #require(URL(string: "\(api)/instances/\(known)/recovery")))
        #expect(change.kind == .rejectedWrite)
    }

    @Test("Other hosts are blocked and never answered with data")
    func externalHostsAreBlocked() throws {
        let response = DemoRouter.respond(method: "GET", url: try #require(URL(string: "https://api.ipify.org")))
        #expect(response.status == 404)
        #expect(response.kind == .blockedExternal)
    }
}

/// These suites run in a host that was launched in demo mode, which only the `CivoCloudManagerDemoHost` scheme does.
/// A host started the normal way has already read the real Keychain and defaults before any test code runs.
@Suite("Demo isolation", .serialized, .enabled(if: DemoMode.isActive, "run with the CivoCloudManagerDemoHost scheme"))
@MainActor
struct DemoIsolationTests {
    @Test("Startup built the app state in the sandbox: trial start, credentials and region never came from the real ones")
    func startupUsedTheSandbox() {
        #expect(AppEnvironment.defaults !== UserDefaults.standard)
        #expect(AppEnvironment.defaults.object(forKey: "fullAccessTrialStartedAt") != nil)
        #expect(AppEnvironment.supportDirectory.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        #expect(StoreManager.shared.isFullAccessUnlocked)
        #expect(CivoConfig.shared.apiKey == DemoMode.apiKey)
        #expect(CivoConfig.shared.region == DemoMode.region)
        CivoConfig.shared.apiKey = "must-not-be-stored"
        #expect(CivoConfig.shared.apiKey == DemoMode.apiKey)
    }

    @Test("The shared API client is served by the demo protocol, not by the network")
    func apiClientReadsFixtures() async throws {
        let regions: [CivoRegion] = try await CivoAPIClient.shared.getArray(path: "/regions", regionRequired: false)
        #expect(regions.map(\.code) == ["lon1", "fra1", "nyc1"])
    }

    @Test("IP detection returns the documentation address without a lookup")
    func ipDetectionStaysLocal() async throws {
        let before = DemoTraffic.shared.blocked
        #expect(try await IPDetector().detectIP() == DemoFixtures.documentationIP)
        #expect(DemoTraffic.shared.blocked == before)
    }

    @Test("Opening an active cluster loads its detail but never connects, so no IP lookup, firewall write or kubeconfig request follows")
    func clusterDetailDoesNotAutoConnect() async throws {
        let traffic = (unrouted: DemoTraffic.shared.unrouted, blocked: DemoTraffic.shared.blocked)
        let model = KubernetesViewModel()
        await model.loadClusterDetail(DemoFixtures.id(3, 1))
        try await Task.sleep(for: .milliseconds(500))
        #expect(model.selectedCluster?.name == "demo-cluster")
        #expect(!model.isK8sConnected)
        #expect(model.k8sError == nil)
        #expect(DemoTraffic.shared.unrouted == traffic.unrouted && DemoTraffic.shared.blocked == traffic.blocked)
    }

    @Test("Opening an instance detail reads its instance and recovery status through the real service and model without an unrouted or blocked request")
    func instanceDetailReadsLeaveTrafficUnchanged() async throws {
        let traffic = (unrouted: DemoTraffic.shared.unrouted, blocked: DemoTraffic.shared.blocked)
        let service = CivoInstanceService()
        let instances = try await service.listInstances(region: DemoMode.region)
        let web = try #require(instances.items.first { $0.name == "web-01" })
        let status = try await service.recoveryStatus(of: web.id, region: DemoMode.region)
        #expect(!status.isEnabled)
        #expect(DemoTraffic.shared.unrouted == traffic.unrouted && DemoTraffic.shared.blocked == traffic.blocked)
    }

    @Test("Every session of the app is intercepted per session, because global registration does not reach custom sessions")
    func everySessionIsContained() async throws {
        let sessions: [String: URLSession] = [
            "kubernetes": URLSession(configuration: KubernetesAPIClient.sessionConfiguration()),
            "console": URLSession(configuration: CivoConsoleService.sessionConfiguration()),
            "shared": DemoNetwork.sharedSession,
        ]
        let probe = try #require(URL(string: "https://containment-probe.invalid/probe"))
        for (name, session) in sessions {
            let before = DemoTraffic.shared.blocked
            let (_, response) = try await session.data(from: probe)
            #expect((response as? HTTPURLResponse)?.statusCode == 404, "\(name)")
            #expect(DemoTraffic.shared.blocked == before + 1, "\(name)")
        }
    }
}
#endif
