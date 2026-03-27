import Foundation

struct PauseProgress: Sendable {
    let phase: Phase
    let currentFile: Int
    let totalFiles: Int
    let currentFileName: String
    let bytesCopied: Int64
    let bytesTotal: Int64
    var copyStartTime: Date?

    enum Phase: String, Sendable {
        case preparing = "Preparing"
        case copying = "Copying"
        case verifying = "Verifying"
        case deleting = "Deleting"
        case resizing = "Resizing Vault"
        case completed = "Completed"
    }

    var fraction: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(currentFile) / Double(totalFiles)
    }

    var estimatedTimeRemaining: String? {
        guard phase == .copying, bytesCopied > 0, bytesTotal > bytesCopied,
              let start = copyStartTime else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed > 2 else { return nil }
        let bytesPerSecond = Double(bytesCopied) / elapsed
        guard bytesPerSecond > 0 else { return nil }
        let remainingSeconds = Int(Double(bytesTotal - bytesCopied) / bytesPerSecond)
        if remainingSeconds < 60 { return "~\(remainingSeconds)s remaining" }
        let minutes = remainingSeconds / 60
        if minutes < 60 { return "~\(minutes)m \(remainingSeconds % 60)s remaining" }
        return "~\(minutes / 60)h \(minutes % 60)m remaining"
    }
}

final class ObjectStorePauseService: Sendable {
    static let vaultName = "civo-cloud-manager"
    static let vaultCredentialName = "civo-cloud-manager-vault"
    private static let manifestKey = "paused/manifest.json"
    private static let pausedPrefix = "paused/"
    private static let defaultVaultSize = 500
    private static let maxConcurrentTransfers = 4

    private let storeService = CivoObjectStoreService()

    // MARK: - Vault Setup

    func findVault() async throws -> CivoObjectStore? {
        let stores = try await storeService.listObjectStores()
        return stores.first { $0.name == Self.vaultName }
    }

    func findVaultCredential() async throws -> CivoObjectStoreCredential? {
        let creds = try await storeService.listCredentials()
        return creds.first { $0.name == Self.vaultCredentialName }
    }

    func setupVault() async throws -> (store: CivoObjectStore, credential: CivoObjectStoreCredential) {
        // Check if vault already exists — resolve credential via store's credential_id
        if let vault = try await findVault() {
            if let credId = vault.credentialId {
                let cred = try await storeService.showCredential(credId)
                return (vault, cred)
            }
            // Vault exists but no credential linked — fall through to create
        }

        // Create credential first
        var credential = try await findVaultCredential()
        if credential == nil {
            credential = try await storeService.createCredential(["name": Self.vaultCredentialName])
            Log.info("Created vault credential: \(credential!.displayName)")
        }

        // Create vault store with that credential
        var vault = try await findVault()
        if vault == nil {
            let body: [String: Any] = [
                "name": Self.vaultName,
                "size": Self.defaultVaultSize,
                "access_key_id": credential!.accessKeyId ?? ""
            ]
            vault = try await storeService.createObjectStore(body)
            Log.info("Created vault store: \(vault!.name)")

            // Wait for vault to become ready
            try await waitForStoreReady(vault!.id)
            vault = try await storeService.showObjectStore(vault!.id)
        }

        // Resolve the actual credential linked to the store
        if let credId = vault!.credentialId {
            credential = try await storeService.showCredential(credId)
        }

        return (vault!, credential!)
    }

    // MARK: - Pause

    func pauseStore(
        _ store: CivoObjectStore,
        credential: CivoObjectStoreCredential,
        progress: @Sendable @escaping (PauseProgress) -> Void
    ) async throws {
        // 1. Setup vault
        progress(PauseProgress(phase: .preparing, currentFile: 0, totalFiles: 0, currentFileName: "Setting up vault...", bytesCopied: 0, bytesTotal: 0))
        let (vault, vaultCred) = try await setupVault()

        // 2. Create S3 clients
        guard let sourceEndpoint = store.objectstoreEndpoint,
              let sourceAccessKey = credential.accessKeyId,
              let sourceSecretKey = credential.secretAccessKeyId else {
            throw PauseError.missingCredentials
        }

        guard let vaultEndpoint = vault.objectstoreEndpoint,
              let vaultAccessKey = vaultCred.accessKeyId,
              let vaultSecretKey = vaultCred.secretAccessKeyId else {
            throw PauseError.missingVaultCredentials
        }

        let region = CivoConfig.shared.region
        let sourceClient = S3Client(endpoint: sourceEndpoint, accessKey: sourceAccessKey, secretKey: sourceSecretKey, region: region)
        let vaultClient = S3Client(endpoint: vaultEndpoint, accessKey: vaultAccessKey, secretKey: vaultSecretKey, region: region)

        // 3. List all files in source store
        progress(PauseProgress(phase: .preparing, currentFile: 0, totalFiles: 0, currentFileName: "Listing files...", bytesCopied: 0, bytesTotal: 0))
        let allObjects = try await sourceClient.listAllObjects(bucket: store.name, prefix: "")
        let totalFiles = allObjects.count
        let totalBytes = Int64(allObjects.reduce(0) { $0 + $1.size })

        if totalFiles == 0 {
            // Empty store — save local fallback BEFORE delete for recovery
            let entry = PausedObjectStore(
                id: UUID().uuidString,
                originalName: store.name,
                originalMaxSize: store.maxSize ?? Self.defaultVaultSize,
                credentialId: credential.id,
                accessKeyId: credential.accessKeyId,
                region: CivoConfig.shared.region,
                endpoint: sourceEndpoint,
                pausedAt: Date(),
                fileCount: 0,
                totalSizeBytes: 0,
                vaultPrefix: "\(Self.pausedPrefix)\(store.name)/"
            )
            var localManifest = loadLocalManifest()
            localManifest.stores.append(entry)
            saveLocalManifest(localManifest)

            progress(PauseProgress(phase: .deleting, currentFile: 0, totalFiles: 0, currentFileName: store.name, bytesCopied: 0, bytesTotal: 0))
            try await storeService.removeObjectStore(store.id)
            try await savePausedMetadata(vaultClient: vaultClient, vaultBucket: vault.name, entry: entry)
            progress(PauseProgress(phase: .completed, currentFile: 0, totalFiles: 0, currentFileName: "", bytesCopied: 0, bytesTotal: 0))
            return
        }

        // 4. Ensure vault has enough space
        let requiredGB = Int(totalBytes / (1024 * 1024 * 1024)) + 1
        try await ensureVaultCapacity(vault: vault, additionalGB: requiredGB, vaultClient: vaultClient)

        // 5. Copy files to vault (parallel, max 4 concurrent)
        let vaultPrefix = "\(Self.pausedPrefix)\(store.name)/"
        let pauseCounter = TransferCounter()
        let pauseCopyStart = Date()
        try await withThrowingTaskGroup(of: Void.self) { group in
            var inflight = 0
            for object in allObjects {
                if inflight >= Self.maxConcurrentTransfers {
                    try await group.next()
                    inflight -= 1
                }
                group.addTask {
                    try Task.checkCancellation()
                    let destKey = "\(vaultPrefix)\(object.key)"
                    let data = try await sourceClient.downloadObject(bucket: store.name, key: object.key)
                    try await vaultClient.uploadObject(bucket: vault.name, key: destKey, data: data)
                    let (files, bytes) = await pauseCounter.add(bytes: Int64(data.count))
                    progress(PauseProgress(phase: .copying, currentFile: files, totalFiles: totalFiles, currentFileName: object.key, bytesCopied: bytes, bytesTotal: totalBytes, copyStartTime: pauseCopyStart))
                }
                inflight += 1
            }
            try await group.waitForAll()
        }
        let bytesCopied = await pauseCounter.totalBytes

        // 6. Verify — compare keys and sizes, not just count
        progress(PauseProgress(phase: .verifying, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "Verifying copy...", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        let vaultObjects = try await vaultClient.listAllObjects(bucket: vault.name, prefix: vaultPrefix)
        try verifyObjects(source: allObjects, copied: vaultObjects, prefix: vaultPrefix)

        // 7. Delete original store FIRST, then save metadata
        // This prevents "both active and paused" inconsistency
        progress(PauseProgress(phase: .deleting, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: store.name, bytesCopied: bytesCopied, bytesTotal: totalBytes))
        try await storeService.removeObjectStore(store.id)

        // 8. Save metadata after successful delete
        let entry = PausedObjectStore(
            id: UUID().uuidString,
            originalName: store.name,
            originalMaxSize: store.maxSize ?? Self.defaultVaultSize,
            credentialId: store.credentialId,
            accessKeyId: store.accessKeyId,
            region: CivoConfig.shared.region,
            endpoint: sourceEndpoint,
            pausedAt: Date(),
            fileCount: totalFiles,
            totalSizeBytes: totalBytes,
            vaultPrefix: vaultPrefix
        )
        try await savePausedMetadata(vaultClient: vaultClient, vaultBucket: vault.name, entry: entry)

        progress(PauseProgress(phase: .completed, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        Log.info("Paused object store '\(store.name)': \(totalFiles) files, \(entry.totalSizeDisplay)")
    }

    // MARK: - Resume

    func resumeStore(
        _ paused: PausedObjectStore,
        progress: @Sendable @escaping (PauseProgress) -> Void
    ) async throws {
        // 1. Get vault — resolve credential via store's credential_id
        progress(PauseProgress(phase: .preparing, currentFile: 0, totalFiles: 0, currentFileName: "Connecting to vault...", bytesCopied: 0, bytesTotal: 0))
        guard let vault = try await findVault(), let credId = vault.credentialId else {
            throw PauseError.vaultNotFound
        }
        let vaultCred = try await storeService.showCredential(credId)

        guard let vaultEndpoint = vault.objectstoreEndpoint,
              let vaultAccessKey = vaultCred.accessKeyId,
              let vaultSecretKey = vaultCred.secretAccessKeyId else {
            throw PauseError.missingVaultCredentials
        }

        let vaultClient = S3Client(endpoint: vaultEndpoint, accessKey: vaultAccessKey, secretKey: vaultSecretKey, region: CivoConfig.shared.region)

        // 2. Recreate original store (or use existing if already created from a prior attempt)
        progress(PauseProgress(phase: .preparing, currentFile: 0, totalFiles: 0, currentFileName: "Creating \(paused.originalName)...", bytesCopied: 0, bytesTotal: 0))
        let existingStores = try await storeService.listObjectStores()
        let readyStore: CivoObjectStore
        if let existing = existingStores.first(where: { $0.name == paused.originalName }) {
            let credentialMismatch = existing.credentialId != paused.credentialId && paused.credentialId != nil
            if credentialMismatch {
                // Store exists with wrong credential — auto-replace if empty, error if has data
                Log.warning("Store '\(paused.originalName)' exists with credential \(existing.credentialId ?? "nil"), expected \(paused.credentialId ?? "nil")")
                let existingCred = try? await storeService.showCredential(existing.credentialId ?? "")
                let existingEndpoint = existing.objectstoreEndpoint ?? ""
                if let ak = existingCred?.accessKeyId, let sk = existingCred?.secretAccessKeyId, !existingEndpoint.isEmpty {
                    let checkClient = S3Client(endpoint: existingEndpoint, accessKey: ak, secretKey: sk, region: CivoConfig.shared.region)
                    let existingObjects = try await checkClient.listAllObjects(bucket: existing.name, prefix: "")
                    if !existingObjects.isEmpty {
                        throw PauseError.storeExistsWithDifferentCredential(paused.originalName)
                    }
                }
                // Store is empty — safe to delete and recreate with correct credential
                try await storeService.removeObjectStore(existing.id)
                Log.info("Deleted empty store '\(paused.originalName)' with wrong credential, recreating")
                readyStore = try await createStoreWithCredential(paused)
            } else {
                readyStore = existing
                Log.info("Store '\(paused.originalName)' already exists, using existing")
            }
        } else {
            readyStore = try await createStoreWithCredential(paused)
        }

        // 3. Get the credential for the new store to build S3 client
        guard let destEndpoint = readyStore.objectstoreEndpoint else {
            throw PauseError.missingCredentials
        }

        // Find the credential used by the new store
        let destCredential: CivoObjectStoreCredential?
        if let credId = readyStore.credentialId {
            destCredential = try await storeService.showCredential(credId)
        } else {
            // Fallback: use the credential referenced in paused metadata
            if let credId = paused.credentialId {
                destCredential = try await storeService.showCredential(credId)
            } else {
                destCredential = nil
            }
        }

        guard let destAccessKey = destCredential?.accessKeyId,
              let destSecretKey = destCredential?.secretAccessKeyId else {
            throw PauseError.missingCredentials
        }

        let destClient = S3Client(endpoint: destEndpoint, accessKey: destAccessKey, secretKey: destSecretKey, region: CivoConfig.shared.region)

        // 4. List files in vault and validate against manifest
        let restoredFlag = "\(paused.vaultPrefix).restored"
        let allVaultObjects = try await vaultClient.listAllObjects(bucket: vault.name, prefix: paused.vaultPrefix)
        // Filter out operational markers (.restored flag) — only data files
        let vaultObjects = allVaultObjects.filter { $0.key != restoredFlag }
        let totalFiles = vaultObjects.count
        let totalBytes = Int64(vaultObjects.reduce(0) { $0 + $1.size })

        // Validate vault contents match manifest metadata
        if paused.fileCount > 0 && totalFiles == 0 {
            throw PauseError.vaultDataMissing(paused.originalName)
        }
        if paused.fileCount > 0 && totalFiles < paused.fileCount {
            throw PauseError.vaultDataIncomplete(paused.originalName, expected: paused.fileCount, actual: totalFiles)
        }

        // 5. Copy files back (parallel, max 4 concurrent)
        let resumeCounter = TransferCounter()
        let resumeCopyStart = Date()
        try await withThrowingTaskGroup(of: Void.self) { group in
            var inflight = 0
            for object in vaultObjects {
                let originalKey = String(object.key.dropFirst(paused.vaultPrefix.count))
                guard !originalKey.isEmpty else { continue }

                if inflight >= Self.maxConcurrentTransfers {
                    try await group.next()
                    inflight -= 1
                }
                group.addTask {
                    try Task.checkCancellation()
                    let data = try await vaultClient.downloadObject(bucket: vault.name, key: object.key)
                    try await destClient.uploadObject(bucket: paused.originalName, key: originalKey, data: data)
                    let (files, bytes) = await resumeCounter.add(bytes: Int64(data.count))
                    progress(PauseProgress(phase: .copying, currentFile: files, totalFiles: totalFiles, currentFileName: originalKey, bytesCopied: bytes, bytesTotal: totalBytes, copyStartTime: resumeCopyStart))
                }
                inflight += 1
            }
            try await group.waitForAll()
        }
        let bytesCopied = await resumeCounter.totalBytes

        // 6. Verify — compare keys and sizes
        progress(PauseProgress(phase: .verifying, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "Verifying restore...", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        if totalFiles > 0 {
            let restoredObjects = try await destClient.listAllObjects(bucket: paused.originalName, prefix: "")
            try verifyObjects(source: vaultObjects, copied: restoredObjects, prefix: paused.vaultPrefix)
        }

        // 7. Mark as fully restored in vault (safety flag for auto-recovery)
        try await vaultClient.uploadObject(bucket: vault.name, key: restoredFlag, data: Data(), contentType: "text/plain")

        // 8. Delete vault data files (keep .restored flag as recovery marker)
        progress(PauseProgress(phase: .deleting, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "Cleaning up vault...", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        let keysToDelete = vaultObjects.map(\.key)
        if !keysToDelete.isEmpty {
            try await vaultClient.deleteObjects(bucket: vault.name, keys: keysToDelete)
        }

        // 9. Remove from manifest (safe: .restored flag still present for auto-recovery)
        try await removePausedMetadata(vaultClient: vaultClient, vaultBucket: vault.name, pausedId: paused.id)

        // 10. Delete .restored flag (manifest already updated, flag no longer needed)
        do {
            try await vaultClient.deleteObject(bucket: vault.name, key: restoredFlag)
        } catch {
            Log.warning("Could not delete .restored flag for '\(paused.originalName)': \(error.localizedDescription)")
        }

        // 11. Shrink vault if possible
        progress(PauseProgress(phase: .resizing, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "Optimizing vault size...", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        try await shrinkVaultIfPossible(vault: vault, vaultClient: vaultClient)

        progress(PauseProgress(phase: .completed, currentFile: totalFiles, totalFiles: totalFiles, currentFileName: "", bytesCopied: bytesCopied, bytesTotal: totalBytes))
        Log.info("Resumed object store '\(paused.originalName)': \(totalFiles) files restored")
    }

    private func createStoreWithCredential(_ paused: PausedObjectStore) async throws -> CivoObjectStore {
        var body: [String: Any] = [
            "name": paused.originalName,
            "size": paused.originalMaxSize
        ]
        // Resolve access key: use stored value, or look up from credentialId
        if let accessKeyId = paused.accessKeyId {
            body["access_key_id"] = accessKeyId
        } else if let credId = paused.credentialId {
            let cred = try await storeService.showCredential(credId)
            if let ak = cred.accessKeyId {
                body["access_key_id"] = ak
            }
        }
        let newStore = try await storeService.createObjectStore(body)
        try await waitForStoreReady(newStore.id)
        return try await storeService.showObjectStore(newStore.id)
    }

    // MARK: - Manifest

    func loadManifest(vaultClient: S3Client, vaultBucket: String) async throws -> PausedStoreManifest {
        do {
            let data = try await vaultClient.downloadObject(bucket: vaultBucket, key: Self.manifestKey)
            return try JSONDecoder.pauseDecoder.decode(PausedStoreManifest.self, from: data)
        } catch let error as S3Error {
            // Only treat 404 (file not found) as empty manifest
            if case .httpError(let code, _) = error, code == 404 {
                return PausedStoreManifest(stores: [])
            }
            throw error
        }
    }

    func loadPausedStores() async throws -> [PausedObjectStore] {
        guard let vault = try await findVault() else {
            return loadLocalManifest().stores
        }
        // Resolve credential via store's credential_id
        guard let credId = vault.credentialId else {
            return loadLocalManifest().stores
        }
        let cred = try await storeService.showCredential(credId)
        guard let endpoint = vault.objectstoreEndpoint,
              let accessKey = cred.accessKeyId,
              let secretKey = cred.secretAccessKeyId else {
            return loadLocalManifest().stores
        }
        let client = S3Client(endpoint: endpoint, accessKey: accessKey, secretKey: secretKey, region: CivoConfig.shared.region)
        var manifest = try await loadManifest(vaultClient: client, vaultBucket: vault.name)

        // Clean up manifest entries for fully restored stores (check .restored flag)
        let activeStoreNames = Set((try? await storeService.listObjectStores())?.map(\.name) ?? [])
        var repaired = false
        var idsToRemove: Set<String> = []
        let candidateStores = manifest.stores.filter { activeStoreNames.contains($0.originalName) }
        for stale in candidateStores {
            let restoredFlag = "\(stale.vaultPrefix).restored"
            let isFullyRestored = (try? await client.headObject(bucket: vault.name, key: restoredFlag)) != nil

            if isFullyRestored {
                // .restored flag present — clean up vault folder and remove manifest entry
                var keysToClean: [String]
                do {
                    keysToClean = try await client.listAllObjects(bucket: vault.name, prefix: stale.vaultPrefix).map(\.key)
                } catch {
                    Log.warning("Vault listing failed for '\(stale.originalName)': \(error.localizedDescription)")
                    keysToClean = []
                }
                if !keysToClean.contains(restoredFlag) {
                    keysToClean.append(restoredFlag)
                }
                do {
                    try await client.deleteObjects(bucket: vault.name, keys: keysToClean)
                } catch {
                    Log.warning("Vault cleanup failed for '\(stale.originalName)': \(error.localizedDescription)")
                }
                idsToRemove.insert(stale.id)
                repaired = true
                Log.info("Cleaned up fully restored store: \(stale.originalName)")
            } else {
                // No .restored flag — only clean if vault folder is verifiably empty (not a listing error)
                do {
                    let vaultFiles = try await client.listAllObjects(bucket: vault.name, prefix: stale.vaultPrefix)
                    if vaultFiles.isEmpty {
                        idsToRemove.insert(stale.id)
                        repaired = true
                        Log.info("Cleaned up restored store (empty vault folder): \(stale.originalName)")
                    }
                } catch {
                    Log.warning("Could not verify vault contents for '\(stale.originalName)': \(error.localizedDescription)")
                }
            }
        }
        if !idsToRemove.isEmpty {
            manifest.stores.removeAll { idsToRemove.contains($0.id) }
        }

        // Repair: detect orphaned folders in vault not tracked in manifest
        let vaultContents = try await client.listObjects(bucket: vault.name, prefix: Self.pausedPrefix, delimiter: "/")
        let trackedPrefixes = Set(manifest.stores.map(\.vaultPrefix))
        for prefix in vaultContents.commonPrefixes {
            guard prefix != Self.pausedPrefix, !trackedPrefixes.contains(prefix) else { continue }
            // Orphaned folder — check if the original store still exists (cancelled pause)
            let storeName = String(prefix.dropFirst(Self.pausedPrefix.count).dropLast()) // remove trailing /
            if activeStoreNames.contains(storeName) {
                // Store still active — this is leftover from a cancelled pause, clean up
                let leftoverKeys = try await client.listAllObjects(bucket: vault.name, prefix: prefix)
                try await client.deleteObjects(bucket: vault.name, keys: leftoverKeys.map(\.key))
                repaired = true
                Log.warning("Cleaned up leftover vault data for active store: \(storeName)")
                continue
            }
            let objects = try await client.listAllObjects(bucket: vault.name, prefix: prefix)
            let totalBytes = Int64(objects.reduce(0) { $0 + $1.size })
            let entry = PausedObjectStore(
                id: UUID().uuidString,
                originalName: String(storeName),
                originalMaxSize: Self.defaultVaultSize,
                credentialId: nil,
                accessKeyId: nil,
                region: CivoConfig.shared.region,
                endpoint: endpoint,
                pausedAt: Date(),
                fileCount: objects.count,
                totalSizeBytes: totalBytes,
                vaultPrefix: prefix
            )
            manifest.stores.append(entry)
            repaired = true
            Log.warning("Recovered orphaned paused store: \(storeName) (\(objects.count) files)")
        }

        if repaired {
            let data = try JSONEncoder.pauseEncoder.encode(manifest)
            try await client.uploadObject(bucket: vault.name, key: Self.manifestKey, data: data, contentType: "application/json")
        }

        // Auto-shrink vault if oversized
        try? await shrinkVaultIfPossible(vault: vault, vaultClient: client)

        saveLocalManifest(manifest)
        return manifest.stores
    }

    private func savePausedMetadata(vaultClient: S3Client, vaultBucket: String, entry: PausedObjectStore) async throws {
        var manifest = try await loadManifest(vaultClient: vaultClient, vaultBucket: vaultBucket)
        manifest.stores.append(entry)
        let data = try JSONEncoder.pauseEncoder.encode(manifest)
        try await vaultClient.uploadObject(bucket: vaultBucket, key: Self.manifestKey, data: data, contentType: "application/json")
        saveLocalManifest(manifest)
    }

    private func removePausedMetadata(vaultClient: S3Client, vaultBucket: String, pausedId: String) async throws {
        var manifest = try await loadManifest(vaultClient: vaultClient, vaultBucket: vaultBucket)
        manifest.stores.removeAll { $0.id == pausedId }
        let data = try JSONEncoder.pauseEncoder.encode(manifest)
        try await vaultClient.uploadObject(bucket: vaultBucket, key: Self.manifestKey, data: data, contentType: "application/json")
        saveLocalManifest(manifest)
    }

    func discardPausedStore(_ paused: PausedObjectStore) async throws {
        guard let vault = try await findVault(), let vaultCredId = vault.credentialId else {
            throw PauseError.vaultNotFound
        }
        let cred = try await storeService.showCredential(vaultCredId)
        guard let endpoint = vault.objectstoreEndpoint,
              let ak = cred.accessKeyId, let sk = cred.secretAccessKeyId else {
            throw PauseError.missingVaultCredentials
        }
        let client = S3Client(endpoint: endpoint, accessKey: ak, secretKey: sk, region: CivoConfig.shared.region)

        // Delete any remaining vault data for this store
        let vaultFiles = try await client.listAllObjects(bucket: vault.name, prefix: paused.vaultPrefix)
        if !vaultFiles.isEmpty {
            try await client.deleteObjects(bucket: vault.name, keys: vaultFiles.map(\.key))
        }
        // Delete .restored flag if present
        let restoredFlag = "\(paused.vaultPrefix).restored"
        try? await client.deleteObject(bucket: vault.name, key: restoredFlag)

        // Remove from manifest
        try await removePausedMetadata(vaultClient: client, vaultBucket: vault.name, pausedId: paused.id)

        // Shrink vault if possible
        try? await shrinkVaultIfPossible(vault: vault, vaultClient: client)

        Log.info("Discarded paused store '\(paused.originalName)'")
    }

    func updatePausedStoreCredential(storeName: String, credentialId: String, accessKeyId: String?) async throws {
        guard let vault = try await findVault(), let vaultCredId = vault.credentialId else {
            throw PauseError.vaultNotFound
        }
        let cred = try await storeService.showCredential(vaultCredId)
        guard let endpoint = vault.objectstoreEndpoint,
              let ak = cred.accessKeyId, let sk = cred.secretAccessKeyId else {
            throw PauseError.missingVaultCredentials
        }
        let client = S3Client(endpoint: endpoint, accessKey: ak, secretKey: sk, region: CivoConfig.shared.region)
        var manifest = try await loadManifest(vaultClient: client, vaultBucket: vault.name)
        if let idx = manifest.stores.firstIndex(where: { $0.originalName == storeName }) {
            let old = manifest.stores[idx]
            manifest.stores[idx] = PausedObjectStore(
                id: old.id, originalName: old.originalName, originalMaxSize: old.originalMaxSize,
                credentialId: credentialId, accessKeyId: accessKeyId,
                region: old.region, endpoint: old.endpoint, pausedAt: old.pausedAt,
                fileCount: old.fileCount, totalSizeBytes: old.totalSizeBytes, vaultPrefix: old.vaultPrefix
            )
            let data = try JSONEncoder.pauseEncoder.encode(manifest)
            try await client.uploadObject(bucket: vault.name, key: Self.manifestKey, data: data, contentType: "application/json")
            saveLocalManifest(manifest)
            Log.info("Updated credential for paused store '\(storeName)' to \(credentialId)")
        }
    }

    // MARK: - Local Fallback

    private static let localManifestKey = "CivoCloudManager.pausedStores"

    private func loadLocalManifest() -> PausedStoreManifest {
        guard let data = UserDefaults.standard.data(forKey: Self.localManifestKey) else {
            return PausedStoreManifest(stores: [])
        }
        return (try? JSONDecoder.pauseDecoder.decode(PausedStoreManifest.self, from: data)) ?? PausedStoreManifest(stores: [])
    }

    private func saveLocalManifest(_ manifest: PausedStoreManifest) {
        if let data = try? JSONEncoder.pauseEncoder.encode(manifest) {
            UserDefaults.standard.set(data, forKey: Self.localManifestKey)
        }
    }

    // MARK: - Vault Capacity

    private func ensureVaultCapacity(vault: CivoObjectStore, additionalGB: Int, vaultClient: S3Client) async throws {
        let currentMax = vault.maxSize ?? Self.defaultVaultSize
        // Check actual usage in vault, not just max size
        let existing = try await vaultClient.listAllObjects(bucket: vault.name, prefix: Self.pausedPrefix)
        let usedGB = existing.reduce(0) { $0 + $1.size } / (1024 * 1024 * 1024)
        let neededGB = usedGB + additionalGB
        if neededGB >= currentMax {
            // Round up to nearest 500 GB (Civo requires multiples of 500)
            let newSize = ((neededGB + 500) / 500) * 500
            let _ = try await storeService.updateObjectStore(vault.id, body: ["max_size_gb": newSize])
            Log.info("Resized vault from \(currentMax) GB to \(newSize) GB")
        }
    }

    private func shrinkVaultIfPossible(vault: CivoObjectStore, vaultClient: S3Client) async throws {
        let remaining = try await vaultClient.listAllObjects(bucket: vault.name, prefix: Self.pausedPrefix)
        let usedBytes = remaining.reduce(0) { $0 + $1.size }
        let usedGB = usedBytes / (1024 * 1024 * 1024) + 1
        // Round up to nearest 500 GB (Civo requires multiples of 500)
        let newSize = max(Self.defaultVaultSize, ((usedGB + 499) / 500) * 500)
        let currentMax = vault.maxSize ?? Self.defaultVaultSize
        if newSize < currentMax {
            let _ = try await storeService.updateObjectStore(vault.id, body: ["max_size_gb": newSize])
            Log.info("Shrunk vault from \(currentMax) GB to \(newSize) GB")
        }
    }

    // MARK: - Helpers

    /// Verifies that copied objects match source objects by key and size.
    /// The `prefix` is stripped from source keys before comparison.
    private func verifyObjects(source: [S3Object], copied: [S3Object], prefix: String) throws {
        guard copied.count == source.count else {
            throw PauseError.verificationFailed(expected: source.count, actual: copied.count)
        }
        // Build lookup: strip prefix from source keys → size
        let sourceMap = Dictionary(uniqueKeysWithValues: source.map { obj -> (String, Int) in
            let key = obj.key.hasPrefix(prefix) ? String(obj.key.dropFirst(prefix.count)) : obj.key
            return (key, obj.size)
        })
        for obj in copied {
            let key = obj.key.hasPrefix(prefix) ? String(obj.key.dropFirst(prefix.count)) : obj.key
            guard let expectedSize = sourceMap[key] else {
                throw PauseError.verificationFailed(expected: source.count, actual: copied.count)
            }
            guard obj.size == expectedSize else {
                throw PauseError.verificationFailed(expected: source.count, actual: copied.count)
            }
        }
    }

    private func waitForStoreReady(_ id: String) async throws {
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(2))
            let store = try await storeService.showObjectStore(id)
            if store.status == "ready" { return }
        }
        throw PauseError.storeNotReady
    }
}

// MARK: - Errors

private actor TransferCounter {
    var fileCount = 0
    var totalBytes: Int64 = 0

    func add(bytes: Int64) -> (files: Int, bytes: Int64) {
        fileCount += 1
        totalBytes += bytes
        return (fileCount, totalBytes)
    }
}

enum PauseError: LocalizedError {
    case missingCredentials
    case missingVaultCredentials
    case vaultNotFound
    case verificationFailed(expected: Int, actual: Int)
    case storeNotReady
    case vaultDataMissing(String)
    case vaultDataIncomplete(String, expected: Int, actual: Int)
    case storeExistsWithDifferentCredential(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials: return "Missing object store credentials"
        case .missingVaultCredentials: return "Missing vault credentials"
        case .vaultNotFound: return "Vault store not found. Please set up the vault first."
        case .verificationFailed(let expected, let actual): return "Verification failed: expected \(expected) files, found \(actual)"
        case .storeNotReady: return "Object store did not become ready in time"
        case .vaultDataMissing(let name): return "No data found in vault for '\(name)'. The backup may be lost."
        case .vaultDataIncomplete(let name, let expected, let actual): return "Vault backup for '\(name)' is incomplete: \(actual)/\(expected) files. Resume aborted to protect data."
        case .storeExistsWithDifferentCredential(let name): return "Store '\(name)' already exists with different credentials. Delete it first or use the existing store."
        }
    }
}

// MARK: - JSON Coders

private extension JSONDecoder {
    static let pauseDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

private extension JSONEncoder {
    static let pauseEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}
