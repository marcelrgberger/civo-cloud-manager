import Foundation
import Testing
import Security
import CryptoKit

@testable import CivoCloudManager

@Suite("SSH encryption key preservation")
struct SSHEncryptionTests {
    @Test("Finder metadata permits creation; visible and hidden backup files prevent replacement")
    func backupDetection() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let metadata = dir.appendingPathComponent(".DS_Store")
        try Data([1, 2, 3]).write(to: metadata)
        #expect(try SSHKeychain.hasBackups(in: dir))
        try Data([0, 0, 0, 1, 0x42, 0x75, 0x64, 0x31]).write(to: metadata)
        #expect(try !SSHKeychain.hasBackups(in: dir))
        let hidden = dir.appendingPathComponent(".private-key")
        try Data([1]).write(to: hidden)
        #expect(try SSHKeychain.hasBackups(in: dir))
        try FileManager.default.moveItem(at: hidden, to: dir.appendingPathComponent("private-key"))
        #expect(try SSHKeychain.hasBackups(in: dir))
    }

    @Test("Concurrent creation cannot hide failed or missing winner reads")
    func failedWinnerRead() {
        #expect(throws: SSHKeychain.KeyError.keychain(errSecDuplicateItem)) {
            try SSHKeychain.resolveKey(allowCreation: true, read: { nil }, add: { _ in errSecDuplicateItem })
        }
        var reads = 0
        #expect(throws: SSHKeychain.KeyError.keychain(errSecInteractionNotAllowed)) {
            try SSHKeychain.resolveKey(allowCreation: true, read: {
                reads += 1
                if reads > 1 { throw SSHKeychain.KeyError.keychain(errSecInteractionNotAllowed) }
                return nil
            }, add: { _ in errSecDuplicateItem })
        }
    }

    @Test("Locked keychains and malformed keys never cause replacement")
    func readFailure() {
        #expect(throws: SSHKeychain.KeyError.self) {
            try SSHKeychain.resolveKey(allowCreation: true, read: {
                throw SSHKeychain.KeyError.keychain(errSecInteractionNotAllowed)
            }, add: { _ in Issue.record("Replaced unavailable key"); return errSecSuccess })
        }
        #expect(throws: SSHKeychain.KeyError.self) {
            try SSHKeychain.resolveKey(allowCreation: true, read: { Data([1]) },
                                      add: { _ in Issue.record("Replaced malformed key"); return errSecSuccess })
        }
    }

    @Test("Reading backups or saving alongside existing backups cannot create a missing key")
    func missingExistingKey() {
        #expect(throws: SSHKeychain.KeyError.self) {
            try SSHKeychain.resolveKey(allowCreation: false, read: { nil },
                                      add: { _ in Issue.record("Created replacement key"); return errSecSuccess })
        }
    }

    @Test("Failed key persistence prevents encryption with an unpersisted key")
    func failedCreation() {
        #expect(throws: SSHKeychain.KeyError.self) {
            try SSHKeychain.resolveKey(allowCreation: true, read: { nil }, add: { _ in errSecAuthFailed })
        }
    }

    @Test("A concurrent creator wins without replacing or using the losing key")
    func concurrentCreation() throws {
        let winner = Data(repeating: 42, count: 32)
        var reads = 0
        let key = try SSHKeychain.resolveKey(allowCreation: true, read: {
            reads += 1
            return reads == 1 ? nil : winner
        }, add: { _ in errSecDuplicateItem })
        #expect(key.withUnsafeBytes { Data($0) } == winner)
        #expect(reads == 2)
    }

    @Test("Newly persisted keys decrypt backups after reload")
    func roundTrip() throws {
        var stored: Data?
        let key = try SSHKeychain.resolveKey(allowCreation: true, read: { stored }, add: {
            stored = $0
            return errSecSuccess
        })
        let plaintext = Data("private-key-fixture".utf8)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        let reloaded = try SSHKeychain.resolveKey(allowCreation: false, read: { stored },
                                                add: { _ in Issue.record("Replaced stored key"); return errSecSuccess })
        #expect(try AES.GCM.open(sealed, using: reloaded) == plaintext)
    }
}

@Suite("Persistent firewall closures")
@MainActor
struct FirewallClosureTests {
    @Test("Confirmed deletions are not repeated when persistence fails")
    func failedPersistenceAfterDeletion() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("jobs.json")
        let queue = FirewallClosureQueue(file: file)
        try queue.schedule(firewallId: "fw", ruleId: "rule", region: "fra1", closeAt: .distantPast)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        await queue.closeDue { _ in }
        #expect(queue.jobs.isEmpty)
        #expect(queue.lastError != nil)
        try FileManager.default.removeItem(at: file)
        await queue.closeDue { _ in Issue.record("Repeated confirmed deletion") }
        #expect(queue.lastError == nil)
        #expect(FirewallClosureQueue(file: file).jobs.isEmpty)
    }

    @Test("Retry limits survive restart and permit explicit retry")
    func retryLimit() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("jobs.json")
        let queue = FirewallClosureQueue(file: file)
        try queue.schedule(firewallId: "fw", ruleId: "rule", region: "fra1", closeAt: .distantPast)
        for attempt in 0..<8 {
            await queue.closeDue(now: Date(timeIntervalSince1970: Double(attempt) * 7200)) { _ in
                throw URLError(.notConnectedToInternet)
            }
        }
        let restarted = FirewallClosureQueue(file: file)
        #expect(restarted.jobs.first?.failures == 8)
        await restarted.closeDue { _ in Issue.record("Exceeded retry limit") }
        restarted.retryFailures()
        // Simulate quitting immediately after Retry, before another timer tick.
        let afterRetryRestart = FirewallClosureQueue(file: file)
        #expect(afterRetryRestart.jobs.count == 1)
        #expect(afterRetryRestart.jobs.first?.failures == nil)
        #expect(afterRetryRestart.jobs.first?.nextAttempt == nil)
        #expect(afterRetryRestart.jobs.first?.failureMessage == nil)
        await afterRetryRestart.closeDue { _ in }
        #expect(afterRetryRestart.jobs.isEmpty)
    }

    @Test("Failed manual retry persistence stays visible and is retried locally")
    func retryPersistenceFailure() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let file = dir.appendingPathComponent("jobs.json")
        let job = FirewallClosureJob(id: UUID(), firewallId: "fw", ruleId: "rule", region: "fra1",
                                     closeAt: .distantFuture, failures: 8, nextAttempt: .distantFuture,
                                     failureMessage: "Previous failure")
        try JSONEncoder().encode([job]).write(to: file)
        let queue = FirewallClosureQueue(file: file)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        queue.retryFailures()
        #expect(queue.lastError?.contains(file.path) == true)
        #expect(queue.jobs.count == 1)
        try FileManager.default.removeItem(at: file)
        await queue.closeDue { _ in Issue.record("Closed before deadline") }
        #expect(queue.lastError == nil)
        let recovered = FirewallClosureQueue(file: file)
        #expect(recovered.jobs.count == 1)
        #expect(recovered.jobs.first?.failures == nil)
    }

    @Test("Corrupt storage cannot be silently overwritten")
    func corruptStorage() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let original = Data("not-json".utf8)
        try original.write(to: file)
        let queue = FirewallClosureQueue(file: file)
        #expect(queue.lastError != nil)
        #expect(throws: CivoAPIError.self) { try queue.prepare() }
        #expect(try Data(contentsOf: file) == original)
    }

    @Test("Reentrant ticks do not delete the same rule concurrently")
    func overlappingTicks() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let queue = FirewallClosureQueue(file: dir.appendingPathComponent("jobs.json"))
        try queue.schedule(firewallId: "fw", ruleId: "rule", region: "fra1", closeAt: .distantPast)
        var calls = 0
        await queue.closeDue { _ in
            calls += 1
            await queue.closeDue { _ in calls += 1 }
        }
        #expect(calls == 1)
        #expect(queue.jobs.isEmpty)
    }

    @Test("Deadlines survive restart and transient failures without changing region")
    func retryAndRestart() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("jobs.json")
        let queue = FirewallClosureQueue(file: file)
        let deadline = Date(timeIntervalSince1970: 100)
        try queue.schedule(firewallId: "fw", ruleId: "rule", region: "lon1", closeAt: deadline)
        let restarted = FirewallClosureQueue(file: file)
        #expect(restarted.jobs.count == 1)
        await restarted.closeDue(now: deadline.addingTimeInterval(-1)) { _ in Issue.record("Closed before deadline") }
        await restarted.closeDue(now: deadline) { job in
            #expect(job.region == "lon1")
            throw URLError(.notConnectedToInternet)
        }
        #expect(restarted.jobs.count == 1)
        #expect(restarted.lastError != nil)
        #expect(FirewallClosureQueue(file: file).jobs.count == 1)
        await restarted.closeDue(now: deadline) { _ in Issue.record("Retry ignored backoff") }
        await restarted.closeDue(now: deadline.addingTimeInterval(30)) { job in
            #expect(job.firewallId == "fw" && job.ruleId == "rule" && job.region == "lon1")
        }
        #expect(restarted.jobs.isEmpty)
        #expect(restarted.lastError == nil)
        #expect(FirewallClosureQueue(file: file).jobs.isEmpty)
    }

    @Test("Already removed rules complete; failed jobs do not block other closures")
    func independentJobs() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let queue = FirewallClosureQueue(file: dir.appendingPathComponent("jobs.json"))
        for rule in ["failed", "gone"] {
            try queue.schedule(firewallId: "fw", ruleId: rule, region: "fra1", closeAt: .distantPast)
        }
        await queue.closeDue { job in
            if job.ruleId == "failed" { throw CivoAPIError.httpError(503, "Unavailable") }
            throw CivoAPIError.httpError(404, "Gone")
        }
        #expect(queue.jobs.map(\.ruleId) == ["failed"])
    }
}

@Suite("API region routing")
struct RegionRoutingTests {
    @Test("Explicit regions override the selected region without duplicates")
    func explicitRegion() throws {
        let supplied = [URLQueryItem(name: "region", value: "lon1"), URLQueryItem(name: "page", value: "2")]
        let items = try CivoAPIClient.resolvedQueryItems(supplied, defaultRegion: "fra1", regionRequired: true)
        #expect(items.filter { $0.name == "region" }.map(\.value) == ["lon1"])
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
        #expect(try CivoAPIClient.resolvedQueryItems(supplied, defaultRegion: "", regionRequired: true) == items)
        #expect(try CivoAPIClient.resolvedQueryItems(nil, defaultRegion: "fra1", regionRequired: true) == [URLQueryItem(name: "region", value: "fra1")])
        #expect(try CivoAPIClient.resolvedQueryItems(nil, defaultRegion: "fra1", regionRequired: false).isEmpty)
    }
    @Test("Invalid explicit regions fail instead of falling back")
    func invalidRegions() {
        let cases: [[String?]] = [[""], [nil], ["fra1", "lon1"]]
        for values in cases {
            #expect(throws: CivoAPIError.self) {
                try CivoAPIClient.resolvedQueryItems(values.map { URLQueryItem(name: "region", value: $0) }, defaultRegion: "fra1", regionRequired: true)
            }
        }
    }
}

@Suite("Kubernetes TLS trust")
struct KubernetesTrustTests {
    private let serverCertificate = "MIIDZDCCAkygAwIBAgIUWThxTBBVX43jb0Xa9IDI97Wb2ekwDQYJKoZIhvcNAQELBQAwHzEdMBsGA1UEAwwUY2x1c3Rlci5leGFtcGxlLnRlc3QwHhcNMjYwOTA5MDkyOTExWhcNMjcwOTA5MDkyOTExWjAfMR0wGwYDVQQDDBRjbHVzdGVyLmV4YW1wbGUudGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKtXEATYPcER2KK6oEBQGTy15U+ugkOaPThBEGgjxuA3pHXT1Krzqn01olHq0G7lTAsjTZiRiRnB4UkIwpO0h8GuqaUzV1Kezb+8aPxGMgR3ECZWQoudKAbSGmJ4G9mKJZHQfOD2SjnraNO7Xxil6V/riWBJ+OJtRDUqVKNrrjTuuQGdCsANS02wpLpojefGY593WzZOxoVPda047RbeTX/NQfQoqWlKMOcZM4J1FP17KPwtSIfIvUH6gy/rWXL+iMaDa9QiR5RiDTdrKlMj7F26OIqbgm0eP3QS2j6z49S/l08EVg1uU1BaqAa+QuIatKQnYSKOC2Zk5pl1KeHcy4cCAwEAAaOBlzCBlDAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIFoDATBgNVHSUEDDAKBggrBgEFBQcDATAfBgNVHREEGDAWghRjbHVzdGVyLmV4YW1wbGUudGVzdDAdBgNVHQ4EFgQU3PJZ/qHjk1N3E+13jm9A5/ieX6wwHwYDVR0jBBgwFoAUya2acjiuwnDGZigJjyfPnl8s2CYwDQYJKoZIhvcNAQELBQADggEBAIi+J2y8KjzQ4NEhcGmY7bW29/gmQ9Cp4HKEti8FwQP0vP92MOEWe3pPJKGNSbHOHex51zwzwmjrBlAlD5Sn6V7aYZXRZu67r1J9hIXZy1acLMvHnmkzYzK7uuphXUpu2qZotVpFtI6uOBVZaPCd95S9C9h3zoCbxm3OdMI7Yn+ZKInfH99yVBf+8AH9YLUJqVwRCpbsCcOESuzf6neoUjm6pF/evfUosgfNm+rishjLAXQHBWbhLtmnjpXgjd5H4miRVamYLj8SXquA3eM2ReukMpRFfulahyuzEOuLl22GU91U1PaNUjSP726na6QUx5QEs1sxxW5uTUvTylfYDiU="
    private let certificate = "MIIDQDCCAiigAwIBAgIUcKwMgRV3l+JvXXLn7gMCkA/HyU0wDQYJKoZIhvcNAQELBQAwHzEdMBsGA1UEAwwUY2x1c3Rlci5leGFtcGxlLnRlc3QwHhcNMjYwOTA5MDkyODA5WhcNMzYwOTA2MDkyODA5WjAfMR0wGwYDVQQDDBRjbHVzdGVyLmV4YW1wbGUudGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKE1rUmKyDMQ8nKOxl3qeX85QHBUuHmKPnPeDaHp5FH69KYQkD0Y5dOOKPkBZYmjLGV3vufqm6tEqLvaj65wlr10ze1SeytRsxz/A6KYY2/xfI53uVKf1Crn6F/e1LJvZ9dqERscqv3k5NjJ2E+I7sutfGIca24Qv4A5llbnFvIZqlEqHQjXzVP1+owdsq0VSDs5tKNokKLGLmfB8EZ0ewW/HlvGu8DxRJksw81d6hoyt9v0UzRbV/lHqSQK25PrhhIXhGID4x655tjPdRq9kCssl0n3+pNm4mrvH0w/S923xwEXWuzUfLzndshVTXGabeKDq6WBYk1tUtcmblHJ+f8CAwEAAaN0MHIwHQYDVR0OBBYEFMmtmnI4rsJwxmYoCY8nz55fLNgmMB8GA1UdIwQYMBaAFMmtmnI4rsJwxmYoCY8nz55fLNgmMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0RBBgwFoIUY2x1c3Rlci5leGFtcGxlLnRlc3QwDQYJKoZIhvcNAQELBQADggEBAEy9Bl4/7/eBAObRiDJMkE+o3z+XSTcD3C2ZX6T1zEg6ZZUSvcILNTbt+P9aBAj79+e8T201OpI7XYp6jNzHOeiWhm5STs+jUTgPSZEeaP8br7CHYeVGoMFtlbMywHTHxvyUZnefPhk5/Hv59cdsDBlybVnmYATP6Xx4fbmd1PeYw06WOXEOeasHOfMSfUT679lW7d/c5VDOZrSKQx0S4x+++kLoJhVzngSvabYkYLQZikhJqGkAdSihyRwMPq3d0nejmhHeOH4WEHDFIJ9AYk/3qNrvMXz2TYjVjtXo1MiICavGI8eYE7mLnSoRPGQGLHb7LOkNJuaOOuNh4pB7kTk="
    private let unrelatedCA = "MIIDDzCCAfegAwIBAgIUbUG+SLSN7KdppUwi0znGgH5xn44wDQYJKoZIhvcNAQELBQAwFzEVMBMGA1UEAwwMVW5yZWxhdGVkIENBMB4XDTI2MDkwOTA5MjgzN1oXDTM2MDkwNjA5MjgzN1owFzEVMBMGA1UEAwwMVW5yZWxhdGVkIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApH2Se6jowIqVnIb9EUx4Ip5AxZmfH3ZMkCDgBaKBlWZ74ELhfK8aJEekCYq/wXo1um+gZyfCuxttcW3VY4w8wc8pis1xkk7Y8Zcgg0jasyq0jSjwgoirlxa7WYL4svDeXUKW3cK+IIDyXgb1RX8ZLU2s1uXoIlHJUg86XiglkGDU1PAB0vP9zEYQJFkz+lf1B4ghIn7qoR2jkUN472JOm7IPu6/5wsDFigsqcNfpdufzYsWviUyOL7gT48RcctSrD7MgrgOuQIi0kIMPwaOUm56Jt0tv/iPCSqaZBn4WQmNmEY4cA3wfW6rwWSiaTPTavpHbuckcUCZislyF5H8edwIDAQABo1MwUTAdBgNVHQ4EFgQU+WskWPPk3MAFygYtwZKLs5rxg2owHwYDVR0jBBgwFoAU+WskWPPk3MAFygYtwZKLs5rxg2owDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAGbEwCUJLguBzCgrpVP4+43cteUX+PpuJfmSjyfZh+VGz3gmP4CXidDdC1xJhSmHppV9d0g4FPVqRuudGHTZgbqLAzEHSXj2OB6Y614ATfrxjWolh8ARsWIRwkQwgl/F4M3aG35qLLeOfCuXQ5YMYoeHzVpyS0XHnIan821LaRNlORbVXqLKOMUDW35LkX2tXJjLYPKCH7zl7DDQotXWF82tug+jJjdrNio5ZAHyX2yWnm7u8wsR1rlXV4x3Ni+VjTypdxiQVaO5K69TdYMgMHhQl2QAcU5lj3GGzPSPrSLO+SooCymG7e1FClMEwxSpXYNqkyNhDmTq3msLFo7hlrw=="

    @Test("Only the configured CA, matching hostname and valid dates are accepted")
    func serverTrust() throws {
        let certData = try #require(Data(base64Encoded: certificate))
        let otherData = try #require(Data(base64Encoded: unrelatedCA))
        let leafData = try #require(Data(base64Encoded: serverCertificate))
        let cert = try #require(SecCertificateCreateWithData(nil, certData as CFData))
        let other = try #require(SecCertificateCreateWithData(nil, otherData as CFData))
        let leaf = try #require(SecCertificateCreateWithData(nil, leafData as CFData))
        func trust(at date: Date) throws -> SecTrust {
            var result: SecTrust?
            #expect(SecTrustCreateWithCertificates([leaf, cert] as CFArray, SecPolicyCreateBasicX509(), &result) == errSecSuccess)
            let trust = try #require(result)
            SecTrustSetVerifyDate(trust, date as CFDate)
            SecTrustSetNetworkFetchAllowed(trust, false)
            return trust
        }
        let validDate = Date(timeIntervalSince1970: 1789041600)
        #expect(KubernetesAPIClient.validateServerTrust(try trust(at: validDate), host: "cluster.example.test", caCertificate: cert))
        #expect(!KubernetesAPIClient.validateServerTrust(try trust(at: validDate), host: "attacker.example.test", caCertificate: cert))
        #expect(!KubernetesAPIClient.validateServerTrust(try trust(at: validDate), host: "cluster.example.test", caCertificate: other))
        let expiredDate = Date(timeIntervalSince1970: 1900000000)
        #expect(!KubernetesAPIClient.validateServerTrust(try trust(at: expiredDate), host: "cluster.example.test", caCertificate: cert))
        let validTrust = try trust(at: validDate)
        var callbacks = 0
        KubernetesAPIClient.handleServerTrust(validTrust, host: "cluster.example.test", caCertificate: cert) { disposition, credential in
            callbacks += 1
            #expect(disposition == .useCredential)
            #expect(credential != nil)
        }
        for candidate in [nil, try trust(at: expiredDate)] as [SecTrust?] {
            KubernetesAPIClient.handleServerTrust(candidate, host: "cluster.example.test", caCertificate: cert) { disposition, credential in
                callbacks += 1
                #expect(disposition == .cancelAuthenticationChallenge)
                #expect(credential == nil)
            }
        }
        KubernetesAPIClient.handleServerTrust(validTrust, host: "wrong.example.test", caCertificate: cert) { disposition, credential in
            callbacks += 1
            #expect(disposition == .cancelAuthenticationChallenge)
            #expect(credential == nil)
        }
        #expect(callbacks == 4)
    }
}

@Suite("Localized legal documents")
struct LegalDocumentTests {
    @Test("System languages and regional variants resolve to shipped translations")
    func preferredLanguages() {
        for language in ["en", "de", "es", "fr", "it", "nl", "pl", "pt"] {
            #expect(LegalDocument.preferredLanguage(for: [language]) == language)
        }
        #expect(LegalDocument.preferredLanguage(for: ["de-CH"]) == "de")
        #expect(LegalDocument.preferredLanguage(for: ["fr-CA"]) == "fr")
        #expect(LegalDocument.preferredLanguage(for: ["pt-BR"]) == "pt")
        #expect(LegalDocument.preferredLanguage(for: ["ja", "nl-NL"]) == "nl")
        #expect(LegalDocument.preferredLanguage(for: ["ja"]) == "en")
        #expect(LegalDocument.preferredLanguage(for: []) == "en")
    }

    @Test("Missing, empty and unreadable translations fall back to English")
    func englishFallback() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegalDocuments-\(UUID().uuidString).bundle")
        defer { try? FileManager.default.removeItem(at: directory) }
        for language in ["en", "de"] {
            try FileManager.default.createDirectory(
                at: directory.appendingPathComponent("\(language).lproj"),
                withIntermediateDirectories: true
            )
        }
        let info: [String: Any] = [
            "CFBundleIdentifier": "test.legal.documents",
            "CFBundlePackageType": "BNDL",
            "CFBundleDevelopmentRegion": "en"
        ]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: directory.appendingPathComponent("Info.plist"))
        let bundle = try #require(Bundle(url: directory))
        let english = directory.appendingPathComponent("en.lproj/PrivacyPolicy.md")
        let german = directory.appendingPathComponent("de.lproj/PrivacyPolicy.md")
        try "<!-- doc-id: PRIVACY_POLICY | lang: en -->\nEnglish privacy policy"
            .write(to: english, atomically: true, encoding: .utf8)
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["de"]) == "English privacy policy")
        try "Deutsche Datenschutzerklärung".write(to: german, atomically: true, encoding: .utf8)
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["de-CH"]) == "Deutsche Datenschutzerklärung")
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["ja"]) == "English privacy policy")
        try " \n".write(to: german, atomically: true, encoding: .utf8)
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["de"]) == "English privacy policy")
        try "<!-- metadata only -->".write(to: german, atomically: true, encoding: .utf8)
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["de"]) == "English privacy policy")
        try Data([0xFF]).write(to: german)
        #expect(LegalDocument.privacy.load(bundle: bundle, preferredLanguages: ["de"]) == "English privacy policy")
    }
}

@Suite("Free trial access")
@MainActor
struct FreeTrialTests {
    @Test("Full access lasts seven days, survives restart, and respects purchases")
    func trialLifecycle() throws {
        let suite = "FreeTrialTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let store = StoreManager(defaults: defaults, now: start)
        #expect(store.isFullAccessUnlocked)
        #expect(store.isTrialActive)

        let restarted = StoreManager(defaults: defaults, now: start.addingTimeInterval(86400))
        #expect(restarted.trialEndsAt == store.trialEndsAt)
        #expect(restarted.isFullAccessUnlocked)
        restarted.refreshTrialStatus(now: store.trialEndsAt.addingTimeInterval(-1))
        #expect(restarted.isFullAccessUnlocked)
        restarted.refreshTrialStatus(now: store.trialEndsAt)
        #expect(!restarted.isFullAccessUnlocked)

        let expired = StoreManager(defaults: defaults, now: store.trialEndsAt.addingTimeInterval(86400))
        #expect(!expired.isTrialActive)
        #expect(!expired.isFullAccessUnlocked)
        expired.purchasedProductIDs.insert(AppProduct.fullAccess.rawValue)
        #expect(expired.isFullAccessUnlocked)
        expired.purchasedProductIDs.removeAll()
        #expect(!expired.isFullAccessUnlocked)
    }
}

@Suite("API Response Decoding Tests")
struct APIDecodingTests {

    // MARK: - CivoQuota (int fields from real API)

    @Test("Decode quota response")
    func decodeQuota() throws {
        let json = """
        {"cpu_core_limit":74,"cpu_core_usage":28,"database_count_limit":4,"database_count_usage":3,"database_cpu_core_limit":16,"database_cpu_core_usage":4,"database_disk_gb_limit":400,"database_disk_gb_usage":80,"database_ram_mb_limit":32768,"database_ram_mb_usage":8192,"database_snapshot_count_limit":20,"database_snapshot_count_usage":0,"disk_gb_limit":1600,"disk_gb_usage":700,"disk_snapshot_count_limit":48,"disk_snapshot_count_usage":0,"disk_volume_count_limit":128,"disk_volume_count_usage":11,"instance_count_limit":64,"instance_count_usage":9,"loadbalancer_count_limit":16,"loadbalancer_count_usage":1,"network_count_limit":10,"network_count_usage":1,"objectstore_gb_limit":5000,"objectstore_gb_usage":3000,"public_ip_address_limit":64,"public_ip_address_usage":5,"ram_mb_limit":262144,"ram_mb_usage":57344,"security_group_limit":16,"security_group_rule_limit":160,"security_group_rule_usage":0,"security_group_usage":0,"subnet_count_limit":10,"subnet_count_usage":0}
        """
        let data = json.data(using: .utf8)!
        let quota = try JSONDecoder().decode(CivoQuota.self, from: data)
        #expect(quota.instanceCountLimit == 64)
        #expect(quota.instanceCountUsage == 9)
        #expect(quota.cpuCoreLimit == 74)
        #expect(quota.databaseCountUsage == 3)
        #expect(quota.items.count == 13)
    }

    // MARK: - CivoKubernetesCluster (paginated)

    @Test("Decode kubernetes cluster response (paginated)")
    func decodeKubernetesList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"4874e5e5","name":"k8s-cluster","version":"1.35.0-k3s1","status":"ACTIVE","ready":true,"cluster_type":"k3s","num_target_nodes":1,"target_nodes_size":"g4s.kube.medium","kubernetes_version":"1.35.0-k3s1","api_endpoint":"https://74.220.31.124:6443","master_ip":"74.220.31.124","dns_entry":"4874e5e5.k8s.civo.com","cni_plugin":"flannel","created_at":"2025-06-19T11:37:18Z"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoKubernetesCluster>.self, from: data)
        #expect(response.items.count == 1)
        let cluster = response.items[0]
        #expect(cluster.name == "k8s-cluster")
        #expect(cluster.status == "ACTIVE")
        #expect(cluster.cniPlugin == "flannel")
    }

    // MARK: - CivoDatabase (paginated)

    @Test("Decode database list response (paginated)")
    func decodeDatabaseList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"67763af0","name":"dev-database","status":"Ready","software":"PostgreSQL","software_version":"14","size":"g3.db.xsmall","nodes":1,"port":5432,"public_ipv4":"74.220.25.6","private_ipv4":"192.168.1.8","firewall_id":"62f22b50","network_id":"7fa62450","dns_entry":"67763af0.db.civo.com"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoDatabase>.self, from: data)
        #expect(response.items.count == 1)
        let db = response.items[0]
        #expect(db.name == "dev-database")
        #expect(db.software == "PostgreSQL")
        #expect(db.port == 5432)
        #expect(db.nodes == 1)
        #expect(db.publicIpv4 == "74.220.25.6")
    }

    // MARK: - CivoFirewall (plain array, rules_count as string or int)

    @Test("Decode firewall list (rules_count as string)")
    func decodeFirewallString() throws {
        let json = """
        [{"id":"2a18a3ee","name":"k8s-firewall","rules_count":"7"}]
        """
        let data = json.data(using: .utf8)!
        let fws = try JSONDecoder().decode([CivoFirewall].self, from: data)
        #expect(fws[0].rulesCountInt == 7)
    }

    @Test("Decode firewall list (rules_count as int)")
    func decodeFirewallInt() throws {
        let json = """
        [{"id":"2a18a3ee","name":"k8s-firewall","rules_count":7}]
        """
        let data = json.data(using: .utf8)!
        let fws = try JSONDecoder().decode([CivoFirewall].self, from: data)
        #expect(fws[0].rulesCountInt == 7)
    }

    // MARK: - CivoRule

    @Test("Decode firewall rules")
    func decodeRuleList() throws {
        let json = """
        [{"id":"rule1","label":"civo-cloud-test","cidr":"1.2.3.4/32","ports":"6443","start_port":"6443","end_port":"6443","direction":"ingress","action":"allow"}]
        """
        let data = json.data(using: .utf8)!
        let rules = try JSONDecoder().decode([CivoRule].self, from: data)
        #expect(rules[0].cidr == "1.2.3.4/32")
    }

    @Test("CivoRule decodes cidr as string")
    func cidrString() throws {
        let json = """
        {"id":"r1","cidr":"10.0.0.0/8"}
        """
        let data = json.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CivoRule.self, from: data)
        #expect(rule.cidr == "10.0.0.0/8")
    }

    @Test("CivoRule decodes cidr as array")
    func cidrArray() throws {
        let json = """
        {"id":"r2","cidr":["10.0.0.0/8","172.16.0.0/12"]}
        """
        let data = json.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CivoRule.self, from: data)
        #expect(rule.cidr == "10.0.0.0/8")
    }

    // MARK: - CivoNetwork (plain array, default is Bool)

    @Test("Decode network list (default as bool)")
    func decodeNetworkList() throws {
        let json = """
        [{"id":"7fa62450","label":"default","name":"cust-net","region":"fra1","status":"Active","default":true}]
        """
        let data = json.data(using: .utf8)!
        let networks = try JSONDecoder().decode([CivoNetwork].self, from: data)
        #expect(networks[0].displayName == "default")
        #expect(networks[0].isDefault == true)
    }

    // MARK: - CivoVolume (plain array, size_gb is Int)

    @Test("Decode volume list (size_gb as int)")
    func decodeVolumeList() throws {
        let json = """
        [{"id":"c0da7fd0","name":"pvc-test","status":"available","size_gb":20,"mountpoint":"","instance_id":"","cluster_id":"clust1","network_id":"net1"}]
        """
        let data = json.data(using: .utf8)!
        let volumes = try JSONDecoder().decode([CivoVolume].self, from: data)
        #expect(volumes[0].sizeGb == 20)
        #expect(volumes[0].sizeDisplay == "20 GB")
    }

    // MARK: - CivoObjectStore (paginated, max_size is Int)

    @Test("Decode object store list (max_size as int)")
    func decodeObjectStoreList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"656648","name":"database-backups","max_size":500,"objectstore_endpoint":"objectstore.fra1.civo.com","status":"ready"}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoObjectStore>.self, from: data)
        #expect(response.items[0].maxSize == 500)
        #expect(response.items[0].maxSizeDisplay == "500 GB")
    }

    // MARK: - CivoLoadBalancer (plain array, Backends capital B)

    @Test("Decode load balancer list (Backends capital B)")
    func decodeLoadBalancerList() throws {
        let json = """
        [{"id":"0cf0cbc6","name":"k8s-ingress","algorithm":"round_robin","public_ip":"74.220.28.127","private_ip":"192.168.1.10","state":"available","Backends":"192.168.1.9, 192.168.1.23"}]
        """
        let data = json.data(using: .utf8)!
        let lbs = try JSONDecoder().decode([CivoLoadBalancer].self, from: data)
        #expect(lbs[0].backendList.count == 2)
    }

    // MARK: - CivoRegion (plain array, default is Bool)

    @Test("Decode region list (default as bool)")
    func decodeRegionList() throws {
        let json = """
        [{"code":"fra1","name":"fra1","country":"de","country_name":"Germany","default":false},{"code":"lon1","name":"lon1","country":"gb","country_name":"United Kingdom","default":false}]
        """
        let data = json.data(using: .utf8)!
        let regions = try JSONDecoder().decode([CivoRegion].self, from: data)
        #expect(regions.count == 2)
        #expect(regions[0].code == "fra1")
        #expect(regions[0].countryDisplay == "Germany")
    }

    // MARK: - CivoInstance (paginated)

    @Test("Decode instance list (paginated)")
    func decodeInstanceList() throws {
        let json = """
        {"page":1,"per_page":20,"pages":1,"items":[{"id":"b75f2659","hostname":"test-server","size":"g4s.kube.large","status":"ACTIVE","public_ip":"74.220.31.124","cpu_cores":4,"ram_mb":8192,"disk_gb":60,"firewall_id":"2a18a3ee","created_at":"2026-03-05T10:25:10Z","tags":["k3s"]}]}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<CivoInstance>.self, from: data)
        #expect(response.items[0].name == "test-server")
        #expect(response.items[0].cpuCores == 4)
    }

    // MARK: - CivoSSHKey (plain array)

    @Test("Decode SSH key list")
    func decodeSSHKeyList() throws {
        let json = """
        [{"id":"ssh1","name":"my-key","fingerprint":"SHA256:abc123"}]
        """
        let data = json.data(using: .utf8)!
        let keys = try JSONDecoder().decode([CivoSSHKey].self, from: data)
        #expect(keys[0].name == "my-key")
    }

    // MARK: - CivoDomain (plain array)

    @Test("Decode domain list")
    func decodeDomainList() throws {
        let json = """
        [{"id":"dom1","name":"example.com"}]
        """
        let data = json.data(using: .utf8)!
        let domains = try JSONDecoder().decode([CivoDomain].self, from: data)
        #expect(domains[0].name == "example.com")
    }

    // MARK: - CivoResult (DELETE response)

    @Test("Decode delete result")
    func decodeDeleteResult() throws {
        let json = """
        {"result":"success"}
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(CivoResult.self, from: data)
        #expect(result.result == "success")
    }

    // MARK: - K8s sub-types

    @Test("Decode kubernetes conditions")
    func decodeK8sConditions() throws {
        let json = """
        [{"type":"ControlPlaneReady","status":"True","last_transition_time":"2025-08-31T16:20:33Z"}]
        """
        let data = json.data(using: .utf8)!
        let conditions = try JSONDecoder().decode([CivoK8sCondition].self, from: data)
        #expect(conditions[0].isHealthy == true)
    }

    @Test("Decode node pools")
    func decodeNodePools() throws {
        let json = """
        [{"id":"dev-pool","count":1,"size":"g4s.kube.medium","instance_names":["node1"]}]
        """
        let data = json.data(using: .utf8)!
        let pools = try JSONDecoder().decode([CivoNodePool].self, from: data)
        #expect(pools[0].count == 1)
    }

    // MARK: - QuotaItem

    @Test("QuotaItem percentage calculation")
    func quotaItemPercentage() {
        let item = QuotaItem(id: "test", label: "Test", usage: 7, limit: 10, icon: "cpu")
        #expect(item.percentage == 0.7)

        let zeroLimit = QuotaItem(id: "zero", label: "Zero", usage: 0, limit: 0, icon: "cpu")
        #expect(zeroLimit.percentage == 0)
    }

    // MARK: - CivoAccessLabel

    @Test("Access label generation")
    func accessLabelGeneration() {
        let label = CivoAccessLabel.make(firewallName: "test-fw")
        #expect(label.hasPrefix("civo-cloud-"))
        #expect(label.hasSuffix("-test-fw"))
    }
}
