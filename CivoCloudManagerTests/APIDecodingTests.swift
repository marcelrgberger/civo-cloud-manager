import AppKit
import Foundation
import Testing
import Security
import CryptoKit
import LocalAuthentication
import os

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
        for language in ["en", "de", "es", "fr", "it", "nl", "pl", "pt", "zh-Hans", "ja", "ko", "ar", "hi", "id", "tr", "ru"] {
            #expect(LegalDocument.preferredLanguage(for: [language]) == language)
        }
        #expect(LegalDocument.preferredLanguage(for: ["de-CH"]) == "de")
        #expect(LegalDocument.preferredLanguage(for: ["fr-CA"]) == "fr")
        #expect(LegalDocument.preferredLanguage(for: ["pt-BR"]) == "pt")
        for (regional, expected) in [("zh-CN", "zh-Hans"), ("zh-SG", "zh-Hans"), ("zh-Hans-CN", "zh-Hans"), ("ja-JP", "ja"), ("ko-KR", "ko"), ("ar-SA", "ar"), ("hi-IN", "hi"), ("id-ID", "id"), ("tr-TR", "tr"), ("ru-RU", "ru")] {
            #expect(LegalDocument.preferredLanguage(for: [regional]) == expected)
        }
        #expect(LegalDocument.preferredLanguage(for: ["sv", "nl-NL"]) == "nl")
        #expect(LegalDocument.preferredLanguage(for: ["sv"]) == "en")
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

// MARK: - Instance console

private let consoleInstanceId = "11111111-2222-3333-4444-555555555555"
private let consoleTarget = ConsoleTarget(instanceId: consoleInstanceId, instanceName: "web-1", region: "LON1")
private let consoleURI = "https://vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html?path=/\(consoleInstanceId)/websockify"

@Suite("Console URLs and sensitive requests")
struct ConsoleURLTests {
    @Test("Token is appended to the API uri, keeping its path parameter and encoding reserved characters")
    func tokenAppended() throws {
        let url = try ConsoleURL.make(uri: consoleURI, token: "a+b/c=d&e", target: consoleTarget)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "vnc.lon1.civo.com")
        #expect(components.queryItems?.first { $0.name == "path" }?.value == "/\(consoleInstanceId)/websockify")
        #expect(components.queryItems?.first { $0.name == "token" }?.value == "a+b/c=d&e")
        #expect(components.percentEncodedQuery?.contains("a%2Bb") == true)
    }

    @Test("noVNC is asked to scale to the window, replacing a resize mode from the API uri")
    func scalesToWindow() throws {
        let uri = "https://vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html?path=/\(consoleInstanceId)/websockify&resize=off"
        let url = try ConsoleURL.make(uri: uri, token: "jwt", target: consoleTarget)
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.map(\.name) == ["path", "resize", "token"])
        #expect(items.first { $0.name == "resize" }?.value == "scale")
        #expect(ConsoleURL.isAllowedNavigation(url, sessionURL: url, target: consoleTarget))
    }

    @Test("Untrusted console locations are rejected", arguments: [
        "http://vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html",
        "https://vnc.nyc1.civo.com/\(consoleInstanceId)/vnc.html",
        "https://vnc.lon1.civo.com.evil.example/\(consoleInstanceId)/vnc.html",
        "https://user:pass@vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html",
        "https://vnc.lon1.civo.com:8443/\(consoleInstanceId)/vnc.html",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html?token=foreign",
        "https://vnc.lon1.civo.com/other-instance/vnc.html",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)/../other/vnc.html",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)/..",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)/./vnc.html",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)/%2e%2e/other",
        "https://vnc.lon1.civo.com/\(consoleInstanceId)%2F..%2Fother/vnc.html",
    ])
    func untrustedRejected(uri: String) {
        #expect(throws: ConsoleURL.InvalidURL.self) {
            try ConsoleURL.make(uri: uri, token: "jwt", target: consoleTarget)
        }
    }

    @Test("Navigation guard keeps the page on the console origin and blocks foreign tokens")
    func navigationGuard() throws {
        let session = try ConsoleURL.make(uri: consoleURI, token: "jwt", target: consoleTarget)
        let allowed = [session, URL(string: "https://vnc.lon1.civo.com/\(consoleInstanceId)/vnc_lite.html")!]
        let blocked = [
            "https://example.com/\(consoleInstanceId)/vnc.html",
            "https://vnc.lon1.civo.com/\(consoleInstanceId)/vnc.html?token=other",
            "https://vnc.lon1.civo.com:444/\(consoleInstanceId)/vnc.html",
            "https://dashboard.civo.com/instances/\(consoleInstanceId)/console",
        ].map { URL(string: $0)! }
        for url in allowed { #expect(ConsoleURL.isAllowedNavigation(url, sessionURL: session, target: consoleTarget)) }
        for url in blocked { #expect(!ConsoleURL.isAllowedNavigation(url, sessionURL: session, target: consoleTarget)) }
    }

    @Test("Console requests pin region, one-hour duration and the exchange body")
    func requests() throws {
        func query(_ request: URLRequest) -> [String: String] {
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        }
        let start = try CivoConsoleService.startRequest(consoleTarget, apiKey: "k")
        #expect(start.httpMethod == "PUT")
        #expect(start.url?.path == "/v2/instances/\(consoleInstanceId)/vnc")
        #expect(query(start) == ["region": "LON1", "duration": "1h"])
        #expect(start.value(forHTTPHeaderField: "Authorization") == "bearer k")

        let end = try CivoConsoleService.endRequest(consoleTarget, apiKey: "k")
        #expect(end.httpMethod == "DELETE")
        #expect(query(end) == ["region": "LON1"])

        let exchange = try CivoConsoleService.exchangeRequest(region: "LON1", apiKey: "k")
        #expect(exchange.httpMethod == "POST")
        #expect(exchange.url?.path == "/v2/auth/exchange")
        #expect(exchange.httpBody == Data(#"{"scope":""}"#.utf8))

        let injected = ConsoleTarget(instanceId: "../../account", instanceName: "x", region: "LON1")
        #expect(throws: ConsoleError.self) { try CivoConsoleService.startRequest(injected, apiKey: "k") }
    }

    @Test("Errors and token responses never reveal the console URL or JWT")
    func sanitization() throws {
        let secret = "SECRET-JWT-VALUE"
        let failing = URL(string: "https://vnc.lon1.civo.com/x/vnc.html?token=\(secret)")!
        let urlError = URLError(.cannotConnectToHost, userInfo: [NSURLErrorFailingURLErrorKey: failing,
                                                                 NSURLErrorFailingURLStringErrorKey: failing.absoluteString])
        let sanitized = ConsoleError.sanitize(urlError)
        #expect(sanitized == .network(URLError.Code.cannotConnectToHost.rawValue))
        for text in [String(describing: sanitized), sanitized.logDescription, sanitized.userMessage ?? ""] {
            #expect(!text.contains(secret))
        }
        #expect(ConsoleError.sanitize(URLError(.cancelled)) == .cancelled)
        #expect(ConsoleError.http(404) == .notFound)
        #expect(ConsoleError.http(503) == .server(503))

        let json = #"{"access_token":"\#(secret)","token_type":"Bearer","refresh_token":"<refresh>","expires_in":3600,"id_token":"<id>","account_id":"<account>"}"#
        let token = try JSONDecoder().decode(AuthTokenExchangeResponse.self, from: Data(json.utf8))
        #expect(token.accessToken == secret)
        #expect(token.expiresIn == 3600)
        #expect(!String(describing: token).contains(secret))
        #expect(!String(reflecting: token).contains(secret))
    }

    @Test("Decode console session response")
    func decodeSession() throws {
        let json = #"{"uri":"https://vnc.lon1.civo.com/<instance-id>/vnc.html?path=/<instance-id>/websockify","duration":"1h"}"#
        let session = try JSONDecoder().decode(ConsoleSessionResponse.self, from: Data(json.utf8))
        #expect(session.uri.hasPrefix("https://vnc.lon1.civo.com/"))
        #expect(session.duration == "1h")
    }
}

/// Records events from the main actor and the fake API in one synchronous order.
private final class EventOrder: Sendable {
    private let events = OSAllocatedUnfairLock(initialState: [String]())
    func append(_ event: String) { events.withLock { $0.append(event) } }
    var all: [String] { events.withLock { $0 } }
}

private actor FakeConsoleAPI: ConsoleAPI {
    let order = EventOrder()
    private(set) var startCalls = 0
    private(set) var endCalls = 0
    private(set) var exchangeCalls = 0
    private(set) var probeCalls = 0
    private var probeResults: [ConsoleProbeResult]
    private var endResult: Result<ConsoleEndResult, ConsoleError> = .success(.ended)
    private var holdStart = false
    private var holdEnd = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var endWaiters: [CheckedContinuation<Void, Never>] = []

    init(probeResults: [ConsoleProbeResult] = []) {
        self.probeResults = probeResults
    }

    func configure(holdStart: Bool = false, holdEnd: Bool = false, endResult: Result<ConsoleEndResult, ConsoleError> = .success(.ended)) {
        self.holdStart = holdStart
        self.holdEnd = holdEnd
        self.endResult = endResult
    }

    func releaseStarts() {
        holdStart = false
        startWaiters.forEach { $0.resume() }
        startWaiters = []
    }

    func releaseEnds() {
        holdEnd = false
        endWaiters.forEach { $0.resume() }
        endWaiters = []
    }

    func startSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleSessionResponse {
        startCalls += 1
        if holdStart { await withCheckedContinuation { startWaiters.append($0) } }
        return ConsoleSessionResponse(uri: consoleURI, duration: "1h")
    }

    func endSession(_ target: ConsoleTarget, apiKey: String) async throws -> ConsoleEndResult {
        endCalls += 1
        order.append("delete")
        if holdEnd { await withCheckedContinuation { endWaiters.append($0) } }
        return try endResult.get()
    }

    func exchangeToken(region: String, apiKey: String) async throws -> String {
        exchangeCalls += 1
        return "jwt-\(exchangeCalls)"
    }

    func probe(_ url: URL, target: ConsoleTarget) async throws -> ConsoleProbeResult {
        probeCalls += 1
        return probeResults.isEmpty ? .ready : probeResults.removeFirst()
    }
}

private actor SleepRecorder {
    private(set) var sleeps: [Duration] = []
    func record(_ duration: Duration) { sleeps.append(duration) }
}

@MainActor
private final class ConsoleEnvironment {
    var apiKey = "key-a"
    var accessAllowed = true
    var activities: [String] = []
    let api: FakeConsoleAPI
    let sleeps = SleepRecorder()
    private(set) var vm: ConsoleViewModel!

    init(probeResults: [ConsoleProbeResult] = []) {
        api = FakeConsoleAPI(probeResults: probeResults)
        let sleeps = sleeps
        vm = ConsoleViewModel(
            target: consoleTarget,
            api: api,
            timing: .init(sleep: { duration in await sleeps.record(duration) }),
            apiKeyProvider: { [weak self] in self?.apiKey ?? "" },
            isAccessAllowed: { [weak self] in self?.accessAllowed ?? false },
            recordActivity: { [weak self] in self?.activities.append($0) }
        )
    }

    func connectAndSettle() async {
        vm.connect()
        await waitUntil { !self.vm.isBusy }
    }
}

@Suite("Console initial login")
@MainActor
struct ConsoleLoginTests {
    private let password = "INITIAL-PASSWORD-VALUE"

    @Test("The login never appears in descriptions, and the window value carries no secret")
    func redacted() throws {
        let login = ConsoleLogin(user: "civo", password: password)
        var dumped = ""
        dump(login, to: &dumped)
        for text in [String(describing: login), String(reflecting: login), dumped, "\(login)"] {
            #expect(!text.contains(password))
        }
        let encodedTarget = try String(decoding: JSONEncoder().encode(consoleTarget), as: UTF8.self)
        #expect(!encodedTarget.lowercased().contains("password"))
        #expect(ConsoleLogin(user: "", password: "").isEmpty)
    }

    @Test("The login is handed to the console window in memory and dropped when it closes")
    func handOver() {
        let store = ConsoleLoginStore()
        store.register(ConsoleLogin(user: "civo", password: password), for: consoleTarget)
        let renamed = ConsoleTarget(instanceId: consoleInstanceId, instanceName: "renamed", region: "LON1")
        #expect(store.login(for: renamed)?.password == password)
        store.remove(for: consoleTarget)
        #expect(store.login(for: consoleTarget) == nil)
    }

    @Test("A copied password is concealed and cleared only if nothing else was copied")
    func pasteboard() {
        let board = NSPasteboard(name: NSPasteboard.Name("ccm-test-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }

        let copied = SecretPasteboard.write(password, to: board)
        #expect(board.string(forType: .string) == password)
        #expect(board.types?.contains(SecretPasteboard.concealedType) == true)
        SecretPasteboard.clear(board, ifUnchangedSince: copied)
        #expect(board.string(forType: .string) == nil)

        let again = SecretPasteboard.write(password, to: board)
        board.clearContents()
        board.setString("other", forType: .string)
        SecretPasteboard.clear(board, ifUnchangedSince: again)
        #expect(board.string(forType: .string) == "other")
    }

    @Test("A reveal or copy still waiting for authentication does nothing once invalidated")
    func invalidatedWhileAuthenticating() async {
        var pendingAuthentications: [CheckedContinuation<DeviceOwnerAuthentication, Never>] = []
        var copied: [String] = []
        let access = PasswordAccess(
            authenticate: { _, _ in await withCheckedContinuation { pendingAuthentications.append($0) } },
            writeToPasteboard: { copied.append($0) }
        )

        let reveal = Task { await access.reveal() }
        let copy = Task { await access.copy(password) }
        await waitUntil { pendingAuthentications.count == 2 }
        // Window closed, API key changed or Full Access ended during authentication.
        access.invalidate()
        pendingAuthentications.forEach { $0.resume(returning: .granted) }
        await reveal.value
        #expect(await copy.value == false)
        #expect(!access.isRevealed)
        #expect(copied.isEmpty)

        // A fresh request after invalidation works again.
        let next = Task { await access.copy(password) }
        await waitUntil { pendingAuthentications.count == 3 }
        pendingAuthentications[2].resume(returning: .granted)
        #expect(await next.value)
        #expect(copied == [password])
    }

    @Test("Without Touch ID or a system password the password is neither revealed nor copied")
    func failsClosedWithoutDeviceAuthentication() async {
        var copied: [String] = []
        let access = PasswordAccess(
            authenticate: { _, _ in .unavailable },
            writeToPasteboard: { copied.append($0) }
        )

        await access.reveal()
        #expect(await access.copy(password) == false)
        #expect(!access.isRevealed)
        #expect(copied.isEmpty)
        #expect(access.isDeviceAuthenticationUnavailable)
    }

    @Test("App deactivation, screen lock and sleep hide the password and discard pending authentication")
    func lockEventsInvalidate() async {
        let center = NotificationCenter()
        for name in PasswordAccess.systemLockEvents.map(\.name) {
            var pendingAuthentication: CheckedContinuation<DeviceOwnerAuthentication, Never>?
            var copied: [String] = []
            let access = PasswordAccess(
                authenticate: { _, _ in await withCheckedContinuation { pendingAuthentication = $0 } },
                writeToPasteboard: { copied.append($0) },
                lockEvents: [PasswordAccess.LockEvent(center: center, name: name)]
            )
            access.observeLockEvents()

            let reveal = Task { await access.reveal() }
            await waitUntil { pendingAuthentication != nil }
            pendingAuthentication?.resume(returning: .granted)
            await reveal.value
            #expect(access.isRevealed)

            center.post(name: name, object: nil)
            #expect(!access.isRevealed, "\(name.rawValue)")

            pendingAuthentication = nil
            let copy = Task { await access.copy(password) }
            await waitUntil { pendingAuthentication != nil }
            center.post(name: name, object: nil)
            pendingAuthentication?.resume(returning: .granted)
            #expect(await copy.value == false, "\(name.rawValue)")
            #expect(copied.isEmpty)

            access.stopObservingLockEvents()
        }
    }
}

@MainActor
private func waitUntil(_ condition: @MainActor () async -> Bool) async {
    for _ in 0..<10_000 {
        if await condition() { return }
        await Task.yield()
    }
    Issue.record("Condition not met")
}

@Suite("Console session lifecycle")
@MainActor
struct ConsoleLifecycleTests {
    @Test("Closing the window disconnects locally and never ends the server session")
    func closeIsLocal() async throws {
        let env = ConsoleEnvironment()
        await env.connectAndSettle()
        #expect(env.vm.phase == .loading)
        let url = try #require(env.vm.consoleURL)
        #expect(url.absoluteString.contains("token=jwt-1"))

        env.vm.closeLocally()
        #expect(env.vm.consoleURL == nil)
        #expect(env.vm.phase == .disconnected)
        #expect(await env.api.endCalls == 0)
        #expect(env.activities == ["Opened console"])
    }

    @Test("End session runs the web view teardown before DELETE is sent")
    func endDetachesFirst() async throws {
        let env = ConsoleEnvironment()
        await env.connectAndSettle()
        let connection = try #require(env.vm.connection)
        env.vm.webViewDidAttach(connectionID: connection.id) { env.api.order.append("teardown") }
        await env.api.configure(holdEnd: true)

        let ending = Task { await env.vm.endSession() }
        await waitUntil { await env.api.endCalls == 1 }
        #expect(env.api.order.all == ["teardown", "delete"])
        #expect(env.vm.consoleURL == nil)
        #expect(env.vm.phase == .ending)
        await env.vm.endSession()
        #expect(await env.api.endCalls == 1)

        await env.api.releaseEnds()
        await ending.value
        #expect(env.vm.phase == .ended(.ended))
        #expect(env.activities.last == "Ended console session")
    }

    @Test("DELETE 404 counts as stopped; a failed DELETE is reported honestly")
    func endOutcomes() async {
        let notFound = ConsoleEnvironment()
        await notFound.connectAndSettle()
        await notFound.api.configure(endResult: .success(.alreadyStopped))
        await notFound.vm.endSession()
        #expect(notFound.vm.phase == .ended(.alreadyStopped))

        let failing = ConsoleEnvironment()
        await failing.connectAndSettle()
        await failing.api.configure(endResult: .failure(.server(502)))
        await failing.vm.endSession()
        #expect(failing.vm.phase == .endFailed(.server(502)))
        #expect(failing.vm.consoleURL == nil)
        #expect(!failing.activities.contains { $0.contains("Ended") })
    }

    @Test("A session that arrives after the window closed is ignored, not used or deleted")
    func lateStartAfterClose() async {
        let env = ConsoleEnvironment()
        await env.api.configure(holdStart: true)
        env.vm.connect()
        await waitUntil { await env.api.startCalls == 1 }
        env.vm.closeLocally()
        await env.api.releaseStarts()
        for _ in 0..<100 { await Task.yield() }

        #expect(env.vm.phase == .disconnected)
        #expect(env.vm.consoleURL == nil)
        #expect(await env.api.exchangeCalls == 0)
        #expect(await env.api.endCalls == 0)
    }

    @Test("Overlapping reconnects keep only the latest attempt")
    func overlappingReconnect() async {
        let env = ConsoleEnvironment()
        await env.api.configure(holdStart: true)
        env.vm.connect()
        await waitUntil { await env.api.startCalls == 1 }
        env.vm.connect()
        await waitUntil { await env.api.startCalls == 2 }
        await env.api.releaseStarts()
        await waitUntil { env.vm.phase == .loading }

        #expect(await env.api.exchangeCalls == 1)
        #expect(env.activities == ["Opened console"])
    }

    @Test("Callbacks from a superseded web view cannot detach the current console")
    func staleWebViewCallbacks() async throws {
        let env = ConsoleEnvironment()
        await env.connectAndSettle()
        let old = try #require(env.vm.connection)
        await env.connectAndSettle()
        var staleTornDown = false
        env.vm.webViewDidAttach(connectionID: old.id) { staleTornDown = true }
        env.vm.pageDidFail(connectionID: old.id)
        env.vm.pageDidLoad(connectionID: old.id)

        #expect(staleTornDown)
        #expect(env.vm.consoleURL != nil)
        #expect(env.vm.phase == .loading)
    }

    @Test("Reconnect starts or checks the session again instead of only refreshing the JWT")
    func reconnectRestartsSession() async {
        let env = ConsoleEnvironment()
        await env.connectAndSettle()
        await env.connectAndSettle()
        #expect(await env.api.startCalls == 2)
        #expect(await env.api.exchangeCalls == 2)
        #expect(env.vm.consoleURL?.absoluteString.contains("token=jwt-2") == true)
    }

    @Test("Readiness wait is bounded and uses the injected clock")
    func boundedReadiness() async {
        let env = ConsoleEnvironment(probeResults: Array(repeating: .notReady, count: 10))
        await env.connectAndSettle()
        #expect(env.vm.phase == .failed(.notReady))
        #expect(env.vm.consoleURL == nil)
        #expect(await env.api.probeCalls == 5)
        #expect(await env.sleeps.sleeps == Array(repeating: .seconds(7), count: 4))
    }

    @Test("A rejected JWT is renewed at most once")
    func boundedTokenRenewal() async {
        let renewed = ConsoleEnvironment(probeResults: [.tokenRejected, .ready])
        await renewed.connectAndSettle()
        #expect(renewed.vm.phase == .loading)
        #expect(await renewed.api.exchangeCalls == 2)

        let rejected = ConsoleEnvironment(probeResults: Array(repeating: .tokenRejected, count: 10))
        await rejected.connectAndSettle()
        #expect(rejected.vm.phase == .failed(.notReady))
        #expect(await rejected.api.exchangeCalls == 2)
        #expect(await rejected.api.probeCalls == 5)
    }

    @Test("A changed API key stops the window from acting on another account")
    func accountChange() async {
        let env = ConsoleEnvironment()
        await env.connectAndSettle()
        env.apiKey = "key-b"
        env.vm.apiKeyDidChange()
        #expect(env.vm.consoleURL == nil)
        #expect(env.vm.phase == .failed(.accountChanged))

        await env.vm.endSession()
        #expect(env.vm.phase == .failed(.accountChanged))
        #expect(await env.api.endCalls == 0)

        await env.connectAndSettle()
        #expect(env.vm.phase == .failed(.accountChanged))
        #expect(await env.api.startCalls == 1)
    }

    @Test("Without Full Access the console neither starts nor stays attached")
    func accessGate() async {
        let env = ConsoleEnvironment()
        env.accessAllowed = false
        await env.connectAndSettle()
        #expect(env.vm.phase == .failed(.accessRevoked))
        #expect(await env.api.startCalls == 0)

        env.accessAllowed = true
        await env.connectAndSettle()
        #expect(env.vm.consoleURL != nil)
        env.accessAllowed = false
        env.vm.revokeAccess()
        #expect(env.vm.consoleURL == nil)
        #expect(env.vm.phase == .failed(.accessRevoked))
        await env.vm.endSession()
        #expect(await env.api.endCalls == 0)
    }
}

@Suite("Cost estimate charges")
struct ChargesServiceTests {
    private static func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }
    private static let now = date("2026-11-19T14:57:00Z")

    private static func charge(id: Int, hours: Double) -> CivoCharge {
        CivoCharge(id: id, code: "instance-g3.small", label: "web-\(id)", from: "2026-01-01T00:00:00Z", to: nil,
                   numHours: hours, sizeGb: nil, nodes: nil, region: "LON1", size: nil, unit: nil,
                   productId: nil, previousChargeId: nil, parentProductId: nil)
    }

    final class MemoryStore: ChargesCacheStore, @unchecked Sendable {
        let entries = OSAllocatedUnfairLock(initialState: [String: [CivoCharge]]())
        func load(scope: String, month: String) -> [CivoCharge]? { entries.withLock { $0["\(scope)/\(month)"] } }
        func save(_ charges: [CivoCharge], scope: String, month: String) { entries.withLock { $0["\(scope)/\(month)"] = charges } }
    }

    private static func service(store: MemoryStore, apiKey: String, requests: OSAllocatedUnfairLock<[ChargeWindow]>) -> CivoChargesService {
        CivoChargesService(
            fetch: { window, _ in
                requests.withLock { $0.append(window) }
                return [charge(id: 1, hours: window.to.timeIntervalSince(window.from) / 3600)]
            },
            store: store,
            account: { ChargeAccount(apiKey: apiKey) },
            now: { now }
        )
    }

    private static let scopeA = CivoChargesService.scope(forAPIKey: "key-a")!
    private static let scopeB = CivoChargesService.scope(forAPIKey: "key-b")!

    /// Serialized `from`/`to` of every request for `period`.
    private static func serializedWindows(_ period: ChargePeriod, now: Date) -> [(from: String, to: String)] {
        let range = period.dateRange(now: now)
        return ChargeWindowPlanner.monthlyWindows(from: range.from, to: range.to).map { window in
            let items = CivoChargesService.queryItems(for: window)
            #expect(items.map(\.name) == ["from", "to"])
            return (items[0].value!, items[1].value!)
        }
    }

    @Test("Last Month sends the inclusive last second of the month as to", arguments: [
        ("2026-11-19T14:57:00Z", "2026-10-01T00:00:00Z", "2026-10-31T23:59:59Z", 31),
        ("2028-03-10T08:00:00Z", "2028-02-01T00:00:00Z", "2028-02-29T23:59:59Z", 29),
        ("2027-03-10T08:00:00Z", "2027-02-01T00:00:00Z", "2027-02-28T23:59:59Z", 28),
        ("2027-01-05T08:00:00Z", "2026-12-01T00:00:00Z", "2026-12-31T23:59:59Z", 31),
    ])
    func lastMonthQuery(now: String, from: String, to: String, days: Int) {
        let windows = Self.serializedWindows(.lastMonth, now: Self.date(now))
        #expect(windows.count == 1)
        #expect(windows.first?.from == from)
        #expect(windows.first?.to == to)
        // Inclusive span: from the first to the last included second.
        let span = Self.date(to).timeIntervalSince(Self.date(from)) + 1
        #expect(span == TimeInterval(days * 24 * 60 * 60))
        #expect(span <= ChargeWindowPlanner.maxSpan)
    }

    @Test("Requests across the year transition neither overlap nor leave gaps")
    func yearTransitionQueries() {
        let now = Self.date("2027-01-05T08:00:00Z")
        let quarter = Self.serializedWindows(.lastQuarter, now: now)
        #expect(quarter.map(\.from) == ["2026-10-01T00:00:00Z", "2026-11-01T00:00:00Z", "2026-12-01T00:00:00Z", "2027-01-01T00:00:00Z"])
        #expect(quarter.map(\.to) == ["2026-10-31T23:59:59Z", "2026-11-30T23:59:59Z", "2026-12-31T23:59:59Z", "2027-01-05T07:59:59Z"])
        #expect(zip(quarter, quarter.dropFirst()).allSatisfy { Self.date($1.from).timeIntervalSince(Self.date($0.to)) == 1 })

        let year = Self.serializedWindows(.thisYear, now: now)
        #expect(year.count == 1)
        #expect(year.first?.from == "2027-01-01T00:00:00Z")
        #expect(year.first?.to == "2027-01-05T07:59:59Z")
    }

    @Test("This Year splits into contiguous windows of at most 31 days")
    func thisYearWindows() {
        let range = ChargePeriod.thisYear.dateRange(now: Self.now)
        let windows = ChargeWindowPlanner.monthlyWindows(from: range.from, to: range.to)
        #expect(windows.count == 11)
        #expect(windows.first?.from == Self.date("2026-01-01T00:00:00Z"))
        #expect(windows.last?.to == Self.now)
        #expect(windows.allSatisfy { $0.to.timeIntervalSince($0.from) <= ChargeWindowPlanner.maxSpan })
        #expect(zip(windows, windows.dropFirst()).allSatisfy { $0.to == $1.from })
    }

    @Test("Completed months are reused from the cache, the open month is fetched again, results are summed")
    func cacheReuse() async throws {
        let store = MemoryStore()
        let requests = OSAllocatedUnfairLock(initialState: [ChargeWindow]())
        let service = Self.service(store: store, apiKey: "key-a", requests: requests)

        let first = try await service.charges(for: .lastQuarter)
        #expect(requests.withLock { $0.count } == 4)
        let expectedHours = Self.now.timeIntervalSince(Self.date("2026-08-01T00:00:00Z")) / 3600
        #expect(first.reduce(0) { $0 + $1.numHours } == expectedHours)

        requests.withLock { $0.removeAll() }
        let second = try await service.charges(for: .lastQuarter)
        #expect(requests.withLock { $0 } == [ChargeWindow(from: Self.date("2026-11-01T00:00:00Z"), to: Self.now)])
        #expect(second.reduce(0) { $0 + $1.numHours } == expectedHours)
        #expect(store.entries.withLock { $0.keys.sorted() } == ["2026-08", "2026-09", "2026-10"].map { "\(Self.scopeA)/\($0)" })
    }

    @Test("Another API key does not see cached charges; without a key nothing is cached")
    func cacheScope() async throws {
        let store = MemoryStore()
        let requests = OSAllocatedUnfairLock(initialState: [ChargeWindow]())
        _ = try await Self.service(store: store, apiKey: "key-a", requests: requests).charges(for: .lastMonth)
        _ = try await Self.service(store: store, apiKey: "key-b", requests: requests).charges(for: .lastMonth)
        _ = try await Self.service(store: store, apiKey: "", requests: requests).charges(for: .lastMonth)
        #expect(requests.withLock { $0.count } == 3)
        #expect(CivoChargesService.scope(forAPIKey: "") == nil)
        #expect(CivoChargesService.scope(forAPIKey: "key-a") != CivoChargesService.scope(forAPIKey: "key-b"))
        #expect(CivoChargesService.scope(forAPIKey: "key-a")?.contains("key-a") == false)
        #expect(String(describing: ChargeAccount(apiKey: "key-a")).contains("key-a") == false)
    }

    /// Holds the first fetch until the test releases it.
    actor FetchGate {
        private var isSuspended = false
        private var arrival: CheckedContinuation<Void, Never>?
        private var release: CheckedContinuation<Void, Never>?

        func suspend() async {
            isSuspended = true
            arrival?.resume()
            arrival = nil
            await withCheckedContinuation { release = $0 }
        }

        func untilSuspended() async {
            guard !isSuspended else { return }
            await withCheckedContinuation { arrival = $0 }
        }

        func open() {
            release?.resume()
            release = nil
        }
    }

    @Test("An account switch during a load neither mixes caches nor shows the old account's charges")
    @MainActor
    func accountSwitchDuringLoad() async {
        let store = MemoryStore()
        let gate = FetchGate()
        let currentKey = OSAllocatedUnfairLock(initialState: "key-a")
        let usedKeys = OSAllocatedUnfairLock(initialState: [String]())
        let service = CivoChargesService(
            fetch: { window, account in
                let isFirst = usedKeys.withLock { $0.append(account.apiKey); return $0.count == 1 }
                if isFirst { await gate.suspend() }
                return [Self.charge(id: 1, hours: window.to.timeIntervalSince(window.from) / 3600)]
            },
            store: store,
            account: { ChargeAccount(apiKey: currentKey.withLock { $0 }) },
            now: { Self.now }
        )
        let model = CostChargesViewModel(service: service)

        let loadA = Task { await model.load(.lastQuarter) }
        await gate.untilSuspended()
        currentKey.withLock { $0 = "key-b" }
        model.apiKeyDidChange()
        await gate.open()
        await loadA.value

        // Every request of the load used account A's key and was filed under A only.
        #expect(usedKeys.withLock { $0 } == Array(repeating: "key-a", count: 4))
        #expect(store.entries.withLock { $0.keys.sorted() } == ["2026-08", "2026-09", "2026-10"].map { "\(Self.scopeA)/\($0)" })
        // A's late result was rejected.
        #expect(model.charges.isEmpty)
        #expect(model.error == nil)
        #expect(model.isLoading == false)

        await model.load(.lastQuarter)
        #expect(usedKeys.withLock { Array($0.dropFirst(4)) } == Array(repeating: "key-b", count: 4))
        #expect(store.entries.withLock { $0.keys.filter { $0.hasPrefix(Self.scopeB) }.count } == 3)
        #expect(model.charges.count == 4)
    }

    @Test("Error messages never contain the Civo response body")
    func sanitizedErrors() {
        let body = #"{"code":"parameter_date_range_too_long","reason":"The date range spanned more than 31 days"}"#
        let message = ChargesLoadError.userMessage(CivoAPIError.httpError(400, body))
        #expect(message?.isEmpty == false)
        #expect(message?.contains("parameter_date_range_too_long") == false)
        #expect(ChargesLoadError.userMessage(CivoAPIError.networkError(body))?.contains("{") == false)
        #expect(ChargesLoadError.userMessage(CivoAPIError.cancelled) == nil)
        #expect(ChargesLoadError.userMessage(CancellationError()) == nil)
    }
}

/// In-memory keychain: tests never read or write the user's keychain.
@MainActor
private final class FakeKeychain {
    var items: [String: Data] = [:]
    /// Returned instead of the normal result, e.g. a locked keychain or a missing entitlement.
    var failure: OSStatus?
    var queries: [[String: Any]] = []

    var client: KeychainClient {
        KeychainClient(
            add: { [unowned self] query in
                queries.append(query)
                if let failure { return failure }
                let account = query[kSecAttrAccount as String] as! String
                guard items[account] == nil else { return errSecDuplicateItem }
                items[account] = query[kSecValueData as String] as? Data
                return errSecSuccess
            },
            update: { [unowned self] query, attributes in
                queries.append(query)
                if let failure { return failure }
                let account = query[kSecAttrAccount as String] as! String
                guard items[account] != nil else { return errSecItemNotFound }
                items[account] = attributes[kSecValueData as String] as? Data
                return errSecSuccess
            },
            copyMatching: { [unowned self] query in
                queries.append(query)
                if let failure { return (failure, nil) }
                guard let data = items[query[kSecAttrAccount as String] as! String] else { return (errSecItemNotFound, nil) }
                // Measured on a signed build: a protected entry looked up with a context that may not
                // prompt reports errSecInteractionNotAllowed, even without asking for its data.
                if (query[kSecUseAuthenticationContext as String] as? LAContext)?.interactionNotAllowed == true {
                    return (errSecInteractionNotAllowed, nil)
                }
                return (errSecSuccess, query[kSecReturnData as String] as? Bool == true ? data : nil)
            },
            delete: { [unowned self] query in
                queries.append(query)
                if let failure { return failure }
                return items.removeValue(forKey: query[kSecAttrAccount as String] as! String) == nil ? errSecItemNotFound : errSecSuccess
            }
        )
    }
}

@Suite("Instance credential vault")
@MainActor
struct InstanceCredentialVaultTests {
    private let credential = InstanceCredential(username: "admin", password: "VAULT-PASSWORD-VALUE")
    private let key = InstanceCredentialKey(consoleTarget)

    @Test("Entries follow instance ID and region, not the name")
    func keys() {
        let renamed = ConsoleTarget(instanceId: consoleInstanceId, instanceName: "renamed", region: "lon1")
        let otherRegion = ConsoleTarget(instanceId: consoleInstanceId, instanceName: "web-1", region: "NYC1")
        #expect(InstanceCredentialKey(renamed) == key)
        #expect(InstanceCredentialKey(otherRegion) != key)
    }

    @Test("Create, overwrite and delete; an empty password is never saved")
    func lifecycle() throws {
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        let context = LAContext()

        #expect(try store.contains(key) == false)
        #expect(throws: InstanceCredentialError.emptyPassword) {
            try store.create(InstanceCredential(username: "admin", password: ""), for: key)
        }
        #expect(keychain.items.isEmpty)

        try store.create(InstanceCredential(username: "", password: "only-password"), for: key)
        #expect(try store.contains(key))
        #expect(throws: InstanceCredentialError.keychain(errSecDuplicateItem)) { try store.create(credential, for: key) }

        try store.replace(credential, for: key, context: context)
        #expect(try store.read(key, context: context) == credential)

        try store.delete(key)
        #expect(try store.read(key, context: context) == nil)
        try store.delete(key)

        // Replacing an entry deleted meanwhile saves it again.
        try store.replace(credential, for: key, context: context)
        #expect(try store.read(key, context: context) == credential)
    }

    @Test("Only a missing item means no entry; other keychain errors are reported", arguments: [
        errSecInteractionNotAllowed, errSecMissingEntitlement, errSecAuthFailed, errSecUserCanceled,
    ])
    func keychainErrors(status: OSStatus) throws {
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        try store.create(credential, for: key)
        keychain.failure = status
        let reported = InstanceCredentialError.keychain(status)

        if status == errSecInteractionNotAllowed {
            // The answer for an existing protected entry; a locked keychain cannot be told apart.
            #expect(try store.contains(key))
        } else {
            #expect(throws: reported) { try store.contains(key) }
        }
        #expect(throws: reported) { try store.read(key, context: LAContext()) }
        #expect(throws: reported) { try store.replace(credential, for: key, context: LAContext()) }
        #expect(throws: reported) { try store.delete(key) }
        keychain.failure = nil
        #expect(try store.read(key, context: LAContext()) == credential)
    }

    @Test("Entries are device-only, never synchronized, and protected by Touch ID or the system password")
    func queryAttributes() throws {
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        try store.create(credential, for: key)
        _ = try store.contains(key)

        let add = try #require(keychain.queries.first)
        #expect(add[kSecAttrSynchronizable as String] as? Bool == false)
        #expect(add[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #expect(add[kSecAttrAccessible as String] == nil)
        let accessControl = try #require(add[kSecAttrAccessControl as String] as CFTypeRef?)
        #expect(CFGetTypeID(accessControl) == SecAccessControlGetTypeID())
        #expect(InstanceCredentialStore.protection == kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
        #expect(InstanceCredentialStore.accessControlFlags.contains(.userPresence))

        // User name and password only inside the protected data, never in attributes or descriptions.
        for (name, value) in add where name != kSecValueData as String {
            #expect(!"\(value)".contains(credential.username) && !"\(value)".contains(credential.password))
        }
        var dumped = ""
        dump(credential, to: &dumped)
        for text in [String(describing: credential), String(reflecting: credential), dumped] {
            #expect(!text.contains(credential.password) && !text.contains(credential.username))
        }

        // The existence check reads no data and cannot prompt.
        let check = try #require(keychain.queries.last)
        #expect(check[kSecReturnData as String] == nil)
        let context = try #require(check[kSecUseAuthenticationContext as String] as? LAContext)
        #expect(context.interactionNotAllowed)
    }

    @Test("Saved credentials go only after Civo confirmed the instance deletion")
    func instanceDeletion() async throws {
        let instance = try JSONDecoder().decode(
            CivoInstance.self,
            from: Data(#"{"id": "\#(consoleInstanceId)", "hostname": "web-1", "region": "LON1"}"#.utf8)
        )
        struct DeletionFailed: Error {}
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        try store.create(credential, for: key)

        let failing = InstanceViewModel(credentials: store, deleteInstance: { _ in throw DeletionFailed() })
        #expect(await failing.delete(instance) == false)
        #expect(try store.contains(key))

        var deleted: [String] = []
        let succeeding = InstanceViewModel(credentials: store, deleteInstance: { deleted.append($0) })
        #expect(await succeeding.delete(instance))
        #expect(deleted == [consoleInstanceId])
        #expect(try store.contains(key) == false)
        #expect(succeeding.error == nil)
    }

    @Test("An edit holding the stored values ends after its time and needs a new authentication")
    func editingExpires() async throws {
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        try store.create(credential, for: key)
        var prompts = 0
        let access = PasswordAccess(authenticate: { _, _ in prompts += 1; return .granted }, writeToPasteboard: { _ in })
        let vault = InstanceCredentialVault(target: consoleTarget, store: store, access: access, editingDuration: .milliseconds(100))

        #expect(await vault.beginEditing() == credential)
        #expect(vault.isEditing)
        let relocks = vault.relocks
        let deadline = ContinuousClock.now + .seconds(5)
        while vault.isEditing && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!vault.isEditing)
        #expect(vault.relocks > relocks)

        #expect(await vault.beginEditing() == credential)
        #expect(prompts == 2)
        vault.cancelEditing()
    }

    @Test("Every invalidation is counted, also without an entry or an open edit")
    func relocksWithoutEntry() {
        let keychain = FakeKeychain()
        let store = InstanceCredentialStore(keychain: keychain.client, notificationCenter: NotificationCenter())
        let vault = InstanceCredentialVault(target: consoleTarget, store: store, access: PasswordAccess(lockEvents: []))
        vault.refresh()
        #expect(vault.entry == .absent)
        let relocks = vault.relocks
        vault.invalidate()
        #expect(vault.relocks == relocks + 1)
    }
}

@Suite("Concealed text field")
@MainActor
struct ConcealedTextFieldTests {
    private let secret = "VAULT-PASSWORD-VALUE"

    private func editor() -> (ConcealedFieldEditor, copied: () -> [String]) {
        var copied: [String] = []
        let editor = ConcealedFieldEditor()
        editor.copySecret = { copied.append($0) }
        editor.string = secret
        editor.selectAll(nil)
        return (editor, { copied })
    }

    @Test("Copy and cut go only through the secret copy path, never the general pasteboard")
    func copyAndCut() {
        let changeCount = NSPasteboard.general.changeCount
        let (copying, copied) = editor()
        copying.copy(nil)
        #expect(copied() == [secret])
        #expect(copying.string == secret)

        let (cutting, cut) = editor()
        cutting.setSelectedRange(NSRange(location: 0, length: 5))
        cutting.cut(nil)
        #expect(cut() == ["VAULT"])
        #expect(cutting.string == "-PASSWORD-VALUE")
        let other = NSTextView(frame: .zero)
        other.yank(nil)
        #expect(!other.string.contains("VAULT"))
        #expect(NSPasteboard.general.changeCount == changeCount)
    }

    @Test("Deleting to the end or start of the line leaves nothing in the kill buffer")
    func noKillBuffer() {
        let deletions: [(ConcealedFieldEditor) -> Void] = [
            { $0.setSelectedRange(NSRange(location: 0, length: 0)); $0.deleteToEndOfLine(nil) },
            { $0.setSelectedRange(NSRange(location: 0, length: 0)); $0.deleteToEndOfParagraph(nil) },
            { $0.moveToEndOfDocument(nil); $0.deleteToBeginningOfLine(nil) },
            { $0.moveToEndOfDocument(nil); $0.deleteToBeginningOfParagraph(nil) },
            { $0.setSelectedRange(NSRange(location: 0, length: 0)); $0.setMark(nil); $0.moveToEndOfDocument(nil); $0.deleteToMark(nil) },
        ]
        for delete in deletions {
            let (editor, copied) = editor()
            delete(editor)
            #expect(editor.string.isEmpty)
            #expect(copied().isEmpty)
            let other = NSTextView(frame: .zero)
            other.yank(nil)
            #expect(!other.string.contains(secret))
        }
    }

    @Test("Dragging and Services receive nothing")
    func noOtherExport() {
        let (editor, _) = editor()
        let board = NSPasteboard(name: NSPasteboard.Name("ConcealedTextFieldTests-\(UUID().uuidString)"))
        defer { board.releaseGlobally() }
        #expect(!editor.writeSelection(to: board, types: [.string]))
        #expect(!editor.writeSelection(to: board, type: .string))
        #expect(board.string(forType: .string) == nil)
        #expect(editor.validRequestor(forSendType: .string, returnType: nil) == nil)
    }

    @Test("The field edits with the concealed field editor, not the window's shared one")
    func usesConcealedEditor() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 40), styleMask: [.titled], backing: .buffered, defer: true)
        let field = ConcealedNSTextField(string: secret)
        window.contentView?.addSubview(field)
        #expect(window.fieldEditor(true, for: field) is ConcealedFieldEditor)
    }
}

@Suite("Complete pagination")
struct PaginationTests {
    struct Item: Decodable, Identifiable, Sendable, Equatable {
        let id: String
    }

    /// Serves canned pages and records the query of every request.
    actor PageStub {
        private(set) var queries: [[URLQueryItem]] = []
        private let respond: @Sendable (Int) throws -> PaginatedResponse<Item>

        init(respond: @escaping @Sendable (Int) throws -> PaginatedResponse<Item>) {
            self.respond = respond
        }

        func fetch(_ query: [URLQueryItem]) throws -> PaginatedResponse<Item> {
            queries.append(query)
            let page = Int(query.first { $0.name == "page" }?.value ?? "") ?? 0
            return try respond(page)
        }

        var requestedPages: [String?] { queries.map { $0.first { $0.name == "page" }?.value } }
    }

    static func items(_ ids: String...) -> [Item] { ids.map(Item.init) }

    @Test("Pages 1 to 3 are merged in order and paging stops at the reported page count")
    func mergesAllPages() async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: Self.items("\(page)a", "\(page)b"), page: page, perPage: nil, pages: 3)
        }
        let list = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        #expect(list.isComplete)
        #expect(list.items.map(\.id) == ["1a", "1b", "2a", "2b", "3a", "3b"])
        #expect(await stub.requestedPages == ["1", "2", "3"])
    }

    @Test("Region and filters are sent unchanged with every page; caller page values are replaced")
    func preservesFilters() async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: Self.items("\(page)"), page: page, perPage: nil, pages: 2)
        }
        let filters = [
            URLQueryItem(name: "tags", value: "web prod"),
            URLQueryItem(name: "page", value: "7"),
            URLQueryItem(name: "region", value: "LON1"),
        ]
        _ = try await CivoAPIClient.collectPages(filters: filters) { try await stub.fetch($0) }
        let expectedFilters = [URLQueryItem(name: "tags", value: "web prod"), URLQueryItem(name: "region", value: "LON1")]
        for (index, query) in await stub.queries.enumerated() {
            #expect(query == expectedFilters + [
                URLQueryItem(name: "page", value: String(index + 1)),
                URLQueryItem(name: "per_page", value: String(CivoAPIClient.pageSize)),
            ])
        }
    }

    @Test("A failing later page throws an incomplete-list error and returns nothing partial")
    func intermediateFailure() async throws {
        let stub = PageStub { page in
            if page == 2 { throw CivoAPIError.httpError(500, "") }
            return PaginatedResponse(items: Self.items("\(page)"), page: page, perPage: nil, pages: 3)
        }
        await #expect {
            _ = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        } throws: { error in
            guard case .incompleteList(let detail) = error as? CivoAPIError else { return false }
            return detail?.contains("HTTP 500") == true
        }
        #expect(await stub.requestedPages == ["1", "2"])
    }

    @Test("A failing first page keeps its own error")
    func firstPageFailure() async throws {
        let stub = PageStub { _ in throw CivoAPIError.httpError(401, "") }
        await #expect {
            _ = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        } throws: { error in
            guard case .httpError(401, _) = error as? CivoAPIError else { return false }
            return true
        }
    }

    @Test("A page that reports another page number stops paging as incomplete")
    func nonAdvancingPage() async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: Self.items("\(page)"), page: 1, perPage: nil, pages: 5)
        }
        let list = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        #expect(!list.isComplete)
        #expect(list.items.map(\.id) == ["1"])
        #expect(await stub.requestedPages == ["1", "2"])
    }

    @Test("A page repeating already seen items stops paging as incomplete")
    func repeatedPage() async throws {
        let stub = PageStub { _ in
            PaginatedResponse(items: Self.items("a", "b"), page: nil, perPage: nil, pages: nil)
        }
        let list = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        #expect(!list.isComplete)
        #expect(list.items.map(\.id) == ["a", "b"])
        #expect(await stub.requestedPages == ["1", "2"])
    }

    @Test("Without page metadata a full page is not the end; only an empty page completes the list")
    func missingPagesMetadata() async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: page == 1 ? Self.items("a") : [], page: nil, perPage: nil, pages: nil)
        }
        let list = try await CivoAPIClient.collectPages(filters: []) { try await stub.fetch($0) }
        #expect(list.isComplete)
        #expect(list.items.map(\.id) == ["a"])
        #expect(await stub.requestedPages == ["1", "2"])
    }

    @Test("Reaching the page cap returns the loaded items as incomplete", arguments: [Int?.none, 10])
    func pageCap(reportedPages: Int?) async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: Self.items("\(page)"), page: page, perPage: nil, pages: reportedPages)
        }
        let list = try await CivoAPIClient.collectPages(filters: [], maxPages: 3) { try await stub.fetch($0) }
        #expect(!list.isComplete)
        #expect(list.items.map(\.id) == ["1", "2", "3"])
        #expect(throws: CivoAPIError.self) { try list.completeItems() }
    }

    @Test("Cancellation during a page fetch ends with a cancelled error, also on the last page", arguments: [1, 3])
    func cancellation(reportedPages: Int) async throws {
        let stub = PageStub { page in
            PaginatedResponse(items: Self.items("\(page)"), page: page, perPage: nil, pages: reportedPages)
        }
        let task = Task {
            try await CivoAPIClient.collectPages(filters: []) { query in
                let response = try await stub.fetch(query)
                withUnsafeCurrentTask { $0?.cancel() }
                return response
            }
        }
        await #expect {
            _ = try await task.value
        } throws: { CivoAPIError.isCancelled($0) }
        #expect(await stub.requestedPages == ["1"])
    }
}
