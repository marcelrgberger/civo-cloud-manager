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

A native macOS app for Civo Cloud. Menu bar for quick-access firewall management, main window with full resource dashboard and CRUD. Connects directly to the Civo REST API v2 — no CLI dependency.

- **Swift 6.0**, strict concurrency (Sendable everywhere)
- **macOS 15+** (Sequoia), macOS 26 (Tahoe) ready
- **SwiftUI** with `MenuBarExtra` + 2 `Window` scenes + `NavigationSplitView`
- **Zero external packages** — SPM with no dependencies
- **Native HTTP API** — `CivoAPIClient` using URLSession, no CLI wrapping
- **Full CRUD** — create, view, edit (DNS records), and delete for all resource types

## Architecture

```
CivoCloudManagerApp (@main)
├── MenuBarExtra → MenuBarView → AppState → CivoFirewallService + IPDetector
├── Window("onboarding") → OnboardingView → AppState
└── Window("main") → MainWindowView → 8 ViewModels → 13 Services → CivoAPIClient

CivoAPIClient (shared singleton)
├── GET  /quota, /kubernetes/clusters, /databases, /firewalls, /sizes, /disk_images, ...
├── POST /kubernetes/clusters, /databases, /instances, /firewalls, /volumes, /objectstores, /sshkeys, /dns, /dns/:id/records
├── PUT  /kubernetes/clusters/:id, /instances/:id, /networks/:id, /dns/:id, /dns/:id/records/:id, /quota
├── DELETE /kubernetes/clusters/{id}, /databases/{id}, /instances/{id}, /networks/{id}, /firewalls/{id}, ...
└── Bearer token auth via CivoConfig (Keychain + UserDefaults)

DashboardView (clickable cards → sidebar navigation)
├── Resource cards with hover scale animation
├── Binding to sidebar selection
└── QuotaEditView (quota increase request form via PUT /quota)

Create Views (10 sheet forms)
├── Simple: Firewall, Network, Domain, SSHKey, Volume, ObjectStore
├── Complex: Database, Instance, Kubernetes Cluster
├── DNS Record (with edit support)
└── All use .formStyle(.grouped), Cancel + Create toolbar

Delete Support
├── Networks (context menu, skips default network)
├── Firewalls (context menu with confirmation)
├── Load Balancers (context menu with confirmation)
├── Volumes (individual + bulk cleanup of unused)
├── All resources: Instances, SSH Keys, Databases, Domains, Object Stores
└── All use DeleteConfirmationSheet (requires typing resource name to confirm)
```

**Key data flow:** User action → ViewModel method → Service → CivoAPIClient (URLSession) → decode JSON → update @Observable state → SwiftUI reacts.

**Create flow:** "+" toolbar button → sheet with Form → ViewModel.create(body) → Service.create(body) → POST → dismiss sheet → show SuccessOverlay → refresh list.

**Delete flow:** Context menu "Delete" → DeleteConfirmationSheet (type resource name to confirm) → ViewModel.remove(id) → Service.remove(id) → DELETE → refresh list.

**Quota change flow:** "Request Change" button → QuotaEditView sheet with steppers → ViewModel.updateQuota(body) → CivoQuotaService.updateQuota(body) → PUT /quota.

**Volume cleanup flow:** Toolbar "Cleanup Unused" button → confirmation dialog listing unattached volumes → bulk delete all → refresh list.

**Object store credentials flow:** Context menu "Show Credentials" → sheet displaying endpoint, access_key_id, secret_access_key as selectable text.

## Key Patterns

- **CivoAPIClient** — singleton HTTP client. Methods: `get()`, `getPaginatedList()`, `getArray()`, `post()`, `put()`, `delete()`.
- **CivoConfig** — stores API key (Keychain) and region (UserDefaults). Read by services on every request.
- **Service per resource domain** — each `Civo*Service` wraps API calls for one resource type with list/create/update/delete methods.
- **CivoSizeService** — fetches available sizes (GET /sizes) and disk images (GET /disk_images) for create form pickers. All sizes shown without type filtering.
- **ViewModel CRUD state** — each VM has `isCreating`, `isSaving`, `saveError`, `showSuccess` for managing create/edit flows.
- **`sending` parameters** — all ViewModel create/update methods use `sending [String: Any]` to satisfy Swift 6 strict concurrency when passing bodies from @MainActor to nonisolated services.
- **Rule ownership** — rules labeled `civo-cloud-<hostname>-<firewallname>`, app only touches its own.
- **IP detection** — 3-provider fallback chain with IPv4 validation.
- **Dashboard navigation** — resource cards accept `$selection` binding, clicking navigates to sidebar section.
- **SuccessOverlay** — shared component, auto-dismiss after 1.5s with opacity+scale transition.
- **DeleteConfirmationSheet** — shared component for all destructive operations. Requires typing the exact resource name to enable the delete button. Used by all list views.
- **Context menu delete** — all resource list views have "Delete" in context menu, opening DeleteConfirmationSheet.
- **Quota change request** — QuotaEditView with steppers for all quota limits, submits PUT /quota via CivoQuotaService.updateQuota.
- **Volume cleanup** — toolbar button to bulk-delete volumes not attached to any instance/cluster, with confirmation listing affected volumes.
- **Object store credentials** — CivoObjectStore model includes accessKeyId and secretAccessKey; context menu "Show Credentials" displays them in a sheet.

## Code Layout

- `Sources/App/` — @main entry, 3 scene definitions
- `Sources/Models/` — 16 Codable model types (includes CivoSize, CivoDiskImage; CivoObjectStore has accessKeyId/secretAccessKey)
- `Sources/Services/` — CivoAPIClient, CivoConfig, 13 resource services (includes CivoSizeService), IPDetector
  - `CivoNetworkService` — list, create, update, delete (removeNetwork)
  - `CivoFirewallService` — list, create, delete (removeFirewall), rule CRUD, status checks
  - `CivoQuotaService` — GET /quota, PUT /quota (updateQuota)
  - `CivoLoadBalancerService` — list, delete (removeLoadBalancer)
- `Sources/ViewModels/` — 8 @Observable @MainActor view models with CRUD state
- `Sources/Views/` — MenuBarView, AppState, OnboardingView
- `Sources/Views/MainWindow/` — NavigationSplitView with categorized views + 10 create/edit views + QuotaEditView
- `Sources/Views/MainWindow/QuotaEditView.swift` — quota increase request form with steppers for all limits
- `Sources/Views/Shared/` — StatusBadge, QuotaGauge, ResourceListRow, EmptyStateView, ErrorBanner, SuccessOverlay, DeleteConfirmationSheet, PaywallView
- `Sources/Utilities/` — Logger (os.Logger)
- `Tests/` — 21 model decoding tests
- `CivoCloudManager/` — Xcode project support (Info.plist, Entitlements, Assets)

## Civo API Response Formats

Critical: the API uses TWO different list formats:
- **Paginated:** Kubernetes, Databases, Instances, Object Stores → `{"page":1,"items":[...]}`
- **Plain array:** Firewalls, Rules, Volumes, Load Balancers, Networks, Regions, SSH Keys, DNS, Sizes, Disk Images → `[...]`

Use `api.getPaginatedList()` or `api.getArray()` accordingly.

## Civo JSON Quirks

- `rules_count` is **String or Int** (custom decoder handles both)
- `cidr` can be **String or Array** (custom decoder handles both)
- `region.current` is **String "Yes"/"No"** (not Bool)
- All quota fields are **Strings** (not Int)
- `database.nodes`, `database.port` are **Int**
- `loadbalancer.Backends` has **capital B** (CodingKey maps it)

## Error Types

- `CivoAPIError` — noAPIKey, noRegion, httpError, decodingError, networkError
- `IPDetectorError` — noIPReturned, invalidIP, allProvidersFailed, privateIP, ipv6NotSupported

## Concurrency Model

Swift 6 strict concurrency. All model types are Sendable. ViewModels are @Observable @MainActor. CivoAPIClient is Sendable (uses URLSession). CivoConfig is @unchecked Sendable (reads/writes UserDefaults which is thread-safe). ViewModel create/update methods use `sending` parameter modifier for `[String: Any]` body dicts to avoid data race errors when crossing actor boundaries.
