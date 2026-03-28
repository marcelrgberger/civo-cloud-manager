# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build                            # Debug build (SPM)
swift test                             # Run all 21 decoding tests
swift test --filter decodeQuota        # Run a single test by name
xcodegen generate && bash scripts/post_xcodegen.sh  # Regenerate .xcodeproj (always run both)
```

For Xcode builds: `open CivoCloudManager.xcodeproj`, scheme `CivoCloudManager`, Cmd+R. Tests use Swift Testing framework (`@Test`, `#expect`), not XCTest.

SPM build (`swift build`) embeds Info.plist via linker flags but does NOT include localization or assets — use Xcode for full app builds.

## What This Is

Native macOS app (Swift 6, SwiftUI, macOS 26+) for Civo Cloud. Menu bar for firewall management, main window with full resource dashboard. Connects directly to Civo REST API v2 + Kubernetes API. Zero external dependencies — only Apple frameworks (SwiftUI, CryptoKit, Security, LocalAuthentication, Foundation, os).

Monetization: Free tier (menu bar firewall). Full Access ($14.99 one-time, StoreKit 2) unlocks dashboard. `PaywallView` gates protected views, `StoreManager` handles transactions.

## Architecture

```
CivoCloudManagerApp (@main)
├── MenuBarExtra → MenuBarView → AppState → CivoFirewallService + IPDetector
├── Window("onboarding") → OnboardingView
└── Window("main") → MainWindowView → 8 ViewModels → Services → CivoAPIClient + KubernetesAPIClient + S3Client

Data flow: User → ViewModel → Service → CivoAPIClient (URLSession) → JSON → @Observable state → SwiftUI
K8s flow: Cluster selected → auto-open port 6443 → kubeconfig → KubeconfigParser → KubernetesAPIClient (PKCS#12 mTLS) → K8s API
S3 flow: ObjectStoreBrowserView → S3Client (AWS SigV4 via CryptoKit) → ListObjects/Get/Put/Delete
Pause flow: pauseStore → copy to vault (4 parallel) → verify keys+sizes → delete original → manifest
```

## Key Services

- **CivoAPIClient** — singleton. `get()`, `getPaginatedList()`, `getArray()`, `post()`, `put()`, `delete()`. Bearer token via CivoConfig (Keychain + UserDefaults).
- **KubernetesAPIClient** — per-cluster, ephemeral. PKCS#12 client cert auth via `/usr/bin/openssl` + `SecPKCS12Import`. Supports nodes, pods, logs, metrics, events, deployments, scaling, PVCs, configmaps, secrets, exec. `NSAllowsArbitraryLoads` for self-signed certs on IPs.
- **S3Client** — per-store, ephemeral. AWS SigV4 signing (CryptoKit). ListObjects v2, Get, Put, Delete, Head. Path-style URLs. S3XMLParser with XML entity decoding.
- **ObjectStorePauseService** — vault-based pause/resume. Copy files to `civo-cloud-manager` vault → verify → delete original. Resume recreates store with stored `credentialId`. `.restored` flag for safe cleanup. Manifest in vault JSON + UserDefaults fallback. 4 concurrent transfers.

## Civo API Formats

- **Paginated:** Kubernetes, Databases, Instances, Object Stores, Credentials → `{"page":1,"items":[...]}`
- **Plain array:** Firewalls, Rules, Volumes, Load Balancers, Networks, Regions, SSH Keys, DNS, Sizes → `[...]`
- **Plain text:** Kubeconfig → YAML string

## JSON Quirks

- `rules_count`: String or Int. `cidr`: String or Array. `region.current`: "Yes"/"No" string.
- All quota fields are Strings. `loadbalancer.Backends` has capital B (CodingKey).

## Key Patterns

- **Concurrency** — Swift 6 strict. Models are Sendable. ViewModels are @Observable @MainActor. `sending [String: Any]` for body dicts crossing actor boundaries.
- **Touch ID** — `LAContext.evaluatePolicy(.deviceOwnerAuthentication)` async. Never DispatchQueue callbacks.
- **Auto-firewall** — K8s API auto-opens port 6443 on cluster select, auto-closes on navigate back. Rule: `civo-cloud-<hostname>-k8s-api`.
- **Delete confirmation** — DeleteConfirmationSheet requires typing resource name. All resources.
- **Credentials** — Object Store credentials via `/objectstore/credentials` (paginated). Linked via `ownerInfo.credentialId`. Touch ID-protected secrets.
- **Pause/Resume** — `credential.id` saved in manifest (not `store.credentialId`). Vault auto-resizes in 500 GB increments. Orphaned folders auto-recovered. If credentialId missing, Resume shows credential picker.
- **Cancelled requests** — suppress `URLError.cancelled` via `CivoAPIError.userMessage()`.
- **S3 signing** — query params sorted before signing. Path-style URLs only.
- **Kubeconfig export** — use `.text` UTType, not `.yaml`.

## Code Layout

```
Sources/App/          @main, 4 scenes (MenuBarExtra, onboarding, main, help)
Sources/Models/       28 Codable Sendable types (Civo resources, K8s types, PausedObjectStore)
Sources/Services/     CivoAPIClient, CivoConfig, 13 resource services, KubeconfigParser,
                      KubernetesAPIClient, S3Client, ObjectStorePauseService, IPDetector,
                      NotificationService, ActivityLog, StoreManager, CivoChargesService
Sources/ViewModels/   8 @Observable @MainActor VMs with CRUD state
Sources/Views/        MenuBarView, AppState, OnboardingView, HelpView
  MainWindow/         NavigationSplitView, DashboardView, 11 create forms, QuotaEditView,
                      CostDashboardView, RateEditorView
    Kubernetes/       ClusterDetail, NodeDetail, PodList, PodLog, PodExec, EditLabels
    Compute/          InstanceDetail, SSHKeyList
    Storage/          ObjectStoreDetail, ObjectStoreBrowser, ObjectStorePause,
                      CredentialList, DatabaseDetail, VolumeDetail
    Networking/       FirewallDetail, CreateRule, DomainList, LoadBalancerDetail
    Account/          APIHealth, About, RegionList
  Shared/             StatusBadge, QuotaGauge, ResourceListRow, EmptyState, ErrorBanner,
                      SuccessOverlay, DeleteConfirmationSheet, StaggeredAppear,
                      K8sConnectingView, PaywallView, QuickSearchView, SparklineView,
                      ExportView, SizePickerGrid
Sources/Utilities/    Logger (os.Logger)
Tests/                21 model decoding tests (Swift Testing, single file: APIDecodingTests.swift)
CivoCloudManager/     Info.plist, Entitlements, Assets, Localizable.xcstrings (525 strings × 8 languages),
                      StoreKit config, PrivacyInfo.xcprivacy, InfoPlist.strings (8 lprojs)
```

## Error Types

- `CivoAPIError` — noAPIKey, noRegion, httpError, decodingError, networkError
- `IPDetectorError` — noIPReturned, invalidIP, allProvidersFailed, privateIP, ipv6NotSupported
- `S3Error` — invalidURL, invalidResponse, httpError
- `PauseError` — missingCredentials, vaultNotFound, verificationFailed, vaultDataMissing, vaultDataIncomplete, storeExistsWithDifferentCredential, storeNotReady
