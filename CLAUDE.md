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

No external dependencies — only Apple frameworks (SwiftUI, ServiceManagement, Foundation, os, Security, CryptoKit, LocalAuthentication, StoreKit, UserNotifications).

## What This Is

A native macOS app for Civo Cloud. Menu bar for quick-access firewall management, main window with full resource dashboard and CRUD. Connects directly to the Civo REST API v2 and Kubernetes API — no CLI dependency.

- **Swift 6.0**, strict concurrency (Sendable everywhere)
- **macOS 15+** (Sequoia), macOS 26 (Tahoe) ready
- **SwiftUI** with `MenuBarExtra` + 2 `Window` scenes + `NavigationSplitView`
- **Zero external packages** — SPM with no dependencies
- **Native HTTP API** — `CivoAPIClient` using URLSession, no CLI wrapping
- **Direct Kubernetes API** — `KubernetesAPIClient` connects to K8s clusters using client certificate auth via Security.framework
- **Full CRUD** — create, view, edit (DNS records), and delete for all resource types

## Architecture

```
CivoCloudManagerApp (@main)
├── MenuBarExtra → MenuBarView → AppState → CivoFirewallService + IPDetector
├── Window("onboarding") → OnboardingView → AppState
└── Window("main") → MainWindowView → 8 ViewModels → 18 Services → CivoAPIClient + KubernetesAPIClient + S3Client

CivoAPIClient (shared singleton)
├── GET  /quota, /kubernetes/clusters, /databases, /firewalls, /sizes, /disk_images, ...
├── GET  /kubernetes/clusters/:id/kubeconfig → KubeconfigParser → KubernetesAPIClient
├── POST /kubernetes/clusters, /databases, /instances, /firewalls, /volumes, /objectstores, /objectstore/credentials, /sshkeys, /dns, /dns/:id/records
├── PUT  /kubernetes/clusters/:id, /instances/:id, /networks/:id, /dns/:id, /dns/:id/records/:id, /quota, /objectstores/:id
├── DELETE /kubernetes/clusters/{id}, /databases/{id}, /instances/{id}, /networks/{id}, /firewalls/{id}, /objectstore/credentials/{id}, ...
└── Bearer token auth via CivoConfig (Keychain + UserDefaults)

KubernetesAPIClient (per-cluster, ephemeral)
├── GET /api/v1/nodes/{name} → K8sNode (capacity, conditions, addresses, systemInfo)
├── GET /api/v1/pods?fieldSelector=spec.nodeName={name} → K8sPod[]
├── GET /api/v1/namespaces/{ns}/pods/{name}/log → log text
├── DELETE /api/v1/namespaces/{ns}/pods/{name} → restart pod
├── GET /apis/metrics.k8s.io/v1beta1/nodes → K8sNodeMetrics[] (live CPU/Memory)
├── GET /api/v1/events → K8sEvent[] (cluster events, warnings)
├── GET /apis/apps/v1/deployments → K8sDeployment[] (workloads with replica status)
├── PATCH /apis/apps/v1/namespaces/{ns}/deployments/{name}/scale → scale deployment
├── GET /api/v1/persistentvolumeclaims → K8sPVC[]
├── GET /api/v1/persistentvolumes → K8sPV[] (capacity, Civo Volume ID via CSI volumeHandle)
├── GET /api/v1/configmaps → K8sConfigMap[]
├── GET /api/v1/secrets → K8sSecret[] (Helm release detection via sh.helm.release.v1 labels)
├── GET /apis/apps/v1/daemonsets → K8sDaemonSet[]
├── GET /apis/apps/v1/statefulsets → K8sStatefulSet[]
├── GET /apis/batch/v1/cronjobs → K8sCronJob[]
├── GET /api/v1/services → K8sService[]
├── GET /apis/networking.k8s.io/v1/ingresses → K8sIngress[] (TLS info)
├── GET /api/v1/namespaces → K8sNamespace[]
├── POST /api/v1/namespaces/{ns}/pods/{name}/exec → pod exec (command execution)
├── PATCH /apis/apps/v1/namespaces/{ns}/deployments/{name} → restart deployment (annotation patch)
├── Client certificate auth via PKCS#12 (/usr/bin/openssl + SecPKCS12Import) + Security.framework
└── execute() supports configurable HTTP method and body

S3Client (per-store, ephemeral)
├── ListObjects v2 (prefix/delimiter folder navigation)
├── ListAllObjects (recursive listing without delimiter)
├── GetObject (file download)
├── HeadObject (file metadata)
├── AWS Signature V4 signing via CryptoKit (HMAC-SHA256, SigV4-compliant URI encoding)
├── S3XMLParser for ListBucketResult XML responses
└── ObjectStoreBrowserView with breadcrumb navigation, multi-select, folder download, progress bar

DashboardView (clickable cards → sidebar navigation)
├── Resource cards with hover scale animation
├── Binding to sidebar selection
└── QuotaEditView (quota increase request form via PUT /quota)

Create Views (11 sheet forms)
├── Simple: Firewall, Network, Domain, SSHKey, Volume, ObjectStore
├── Complex: Database, Instance, Kubernetes Cluster
├── DNS Record (with edit support)
├── Firewall Rule (protocol, ports, CIDR, direction, action)
└── All use .formStyle(.grouped), Cancel + Create toolbar

Drill-Down Views
├── Kubernetes: ClusterListView → ClusterDetailView (auto-connect K8s API with K8sConnectingView animation, live metrics/events/sparklines, collapsible workloads/networking/storage/config, namespace filter, deployment scaling/restart, PVC-Volume linking, ConfigMap/Secret viewer, Helm releases, Ingress TLS) → K8sNodeDetailView → K8sPodListView (pod restart) → PodLogView (auto-refresh) → PodExecView (command execution)
├── Object Stores: ObjectStoreListView → ObjectStoreDetailView (credentials via credential_id, config, resize) → ObjectStoreBrowserView (S3 file browser with breadcrumbs, folders, download)
├── Credentials: CredentialListView (list, create, delete Object Store credentials, Touch ID-protected secrets, hover animation)
├── Databases: DatabaseListView → DatabaseDetailView (credentials section with Touch ID-protected password via LAContext)
├── Firewalls: FirewallListView → FirewallDetailView (rule list, add/delete rules, IP presets, firewall timer)
├── Labels: ClusterDetailView → EditLabelsView (add/remove node pool labels)
├── Instances: InstanceListView → InstanceDetailView (resize, reverse DNS, volume attach/detach)
└── Load Balancers: LoadBalancerListView → LoadBalancerDetailView

Auto-Firewall for K8s API
├── Opens port 6443 for user's current IP automatically when cluster is selected (lazy auto-connect)
├── Uses IPDetector + CivoFirewallService
├── Rule labeled civo-cloud-<hostname>-k8s-api
└── Auto-closes the rule when navigating back from cluster

Delete Support
├── All resources use DeleteConfirmationSheet (requires typing resource name)
├── Networks (skips default), Firewalls, Load Balancers, Firewall Rules
└── Instances, SSH Keys, Databases, Domains, Volumes, Object Stores

Animations
├── Staggered list rows (30ms delay per row, fade+slide)
├── Dashboard cards spring from bottom with index delay
├── Sidebar→detail: spring + opacity content transition
├── Drill-down: move+opacity spring transitions (multi-level K8s navigation)
├── K8sConnectingView: rotating helm icon, pulsing blue circle, 5-step progress with green checkmark springs
├── CredentialListView: hover animation (key icon rotation + orange background), staggered spring (60ms delay)
└── SuccessOverlay: spring scale entry/exit
```

**Key data flow:** User action → ViewModel method → Service → CivoAPIClient (URLSession) → decode JSON → update @Observable state → SwiftUI reacts.

**K8s API flow:** Click node name → ViewModel → CivoKubernetesService.getKubeconfig(id) → KubeconfigParser.parse(yaml) → KubernetesAPIClient(serverURL, certs via PKCS#12) → GET /api/v1/nodes/{name} → K8sNode → K8sNodeDetailView.

**K8s live metrics flow:** Select cluster → auto-open port 6443 via CivoFirewallService → download kubeconfig → KubernetesAPIClient → GET metrics, events, deployments, PVCs, PVs → show circular CPU/Memory gauges, events (relative time), collapsible workloads/networking/storage, namespace filter. Navigate back → auto-close firewall rule.

**Create flow:** "+" toolbar button → sheet with Form → ViewModel.create(body) → Service.create(body) → POST → dismiss sheet → show SuccessOverlay → refresh list.

**Delete flow:** Context menu "Delete" → DeleteConfirmationSheet (type resource name to confirm) → ViewModel.remove(id) → Service.remove(id) → DELETE → refresh list.

**Quota change flow:** "Request Change" button → QuotaEditView sheet with steppers → ViewModel.requestQuotaChange(body) → CivoQuotaService.requestQuotaChange(body) → PUT /quota.

**Firewall rule flow:** Click firewall → FirewallDetailView shows rules → "+" opens CreateRuleView → delete via context menu with name confirmation.

**Object store detail flow:** Click object store → ObjectStoreDetailView shows credentials (from linked CivoObjectStoreCredential via credential_id), endpoint, config, and resize section → stepper changes max size → PUT /objectstores/:id. "Browse Files" button opens ObjectStoreBrowserView → S3Client (AWS SigV4) → ListObjects v2 → folder navigation → multi-select download.

**Pod logs flow:** K8sNodeDetailView → "View Pods on this Node" → K8sPodListView (right-click → "Restart Pod") → click pod → PodLogView (scrollable monospaced logs, auto-scroll toggle, refresh, auto-refresh 3s timer).

## Key Patterns

- **CivoAPIClient** — singleton HTTP client. Methods: `get()`, `getPaginatedList()`, `getArray()`, `post()`, `put()`, `delete()`.
- **KubeconfigParser** — parses kubeconfig YAML, extracts server URL, CA certificate, client certificate, and client key. Returns structured data for KubernetesAPIClient.
- **KubernetesAPIClient** — per-cluster ephemeral client. Connects directly to K8s API server using client certificate auth via PKCS#12 (`/usr/bin/openssl` creates PKCS#12 from PEM cert+key, `SecPKCS12Import` for identity creation) + Security.framework. openssl is pre-installed on every Mac. NSAllowsArbitraryLoads for self-signed certs on IP addresses. No kubectl or external tools needed. Methods: `getNodes()`, `getNode(name)`, `getPods(nodeName)`, `getPodLogs(namespace, name)`, `deletePod(namespace, name)`, `scaleDeployment(namespace, name, replicas)`, `listPVs()`, `getMetrics()`, `getEvents()`, `getDeployments()`. Generic `execute(path, method, body)` supports any HTTP method.
- **K8sMetricsParser** — parses metrics-server responses into K8sNodeMetrics/K8sPodMetrics, computes K8sClusterMetrics with CPU/Memory percentages.
- **Multi-level K8s navigation** — ClusterListView → ClusterDetailView → K8sNodeDetailView → K8sPodListView → PodLogView, all with spring move+opacity transitions.
- **Live K8s metrics** — circular CPU and Memory gauges in ClusterDetailView when connected to K8s API. Graceful fallback to static stats when metrics-server is not installed.
- **Auto-connect K8s API** — K8s API connection established lazily when cluster is selected (no manual "Connect" button). Auto-opens port 6443 for user's current IP, closes when navigating back. Rule labeled `civo-cloud-<hostname>-k8s-api`.
- **Namespace filter** — `selectedNamespace` in KubernetesViewModel filters deployments, services, ingresses, configmaps, and secrets via `filteredDeployments`/`filteredServices`/`filteredIngresses`/`filteredConfigMaps`/`filteredSecrets` computed properties.
- **Collapsible sections** — Workloads (Deployments, DaemonSets, StatefulSets, CronJobs), Networking (Services, Ingresses), and Storage (PVCs, PVs) use DisclosureGroup.
- **Deployment scaling** — scale deployments via Kubernetes PATCH to `/scale` subresource.
- **Pod restart** — right-click "Restart Pod" deletes the pod via KubernetesAPIClient.deletePod().
- **Pod log auto-refresh** — toggle enables a 3-second timer to re-fetch logs automatically.
- **Relative event timestamps** — events show "2m ago", "1h ago" instead of absolute times.
- **PVC-Volume linking** — PVCs show linked Civo Volume ID by resolving PV's CSI volumeHandle. PVs listed with capacity.
- **Instance actions** — stop, start, and reboot instances via CivoInstanceService and right-click context menu.
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
- **Quota change request** — QuotaEditView with steppers for all quota limits, submits PUT /quota via CivoQuotaService.requestQuotaChange.
- **Object store credentials** — managed separately via `/objectstore/credentials` (paginated). Each object store links to a credential via `ownerInfo.credentialId`. CivoObjectStoreCredential has `accessKeyId` and `secretAccessKeyId`. ObjectStoreDetailView shows credentials, config, resize section, and "Browse Files" button. CredentialListView in sidebar provides dedicated management (list, create, delete) with Touch ID-protected secret keys and hover animations.
- **Database credentials** — CivoDatabase has `username` and `password` fields. DatabaseDetailView shows a "Credentials" section: username is visible, password is protected by Touch ID / system password via `LAContext.evaluatePolicy(.deviceOwnerAuthentication)` async.
- **Touch ID / biometric auth** — uses `LAContext` from LocalAuthentication framework with async `evaluatePolicy` (no DispatchQueue). Used in DatabaseDetailView (password reveal), CredentialListView (secret key reveal), and ObjectStoreDetailView (secret key reveal).
- **K8s connecting animation** — K8sConnectingView (in Views/Shared/) shows animated 5-step progress while connecting to K8s API: firewall, kubeconfig, certificates, API server, metrics. Rotating helm icon with pulsing blue circle, green checkmark spring on completion.
- **Object store resize** — ObjectStoreDetailView has a stepper to change max size, submitted via PUT /objectstores/:id.
- **S3 file browser** — ObjectStoreBrowserView uses S3Client with AWS Signature V4 signing via CryptoKit (HMAC-SHA256). ListObjects v2 with prefix/delimiter for folder navigation, breadcrumb path, folder drill-down, file icons by extension. Multi-select (Cmd+Click/Shift+Click) with native List selection. Single file → NSSavePanel, multiple files/folders → NSOpenPanel folder picker with recursive download preserving folder structure. Download progress bar. Double-click navigates into folders or downloads files. S3XMLParser handles ListBucketResult XML responses.
- **Firewall rule drill-down** — click firewall → FirewallDetailView shows rules with badges → add/delete rules.
- **StaggeredAppear** — shared ViewModifier for index-based delayed fade+slide animations on list rows.
- **Spring transitions** — sidebar→detail uses spring + opacity; drill-downs use move+opacity spring.
- **Save Kubeconfig** — toolbar button in ClusterDetailView exports kubeconfig as .yaml file via NSSavePanel with .text content type.
- **Editable node pool labels** — EditLabelsView allows add/remove labels on node pools, submitted via PUT to CivoKubernetesService.updateCluster.
- **QuickSearchView** — global search (Cmd+K) across all resources. Sheet overlay with filtering by instances, clusters, databases, networks, volumes, domains.
- **SizePickerGrid** — shared grid picker for Civo sizes used in create instance/database/cluster forms. Visual cards with CPU, RAM, disk specs.
- **SparklineView** — lightweight sparkline chart for CPU/Memory history in ClusterDetailView. Renders from `cpuHistory`/`memoryHistory` circular buffers (max 30 data points).
- **ExportView** — export resource data (Cmd+Shift+E). Supports CSV/JSON export of instances, clusters, databases, networks, volumes, domains.
- **CostDashboardView** — cost estimation dashboard. Uses CivoChargesService to fetch billing data with monthly caching. Custom rate editor via RateEditorView.
- **APIHealthView** — monitors Civo API endpoint health. Checks connectivity to key API endpoints with latency display.
- **ActivityLog** — singleton that tracks user actions (instance start/stop/reboot, resize, DNS changes). Used by InstanceViewModel for audit trail.
- **NotificationService** — sends macOS user notifications. Used for pod restart alerts when container restart count increases.
- **Pod restart alerts** — KubernetesViewModel tracks pod restart counts across refreshes. Sends notification via NotificationService when restarts increase (after initial load).
- **IP Presets** — saved CIDR/label combinations for quick firewall rule creation. Stored as IPPreset model.
- **Firewall Timer** — temporary firewall rules that auto-expire.
- **ConfigMap/Secret viewer** — ClusterDetailView shows K8s ConfigMaps and Secrets in collapsible Config section. Secrets can be decoded (base64) via `getSecretData()`.
- **Helm releases** — detected from K8s secrets with `owner=helm` labels. Parsed into HelmRelease model showing name, chart, version, status, revision.
- **Pod Exec** — PodExecView allows running commands in pods via KubernetesAPIClient.runCommandInPod().
- **Ingress TLS** — K8sIngress model includes TLS information displayed in ClusterDetailView networking section.
- **Deployment restart** — restart deployments via KubernetesAPIClient.restartDeployment() (annotation patch with current timestamp).
- **Instance detail** — InstanceDetailView with resize, stop/start/reboot, reverse DNS editing (inline), SSH command with key path, volume attach/detach. Auto-refresh every 5s while building/provisioning.
- **SSH key generation** — CreateSSHKeyView generates Ed25519 key pairs via /usr/bin/ssh-keygen. Private key saved to ~/Downloads + encrypted backup in app storage (SSHKeychain using AES-GCM via CryptoKit). Public key uploaded to Civo. "Move to ~/.ssh/" button copies command and opens Terminal. Backup toolbar button in SSH Keys list recovers stored keys.
- **About system tools** — AboutView lists required macOS tools (/usr/bin/openssl, /usr/bin/ssh-keygen) with availability check.
- **Keyboard shortcuts** — Cmd+K (QuickSearchView), Cmd+Shift+E (ExportView).
- **Sidebar sections** — Dashboard, Instances, SSH Keys, Kubernetes, Networks, Firewalls, Load Balancers, Domains, Databases, Volumes, Object Stores, Credentials, Cost Estimate, API Health, Regions, About. Categorized into Overview, Compute, Kubernetes, Networking, Storage & Data, Account.
- **Colored sidebar icons** — each SidebarSection has an `iconColor` property: Dashboard (blue), Instances (green), SSH Keys (orange), Kubernetes (blue), Networks (green), Firewalls (red), Load Balancers (indigo), Domains (teal), Databases (purple), Volumes (orange), Object Stores (cyan), Credentials (yellow), Cost Estimate (green), API Health (pink), Regions (mint), About (secondary).
- **CivoAPIError.userMessage** — all ViewModels use `CivoAPIError.userMessage(error)` instead of `error.localizedDescription` to silently suppress cancelled request errors.

## Code Layout

- `Sources/App/` — @main entry, 3 scene definitions
- `Sources/Models/` — 27 Codable model types (includes CivoSize, CivoDiskImage, K8sNode, K8sPod, K8sMetrics, K8sEvent, K8sWorkload, K8sStorage, K8sNetworking, K8sConfig, CivoObjectStoreCredential, CivoCharge, IPPreset, FirewallRule, HelmRelease; CivoObjectStore has ownerInfo with accessKeyId/credentialId; CivoDatabase has username/password)
  - `K8sNode.swift` — K8sNode, K8sNodeCondition, K8sNodeAddress, K8sResourceList, K8sNodeSystemInfo, K8sNodeSpec, K8sNodeTaint
  - `K8sPod.swift` — K8sPod, K8sPodStatus, K8sContainerStatus, K8sPodSpec, K8sContainer
  - `K8sMetrics.swift` — K8sNodeMetrics, K8sPodMetrics, K8sClusterMetrics, K8sMetricsParser
  - `K8sEvent.swift` — K8sEvent, K8sObjectReference
  - `K8sWorkload.swift` — K8sDeployment, K8sDeploymentStatus, K8sDaemonSet, K8sStatefulSet, K8sCronJob
  - `K8sStorage.swift` — K8sPV, K8sPVSpec, K8sCSISource, K8sPVC
  - `K8sNetworking.swift` — K8sService, K8sIngress, K8sNamespace
  - `K8sConfig.swift` — K8sConfigMap, K8sSecret
  - `HelmRelease.swift` — HelmRelease (parsed from Helm secrets)
  - `IPPreset.swift` — IPPreset (saved firewall rule presets)
  - `FirewallRule.swift` — FirewallRule (custom rule model)
  - `CivoCharge.swift` — CivoCharge (cost/billing data)
- `Sources/Services/` — CivoAPIClient, CivoConfig, 13 resource services (includes CivoSizeService), KubeconfigParser, KubernetesAPIClient, S3Client, IPDetector, NotificationService, ActivityLog, StoreManager, CivoChargesService
  - `KubeconfigParser.swift` — parses kubeconfig YAML → server URL, CA cert, client cert, client key
  - `KubernetesAPIClient.swift` — direct K8s API client using PKCS#12 client certificate auth (/usr/bin/openssl + SecPKCS12Import) via Security.framework. Supports nodes, pods, logs, metrics, events, deployments, daemonsets, statefulsets, cronjobs, services, ingresses, namespaces, configmaps, secrets, PVs, PVCs, deletePod, scaleDeployment, restartDeployment, runCommandInPod. Generic execute() supports configurable HTTP method and body.
  - `S3Client.swift` — S3-compatible client with AWS Signature V4 signing via CryptoKit (HMAC-SHA256). ListObjects v2, GetObject, HeadObject, S3XMLParser for XML responses.
  - `CivoKubernetesService` — list, show, create, update, delete + getKubeconfig(id)
  - `CivoNetworkService` — list, create, update, delete (removeNetwork)
  - `CivoFirewallService` — list, create, delete (removeFirewall), rule CRUD, status checks
  - `CivoQuotaService` — GET /quota, PUT /quota (requestQuotaChange)
  - `CivoObjectStoreService` — list, show, create, update (resize via PUT /objectstores/:id), delete + credential CRUD (list, show, create, delete via /objectstore/credentials)
  - `CivoLoadBalancerService` — list, delete (removeLoadBalancer)
  - `CivoChargesService` — GET /charges (with date range), monthly caching for cost dashboard
  - `NotificationService` — macOS user notifications for pod restart alerts
  - `ActivityLog` — tracks user actions (instance start/stop/reboot, resize, etc.)
  - `StoreManager` — StoreKit 2 in-app purchase management, paywall state
- `Sources/ViewModels/` — 8 @Observable @MainActor view models with CRUD state
- `Sources/Views/` — MenuBarView, AppState, OnboardingView
- `Sources/Views/MainWindow/` — NavigationSplitView with categorized views + 11 create/edit views + QuotaEditView
- `Sources/Views/MainWindow/QuotaEditView.swift` — quota increase request form with steppers for all limits
- `Sources/Views/MainWindow/Kubernetes/ClusterDetailView.swift` — cluster info, conditions, pools, apps, kubeconfig save, auto-connect K8s API for live metrics/events/workloads/config, auto-firewall
- `Sources/Views/MainWindow/Kubernetes/K8sNodeDetailView.swift` — node resource cards (CPU, Memory, Pods), conditions, addresses, system info
- `Sources/Views/MainWindow/Kubernetes/K8sPodListView.swift` — pods on a node with status badge, namespace, ready count, restart count
- `Sources/Views/MainWindow/Kubernetes/PodLogView.swift` — scrollable monospaced log output with auto-scroll toggle, refresh, and auto-refresh (3s timer)
- `Sources/Views/MainWindow/Kubernetes/EditLabelsView.swift` — add/remove labels on node pools
- `Sources/Views/MainWindow/Kubernetes/PodExecView.swift` — interactive command execution in pods
- `Sources/Views/MainWindow/Compute/InstanceDetailView.swift` — instance details, resize, reverse DNS, volume attach/detach
- `Sources/Views/MainWindow/CostDashboardView.swift` — cost estimation dashboard using CivoChargesService
- `Sources/Views/MainWindow/RateEditorView.swift` — custom rate editor for cost estimates
- `Sources/Views/MainWindow/Account/APIHealthView.swift` — API endpoint health monitoring
- `Sources/Views/MainWindow/Account/AboutView.swift` — app information and version
- `Sources/Views/MainWindow/Storage/ObjectStoreDetailView.swift` — credentials (from linked credential via credential_id), endpoint, config (max size, region, status), resize section with stepper, "Browse Files" button
- `Sources/Views/MainWindow/Storage/ObjectStoreBrowserView.swift` — S3 file browser with breadcrumb navigation, folder drill-down, file icons, right-click download via NSSavePanel
- `Sources/Views/MainWindow/Storage/CredentialListView.swift` — Object Store credentials: list, create, delete, Touch ID-protected secret keys, hover animation, staggered spring
- `Sources/Views/MainWindow/Storage/DatabaseDetailView.swift` — connection details, credentials (username + Touch ID-protected password via LAContext), config, network/firewall
- `Sources/Views/MainWindow/Storage/VolumeDetailView.swift` — attachment status, mountpoint, size
- `Sources/Views/MainWindow/Networking/FirewallDetailView.swift` — rule list with badges, add/delete
- `Sources/Views/MainWindow/Networking/CreateRuleView.swift` — form for firewall rules
- `Sources/Views/Shared/` — StatusBadge, QuotaGauge, ResourceListRow, EmptyStateView, ErrorBanner, SuccessOverlay, DeleteConfirmationSheet, StaggeredAppear, K8sConnectingView, PaywallView, QuickSearchView, SparklineView, ExportView, SizePickerGrid
- `Sources/Utilities/` — Logger (os.Logger)
- `Tests/` — 21 model decoding tests
- `CivoCloudManager/` — Xcode project support (Info.plist, Entitlements, Assets)

## Civo API Response Formats

Critical: the API uses TWO different list formats:
- **Paginated:** Kubernetes, Databases, Instances, Object Stores, Object Store Credentials → `{"page":1,"items":[...]}`
- **Plain array:** Firewalls, Rules, Volumes, Load Balancers, Networks, Regions, SSH Keys, DNS, Sizes, Disk Images → `[...]`
- **Plain text:** Kubeconfig → YAML string (GET /kubernetes/clusters/:id/kubeconfig)

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
- `S3Error` — invalidURL, invalidResponse, httpError

## Important Implementation Notes

- **Touch ID / LAContext** — always use `try await context.evaluatePolicy()` (async). Never use DispatchQueue-based callbacks as they crash under strict concurrency.
- **Network cancelled errors** — suppress `URLError.cancelled` errors when a popover or view closes during an in-flight request. Do not show these in ErrorBanner.
- **S3 Signature V4** — query parameters must be sorted alphabetically before signing. Use path-style URLs for Civo Object Store (not virtual-hosted).
- **Kubeconfig export** — use `.text` as the UTType content type for NSSavePanel, not `.yaml`.

## Concurrency Model

Swift 6 strict concurrency. All model types are Sendable. ViewModels are @Observable @MainActor. CivoAPIClient is Sendable (uses URLSession). KubernetesAPIClient is Sendable (uses URLSession with PKCS#12 client certificate delegate via SecPKCS12Import). S3Client is Sendable (uses URLSession.shared). CivoConfig is @unchecked Sendable (reads/writes UserDefaults which is thread-safe). ViewModel create/update methods use `sending` parameter modifier for `[String: Any]` body dicts to avoid data race errors when crossing actor boundaries.
