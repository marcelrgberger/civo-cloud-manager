# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Build & Run

```bash
swift build                            # Debug build (SPM)
swift build -c release                 # Release build (SPM)
swift test                             # Run 21 decoding tests
open CivoCloudManager.xcodeproj        # Open Xcode project, Cmd+R
xcodegen generate                      # Regenerate .xcodeproj from project.yml
```

No external dependencies — only Apple frameworks (SwiftUI, ServiceManagement, Foundation, os).

## What This Is

A native macOS app for Civo Cloud. Menu bar for quick-access firewall management, main window with full resource dashboard. Connects directly to the Civo REST API v2 — no CLI dependency.

- **Swift 6.0**, strict concurrency (Sendable everywhere)
- **macOS 15+** (Sequoia), macOS 26 (Tahoe) ready
- **SwiftUI** with `MenuBarExtra` + 2 `Window` scenes + `NavigationSplitView`
- **Zero external packages** — SPM with no dependencies
- **Native HTTP API** — `CivoAPIClient` using URLSession, no CLI wrapping

## Architecture

```
CivoCloudManagerApp (@main)
├── MenuBarExtra → MenuBarView → AppState → CivoFirewallService + IPDetector
├── Window("onboarding") → OnboardingView → AppState
└── Window("main") → MainWindowView → 8 ViewModels → 12 Services → CivoAPIClient

CivoAPIClient (shared singleton)
├── GET /quota, /kubernetes/clusters, /databases, /firewalls, ...
├── POST /firewalls/{id}/rules (create firewall rules)
├── DELETE /kubernetes/clusters/{id}, /databases/{id}, ...
└── Bearer token auth via CivoConfig (UserDefaults)
```

**Key data flow:** User action → ViewModel method → Service → CivoAPIClient (URLSession) → decode JSON → update @Observable state → SwiftUI reacts.

## Key Patterns

- **CivoAPIClient** — singleton HTTP client. Two list methods: `getPaginatedList()` for `{items:[]}` responses, `getArray()` for `[]` responses.
- **CivoConfig** — stores API key and region in UserDefaults. Read by services on every request.
- **Service per resource domain** — each `Civo*Service` wraps API calls for one resource type.
- **Rule ownership** — rules labeled `civo-cloud-<hostname>-<firewallname>`, app only touches its own.
- **IP detection** — 3-provider fallback chain with IPv4 validation.

## Code Layout

- `Sources/App/` — @main entry, 3 scene definitions
- `Sources/Models/` — 14 Codable model types
- `Sources/Services/` — CivoAPIClient, CivoConfig, 12 resource services, IPDetector
- `Sources/ViewModels/` — 8 @Observable @MainActor view models
- `Sources/Views/` — MenuBarView, AppState, OnboardingView
- `Sources/Views/MainWindow/` — NavigationSplitView with categorized views
- `Sources/Views/Shared/` — StatusBadge, QuotaGauge, ResourceListRow, EmptyStateView, ErrorBanner
- `Sources/Utilities/` — Logger (os.Logger)
- `Tests/` — 21 model decoding tests
- `CivoCloudManager/` — Xcode project support (Info.plist, Entitlements, Assets)

## Civo API Response Formats

Critical: the API uses TWO different list formats:
- **Paginated:** Kubernetes, Databases, Instances, Object Stores → `{"page":1,"items":[...]}`
- **Plain array:** Firewalls, Rules, Volumes, Load Balancers, Networks, Regions, SSH Keys, DNS → `[...]`

Use `api.getPaginatedList()` or `api.getArray()` accordingly.

## Civo JSON Quirks

- `rules_count` is **String** (not Int)
- `cidr` can be **String or Array** (custom decoder handles both)
- `region.current` is **String "Yes"/"No"** (not Bool)
- All quota fields are **Strings** (not Int)
- `database.nodes`, `database.port` are **Strings**
- `loadbalancer.Backends` has **capital B** (CodingKey maps it)

## Error Types

- `CivoAPIError` — noAPIKey, noRegion, httpError, decodingError, networkError
- `IPDetectorError` — noIPReturned, invalidIP, allProvidersFailed, privateIP, ipv6NotSupported

## Concurrency Model

Swift 6 strict concurrency. All model types are Sendable. ViewModels are @Observable @MainActor. CivoAPIClient is Sendable (uses URLSession). CivoConfig is @unchecked Sendable (reads/writes UserDefaults which is thread-safe).
