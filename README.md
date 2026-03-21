# Civo Cloud Manager

A native macOS application for managing your **Civo Cloud** infrastructure. Menu bar quick-access for firewall rules, full dashboard for all resources. Connects directly to the Civo REST API — no CLI dependency.

## Features

### Menu Bar (Quick Access)
- Open/close firewall rules for your current public IP with one click
- Open All / Close All — bulk manage all configured firewalls
- Per-firewall port configuration
- Auto-detect public IPv4 via ipify.org (3 fallback providers)
- Auto-refresh every 60 seconds
- Launch at Login via SMAppService

### Dashboard (Full Management)
- **Quota overview** — circular gauges for all account limits (RAM/DB RAM in GB)
- **Quota increase request** — "Request Change" button opens form with steppers for all quota limits, sends PUT /quota
- **Clickable resource cards** — navigate directly to any resource section
- **Full CRUD** — create, view, and delete resources across all categories
- **Kubernetes** — create clusters (CNI, node pools, marketplace apps), drill-down to conditions, installed apps
- **Databases** — create PostgreSQL/MySQL instances with size, nodes, networking config
- **Networking** — create networks, firewalls, domains; add/edit/delete DNS records inline; delete networks (skips default), firewalls, and load balancers; drill-down into firewall rules (view, create, delete)
- **Storage** — create volumes and object stores with size configuration; view object store credentials (access key, secret key)
- **Compute** — create instances (size, disk image, SSH key, firewall, tags), manage SSH keys
- **Regions** — view available regions, switch active region
- **Safe deletion** — all destructive operations require typing the resource name to confirm (DeleteConfirmationSheet)
- **Smooth animations** — staggered list row appearance, spring transitions between views, animated dashboard cards
- Success overlay animation after create/edit operations
- Error banners on every view

### Monetization
- **Free tier** — menu bar firewall management
- **Full Access ($14.99)** — one-time purchase, unlocks dashboard + all resources
- **Apple offer codes** — redeem codes generated in App Store Connect
- **Family Sharing** enabled

### Localization
- 8 languages: English, German, Spanish, French, Italian, Dutch, Polish, Portuguese

### Architecture
- **Native HTTP API** — connects directly to `api.civo.com/v2`, no CLI required
- **App Sandbox** — network client entitlement
- **Keychain** — API key stored securely in macOS Keychain
- **StoreKit 2** — modern in-app purchase with transaction listener
- **Zero dependencies** — only Apple frameworks
- **Swift 6 strict concurrency** — all types Sendable

## Requirements

- **macOS 15+** (Sequoia) / macOS 26 (Tahoe) ready
- **Civo account** with API key (get one at [civo.com](https://www.civo.com))

## Installation

### Build from Source (SPM)

```bash
git clone https://github.com/marcelrgberger/civo-cloud-manager.git
cd civo-cloud-manager
swift build -c release
.build/release/CivoCloudManager
```

### Build from Xcode

```bash
open CivoCloudManager.xcodeproj
# Select scheme "CivoCloudManager" → Cmd+R
```

The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open CivoCloudManager.xcodeproj
```

## First Launch

1. The app appears as a **shield icon** in the menu bar
2. The onboarding wizard opens automatically
3. Enter your **Civo API key** (found at civo.com → Account → Security → API Keys)
4. Select your **region** (fra1, lon1, nyc1, etc.)
5. Choose which **firewalls** to manage and set the port for each
6. Optionally enable **Launch at Login**
7. Click **Finish** — the app is ready

## Usage

### Menu Bar

Click the shield icon in the menu bar to open the popover:

| Icon | Meaning |
|------|---------|
| Shield (green) | All firewalls closed |
| Shield (yellow) | Some firewalls open for your IP |
| Shield (red) | Setup not complete |

- **Open** — creates a firewall rule allowing your current IP on the configured port
- **Close** — removes the rule
- **Open All / Close All** — bulk actions for all managed firewalls
- **Dashboard** — opens the full management window
- **Settings** — re-opens the onboarding wizard
- **Refresh** — manually re-checks status

### Dashboard

Click **Dashboard** in the menu bar popover to open the main window.

The sidebar is organized into categories:

| Category | Sections | CRUD |
|----------|----------|------|
| **Overview** | Dashboard (quota gauges, clickable resource cards, quota change request) | Request Change |
| **Compute** | Instances, SSH Keys | Create, Delete |
| **Kubernetes** | Clusters (detail view for pools, apps, conditions) | Create, Delete |
| **Networking** | Networks, Firewalls (with rule drill-down), Load Balancers, Domains | Create, Edit (DNS records, firewall rules), Delete |
| **Storage & Data** | Databases, Volumes, Object Stores | Create, Delete, Show Credentials |
| **Account** | Regions | Switch |

**Each resource view provides:**
- Live data from the Civo API
- **"+" button** in the toolbar to create new resources via sheet forms
- Refresh button in the toolbar
- Error banner if the API call fails
- Context menu with Delete option (where applicable)
- **Name-confirmation delete** — typing the exact resource name required before deletion is enabled
- **Success overlay** after successful create/edit

**Network delete** skips the default network — only non-default networks can be deleted.

**Object store credentials** — context menu "Show Credentials" opens a sheet displaying access_key_id and secret_access_key as selectable text.

**Firewall rule drill-down** — click a firewall to see all its rules. Each rule shows protocol, ports, CIDR, direction (ingress/egress), and action (allow/deny) with color-coded badges. Add new rules via "+" toolbar button, delete rules via context menu with name confirmation.

**Quota increase request** — "Request Change" button in the quota section opens a form with steppers for all quota limits, submits via PUT /quota.

**Dashboard cards** are clickable — tap any card to navigate directly to that resource section.

### Create Forms

All create views use grouped SwiftUI forms with Cancel/Create toolbar buttons:

| Resource | Fields |
|----------|--------|
| **Instance** | Hostname, size, disk image, network, firewall, SSH key, tags |
| **SSH Key** | Name, public key (paste) |
| **Kubernetes Cluster** | Name, CNI plugin, node size, node count, network, marketplace apps |
| **Network** | Label, CIDR v4 |
| **Firewall** | Name, network |
| **Domain** | Domain name |
| **DNS Record** | Type (A/AAAA/CNAME/MX/TXT/SRV/NS), name, value, TTL, priority |
| **Database** | Name, software (MySQL/PostgreSQL), version, size, nodes, network, firewall |
| **Volume** | Name, size (GB), network |
| **Object Store** | Name, max size (GB) |

### Kubernetes Detail View

Click a cluster in the list to see:
- Cluster info (version, API endpoint, master IP, DNS, CNI plugin, node size)
- Health conditions (ControlPlaneReady, WorkerNodesReady, ClusterVersionSync)
- Node pools (count, size per pool)
- Installed applications (cert-manager, ingress-nginx, etc.)
- Delete button (with confirmation)

### DNS Record Management

Expand a domain in the domain list to see all records inline:
- **Add Record** button per domain
- **Edit** via context menu — opens pre-filled form
- **Delete** via context menu with confirmation

### Firewall Rule Ownership

The app only manages rules it created. Rules are labeled:

```
civo-cloud-<hostname>-<firewall-name>
```

Example: `civo-cloud-Marcels-MacBook-Pro-k8s-cluster-firewall`

This ensures the app never touches rules created by other users or tools.

---

## Architecture

### App Scenes

```mermaid
graph TB
    subgraph "CivoCloudManagerApp"
        A[MenuBarExtra] --> B[MenuBarView]
        C["Window — onboarding"] --> D[OnboardingView]
        E["Window — main"] --> F[MainWindowView]
    end

    B --> G[AppState]
    D --> G
    F --> H[DashboardViewModel]
    F --> I[KubernetesViewModel]
    F --> J[DatabaseViewModel]
    F --> K[NetworkViewModel]
    F --> L[VolumeViewModel]
    F --> M[InstanceViewModel]
    F --> N[DomainViewModel]
    F --> O[RegionViewModel]

    G --> P[CivoFirewallService]
    G --> Q[IPDetector]
    H --> R[CivoQuotaService]
    H --> S1[CivoKubernetesService]
    H --> S2[CivoDatabaseService]
    H --> S3[CivoVolumeService]
    H --> S4[CivoObjectStoreService]
    H --> S5[CivoLoadBalancerService]
    H --> S6[CivoNetworkService]
    I --> S[CivoKubernetesService]
    I --> S6
    I --> SZ[CivoSizeService]
    J --> T[CivoDatabaseService]
    J --> S6
    J --> P
    J --> SZ
    K --> U[CivoNetworkService]
    K --> P
    K --> V[CivoLoadBalancerService]
    L --> W[CivoVolumeService]
    L --> X[CivoObjectStoreService]
    L --> S6
    M --> Y[CivoInstanceService]
    M --> Z[CivoSSHKeyService]
    M --> S6
    M --> P
    M --> SZ
    N --> AA[CivoDomainService]
    O --> AB[CivoRegionService]

    P --> AC[CivoAPIClient]
    R --> AC
    S --> AC
    T --> AC
    U --> AC
    V --> AC
    W --> AC
    X --> AC
    Y --> AC
    Z --> AC
    AA --> AC
    AB --> AC
    SZ --> AC

    AC -->|HTTPS| AD["api.civo.com/v2"]
    Q -->|HTTPS| AE["ipify.org"]

    style AD fill:#7C3AED,color:#fff
    style AE fill:#0EA5E9,color:#fff
    style F fill:#2563EB,color:#fff
```

### Class Diagram — Models

```mermaid
classDiagram
    class CivoFirewall {
        +String id
        +String name
        +String rulesCount
    }

    class CivoRule {
        +String id
        +String? label
        +String? cidr
        +String? ports
    }

    class ManagedFirewall {
        +String id
        +String name
        +Int port
        +Bool enabled
    }

    class FirewallStatus {
        +ManagedFirewall managed
        +Bool isOpen
        +String? ruleId
    }

    class CivoKubernetesCluster {
        +String id
        +String name
        +String status
        +String? kubernetesVersion
        +String? masterIp
        +CivoNodePool[]? pools
        +CivoK8sApp[]? installedApplications
        +CivoK8sCondition[]? conditions
    }

    class CivoNodePool {
        +String id
        +Int? count
        +String? size
    }

    class CivoK8sApp {
        +String? name
        +String? version
    }

    class CivoK8sCondition {
        +String? type
        +String? status
        +Bool isHealthy
    }

    class CivoDatabase {
        +String id
        +String name
        +String status
        +String? software
        +String? publicIpv4
        +Int? port
    }

    class CivoNetwork {
        +String id
        +String? label
        +Bool? isDefault
        +String? status
    }

    class CivoVolume {
        +String id
        +String name
        +Int? sizeGb
        +String? status
    }

    class CivoObjectStore {
        +String id
        +String name
        +Int? maxSize
        +String? accessKeyId
        +String? secretAccessKey
    }

    class CivoLoadBalancer {
        +String id
        +String name
        +String? publicIp
        +String? state
    }

    class CivoInstance {
        +String id
        +String? hostname
        +String? status
    }

    class CivoRegion {
        +String code
        +String name
        +String? countryName
        +Bool? isDefault
    }

    class CivoQuota {
        +Int instanceCountLimit
        +Int instanceCountUsage
        +QuotaItem[] items
    }

    class CivoSize {
        +String name
        +String? description
        +Int? cpu
        +Int? ram
        +Int? disk
        +String? type
    }

    class CivoDiskImage {
        +String id
        +String? name
        +String? version
        +String? label
    }

    class CivoDomainRecord {
        +String id
        +String? name
        +String? type
        +String? value
        +Int? ttl
        +Int? priority
    }

    CivoKubernetesCluster --> CivoNodePool
    CivoKubernetesCluster --> CivoK8sApp
    CivoKubernetesCluster --> CivoK8sCondition
    CivoQuota --> QuotaItem
    FirewallStatus --> ManagedFirewall
    CivoDomain --> CivoDomainRecord
```

### Class Diagram — Services

```mermaid
classDiagram
    class CivoAPIClient {
        +get(path) T
        +getPaginatedList(path) T[]
        +getArray(path) T[]
        +post(path, body) T
        +put(path, body) T
        +delete(path)
        +validateAPIKey(key) Bool
    }

    class CivoConfig {
        +String apiKey (Keychain)
        +String region (UserDefaults)
    }

    class CivoFirewallService {
        +listFirewalls() CivoFirewall[]
        +createFirewall(body) CivoFirewall
        +removeFirewall(id)
        +getRulesForFirewall(id) CivoRule[]
        +openAccess(firewallId, port, ip, label)
        +closeAccess(firewallId, ruleId)
        +getStatus(managedFirewalls, currentIP) FirewallStatus[]
    }

    class CivoQuotaService { +getQuota() CivoQuota; +updateQuota(body) }
    class CivoKubernetesService { +listClusters(); +showCluster(id); +createCluster(body); +updateCluster(id, body); +removeCluster(id) }
    class CivoDatabaseService { +listDatabases(); +createDatabase(body); +removeDatabase(id) }
    class CivoNetworkService { +listNetworks(); +createNetwork(body); +updateNetwork(id, body); +removeNetwork(id) }
    class CivoVolumeService { +listVolumes(); +createVolume(body); +removeVolume(id) }
    class CivoObjectStoreService { +listObjectStores(); +createObjectStore(body); +removeObjectStore(id) }
    class CivoLoadBalancerService { +listLoadBalancers(); +removeLoadBalancer(id) }
    class CivoInstanceService { +listInstances(); +createInstance(body); +updateInstance(id, body); +removeInstance(id) }
    class CivoSSHKeyService { +listSSHKeys(); +createSSHKey(body); +removeSSHKey(id) }
    class CivoDomainService { +listDomains(); +createDomain(body); +updateDomain(id, body); +listRecords(id); +createRecord(id, body); +updateRecord(id, rid, body); +removeRecord(id, rid); +removeDomain(id) }
    class CivoRegionService { +listRegions() }
    class CivoSizeService { +listSizes(); +listDiskImages() }
    class IPDetector { +detectIP() String }

    CivoFirewallService --> CivoAPIClient
    CivoQuotaService --> CivoAPIClient
    CivoKubernetesService --> CivoAPIClient
    CivoDatabaseService --> CivoAPIClient
    CivoNetworkService --> CivoAPIClient
    CivoVolumeService --> CivoAPIClient
    CivoObjectStoreService --> CivoAPIClient
    CivoLoadBalancerService --> CivoAPIClient
    CivoInstanceService --> CivoAPIClient
    CivoSSHKeyService --> CivoAPIClient
    CivoDomainService --> CivoAPIClient
    CivoRegionService --> CivoAPIClient
    CivoSizeService --> CivoAPIClient
```

### Data Flow — Menu Bar Firewall

```mermaid
sequenceDiagram
    participant U as User
    participant M as MenuBarView
    participant S as AppState
    participant F as CivoFirewallService
    participant IP as IPDetector
    participant API as api.civo.com

    U->>M: Click shield icon
    M->>S: Show popover
    S->>IP: Detect public IP
    IP-->>S: 85.214.x.x
    S->>F: getStatus(managedFirewalls, currentIP)
    F->>API: GET /firewalls/{id}/rules?region=fra1
    API-->>F: [CivoRule]
    F-->>S: [FirewallStatus]
    S-->>M: Display status

    U->>M: Click "Open"
    M->>S: openFirewall(managed)
    S->>IP: Re-detect IP
    S->>F: openAccess(firewallId, port, ip, label)
    F->>API: POST /firewalls/{id}/rules
    API-->>F: Created
    S->>S: Force refresh
    S-->>M: Updated — yellow
```

### Data Flow — Dashboard

```mermaid
sequenceDiagram
    participant U as User
    participant MW as MainWindowView
    participant D as DashboardViewModel
    participant API as api.civo.com

    U->>MW: Click "Dashboard" in menu bar
    MW->>D: .task → refresh()

    par Quota
        D->>API: GET /quota
        API-->>D: CivoQuota
    and Kubernetes
        D->>API: GET /kubernetes/clusters?region=fra1
        API-->>D: {items: [...]}
    and Databases
        D->>API: GET /databases?region=fra1
        API-->>D: {items: [...]}
    and Volumes
        D->>API: GET /volumes?region=fra1
        API-->>D: [...]
    and Object Stores
        D->>API: GET /objectstores?region=fra1
        API-->>D: {items: [...]}
    and Load Balancers
        D->>API: GET /loadbalancers?region=fra1
        API-->>D: [...]
    and Networks
        D->>API: GET /networks?region=fra1
        API-->>D: [...]
    end

    D-->>MW: Quota gauges + clickable resource cards
    U->>MW: Click resource card
    MW->>MW: Navigate to sidebar section
```

### Data Flow — Create Resource

```mermaid
sequenceDiagram
    participant U as User
    participant LV as ListView
    participant VM as ViewModel
    participant SVC as Service
    participant API as api.civo.com

    U->>LV: Click "+" toolbar button
    LV->>LV: Present create sheet

    opt Load form data
        VM->>SVC: loadFormData()
        SVC->>API: GET /sizes, /networks, /firewalls
        API-->>SVC: Picker options
        SVC-->>VM: Populate pickers
    end

    U->>LV: Fill form → Click "Create"
    LV->>VM: createResource(body)
    VM->>SVC: create(body)
    SVC->>API: POST /resource
    API-->>SVC: Created resource
    SVC-->>VM: Success

    VM->>VM: Dismiss sheet
    VM->>VM: showSuccess = true
    VM->>SVC: refresh() — reload list
    LV->>LV: Show SuccessOverlay (1.5s)
```

### Data Flow — Kubernetes Detail

```mermaid
sequenceDiagram
    participant U as User
    participant CL as ClusterListView
    participant VM as KubernetesViewModel
    participant API as api.civo.com

    U->>CL: Select cluster
    CL->>VM: loadClusterDetail(id)
    VM->>API: GET /kubernetes/clusters/{id}?region=fra1
    API-->>VM: CivoKubernetesCluster (pools, apps, conditions)
    VM-->>CL: Show ClusterDetailView

    U->>CL: Click "Delete" → Confirmation
    CL->>VM: removeCluster(id)
    VM->>API: DELETE /kubernetes/clusters/{id}?region=fra1
    alt Success
        VM-->>CL: Navigate back
    else Failure
        VM-->>CL: Show error banner
    end
```

### Main Window Navigation

```mermaid
graph LR
    subgraph Sidebar
        OV[Overview]
        CO[Compute]
        KU[Kubernetes]
        NE[Networking]
        ST["Storage & Data"]
        AC[Account]
    end

    subgraph Detail
        OV --> DA[DashboardView]
        DA -->|click card| IL
        DA -->|click card| CL
        DA -->|click card| NL
        DA -->|click card| DBL
        DA -->|click card| VL
        DA -->|click card| OL
        DA -->|click card| LB
        CO --> IL[InstanceListView]
        CO --> SK[SSHKeyListView]
        KU --> CL[ClusterListView]
        CL -->|drill-down| CD[ClusterDetailView]
        NE --> NL[NetworkListView]
        NE --> FL[FirewallListView]
        FL -->|drill-down| FD[FirewallDetailView]
        NE --> LB[LoadBalancerListView]
        NE --> DL[DomainListView]
        ST --> DBL[DatabaseListView]
        ST --> VL[VolumeListView]
        ST --> OL[ObjectStoreListView]
        AC --> RL[RegionListView]
    end

    subgraph "Create Sheets"
        IL -.->|"+"| CI[CreateInstanceView]
        SK -.->|"+"| CS[CreateSSHKeyView]
        CL -.->|"+"| CC[CreateClusterView]
        NL -.->|"+"| CN[CreateNetworkView]
        FL -.->|"+"| CF[CreateFirewallView]
        FD -.->|"+"| CR[CreateRuleView]
        DL -.->|"+"| CDO[CreateDomainView]
        DL -.->|"+"| CDR[CreateDNSRecordView]
        DBL -.->|"+"| CDB[CreateDatabaseView]
        VL -.->|"+"| CV[CreateVolumeView]
        OL -.->|"+"| COS[CreateObjectStoreView]
    end

    subgraph "Edit Sheets"
        DA -.->|"Request Change"| QE[QuotaEditView]
    end

    style DA fill:#2563EB,color:#fff
    style CD fill:#10B981,color:#fff
    style QE fill:#F59E0B,color:#fff
```

---

## Civo API Reference

The app uses the [Civo REST API v2](https://www.civo.com/api). Authentication is via bearer token.

### Endpoint Response Formats

Some Civo API endpoints return paginated objects, others return plain arrays:

| Endpoint | HTTP Methods | Format | Region |
|----------|-------------|--------|--------|
| `/quota` | GET, PUT | Single `{}` | No |
| `/kubernetes/clusters` | GET, POST | Paginated `{items:[]}` | Yes |
| `/kubernetes/clusters/:id` | GET, PUT, DELETE | Single `{}` | Yes |
| `/databases` | GET, POST | Paginated `{items:[]}` | Yes |
| `/databases/:id` | DELETE | Single `{}` | Yes |
| `/instances` | GET, POST | Paginated `{items:[]}` | Yes |
| `/instances/:id` | PUT, DELETE | Single `{}` | Yes |
| `/objectstores` | GET, POST | Paginated `{items:[]}` | Yes |
| `/objectstores/:id` | DELETE | Single `{}` | Yes |
| `/firewalls` | GET, POST | Array `[]` | Yes |
| `/firewalls/:id` | DELETE | — | Yes |
| `/firewalls/:id/rules` | GET, POST | Array `[]` | Yes |
| `/firewalls/:id/rules/:rid` | DELETE | — | Yes |
| `/volumes` | GET, POST | Array `[]` | Yes |
| `/volumes/:id` | DELETE | — | Yes |
| `/loadbalancers` | GET | Array `[]` | Yes |
| `/loadbalancers/:id` | DELETE | — | Yes |
| `/networks` | GET, POST | Array `[]` | Yes |
| `/networks/:id` | PUT, DELETE | Single `{}` | Yes |
| `/regions` | GET | Array `[]` | No |
| `/sshkeys` | GET, POST | Array `[]` | No |
| `/sshkeys/:id` | DELETE | — | No |
| `/dns` | GET, POST | Array `[]` | No |
| `/dns/:id` | PUT, DELETE | — | No |
| `/dns/:id/records` | GET, POST | Array `[]` | No |
| `/dns/:id/records/:rid` | PUT, DELETE | — | No |
| `/sizes` | GET | Array `[]` | Yes |
| `/disk_images` | GET | Array `[]` | Yes |

### JSON Quirks

| Field | Expected | Actual | Handled |
|-------|----------|--------|---------|
| `rules_count` | Int | **String or Int** | Custom decoder |
| `cidr` | Array | **String or Array** | Custom decoder |
| `loadbalancer.Backends` | `backends` | **Capital B** (`Backends`) | CodingKey |
| `database.nodes` | Int | **Int** | Direct |
| `database.port` | Int | **Int** | Direct |

---

## Configuration

All settings are stored in UserDefaults under the `de.berger-rosenstock.CivoCloudManager` domain:

| Key | Storage | Description |
|-----|---------|-------------|
| API Key | **macOS Keychain** | Civo API key (encrypted) |
| `CivoCloudManager.region` | UserDefaults | Active region code (e.g. `fra1`) |
| `CivoCloudManager.managedFirewalls` | Data (JSON) | Selected firewalls with ports |
| `CivoCloudManager.launchAtLogin` | Bool | Auto-start on login |
| `CivoCloudManager.onboardingComplete` | Bool | Setup wizard completed |

---

## Testing

The project includes 21 decoding tests that verify all model types parse correctly against real Civo API responses.

```bash
swift test
```

```
✔ Test run with 21 tests in 1 suite passed after 0.001 seconds.
```

Tests cover:
- All 14 model types (quota, k8s cluster, database, firewall, rule, network, volume, object store, load balancer, instance, SSH key, domain, region, conditions)
- Both response formats (paginated `{items:[]}` and plain `[]`)
- Edge cases (CIDR as string vs array, Backends capital B, quota percentage calculation)
- CivoAccessLabel generation

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI (MenuBarExtra, Window, NavigationSplitView) |
| Platform | macOS 15+ |
| API | Civo REST API v2 via URLSession |
| IP Detection | ipify.org + ifconfig.me + icanhazip.com |
| Secrets | macOS Keychain (API key) |
| Persistence | UserDefaults (settings) |
| Purchases | StoreKit 2 (Non-Consumable) |
| Localization | String Catalog — 8 languages |
| Login | SMAppService |
| Logging | os.Logger (privacy: .private) |
| Dependencies | None (Apple frameworks only) |

---

## Project Structure

```
civo-cloud-manager/
├── project.yml                                # XcodeGen project definition
├── CivoCloudManager.xcodeproj/                # Xcode project (primary build)
├── Package.swift                              # SPM (tests only)
├── CivoCloudManager/
│   ├── Info.plist                              # App metadata + localizations
│   ├── CivoCloudManager.entitlements           # App Sandbox + network
│   ├── CivoCloudManager.storekit              # StoreKit test configuration
│   ├── Localizable.xcstrings                   # String catalog (8 languages)
│   ├── PrivacyInfo.xcprivacy                   # Apple privacy manifest
│   └── Assets.xcassets/                        # App icon + accent color
├── Sources/
│   ├── App/
│   │   └── CivoCloudManagerApp.swift           # @main — 3 scenes
│   ├── Models/
│   │   ├── CivoAccessLabel.swift               # Rule label generation
│   │   ├── FirewallRule.swift                   # CivoFirewall, CivoRule, ManagedFirewall, FirewallStatus
│   │   ├── CivoKubernetes.swift                # Cluster, NodePool, App, Condition
│   │   ├── CivoDatabase.swift
│   │   ├── CivoNetwork.swift
│   │   ├── CivoVolume.swift
│   │   ├── CivoObjectStore.swift               # + accessKeyId, secretAccessKey fields
│   │   ├── CivoLoadBalancer.swift
│   │   ├── CivoInstance.swift
│   │   ├── CivoSSHKey.swift
│   │   ├── CivoDomain.swift                    # + CivoDomainRecord
│   │   ├── CivoRegion.swift
│   │   ├── CivoQuota.swift                     # + QuotaItem (RAM/DB RAM in GB)
│   │   ├── CivoSize.swift                      # Instance/K8s/DB sizes
│   │   └── CivoDiskImage.swift                 # OS disk images for instances
│   ├── Services/
│   │   ├── CivoAPIClient.swift                 # HTTP client — GET, POST, PUT, DELETE
│   │   ├── CivoConfig.swift                    # API key (Keychain) + region
│   │   ├── CivoFirewallService.swift           # Firewall CRUD + rule management + removeFirewall
│   │   ├── CivoQuotaService.swift              # GET /quota + PUT /quota (change request)
│   │   ├── CivoKubernetesService.swift         # List, show, create, update, delete
│   │   ├── CivoDatabaseService.swift           # List, create, delete
│   │   ├── CivoNetworkService.swift            # List, create, update, delete (removeNetwork)
│   │   ├── CivoVolumeService.swift             # List, create, delete
│   │   ├── CivoObjectStoreService.swift        # List, create, delete
│   │   ├── CivoLoadBalancerService.swift       # List, delete
│   │   ├── CivoInstanceService.swift           # List, create, update, delete
│   │   ├── CivoSSHKeyService.swift             # List, create, delete
│   │   ├── CivoDomainService.swift             # Domains + records CRUD
│   │   ├── CivoRegionService.swift
│   │   ├── CivoSizeService.swift               # GET /sizes, GET /disk_images
│   │   ├── IPDetector.swift
│   │   └── StoreManager.swift                 # StoreKit 2 IAP ($14.99 lifetime)
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift
│   │   ├── KubernetesViewModel.swift           # + create/update, form data
│   │   ├── DatabaseViewModel.swift             # + create, form data
│   │   ├── NetworkViewModel.swift              # + create network/firewall, update, delete network/firewall/LB
│   │   ├── VolumeViewModel.swift               # + create volume/object store, cleanup unused
│   │   ├── InstanceViewModel.swift             # + create instance/SSH key, form data
│   │   ├── DomainViewModel.swift               # + create/update domain/record
│   │   └── RegionViewModel.swift
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   ├── AppState.swift
│   │   ├── OnboardingView.swift
│   │   ├── MainWindow/
│   │   │   ├── MainWindowView.swift             # NavigationSplitView + sidebar
│   │   │   ├── DashboardView.swift              # Clickable cards → sidebar nav
│   │   │   ├── QuotaEditView.swift              # Quota increase request form (steppers + PUT /quota)
│   │   │   ├── Compute/
│   │   │   │   ├── InstanceListView.swift       # + toolbar, sheet, overlay
│   │   │   │   ├── SSHKeyListView.swift         # + toolbar, sheet, overlay
│   │   │   │   ├── CreateInstanceView.swift     # Form: hostname, size, image, ...
│   │   │   │   └── CreateSSHKeyView.swift       # Form: name, public key
│   │   │   ├── Kubernetes/
│   │   │   │   ├── ClusterListView.swift        # + toolbar, sheet, overlay
│   │   │   │   ├── ClusterDetailView.swift
│   │   │   │   └── CreateClusterView.swift      # Form: name, CNI, nodes, apps
│   │   │   ├── Networking/
│   │   │   │   ├── NetworkListView.swift        # + toolbar, sheet, overlay, context delete
│   │   │   │   ├── FirewallListView.swift       # + drill-down to FirewallDetailView
│   │   │   │   ├── FirewallDetailView.swift     # Rule list with add/delete
│   │   │   │   ├── CreateRuleView.swift         # Form: protocol, ports, CIDR, direction, action
│   │   │   │   ├── LoadBalancerListView.swift   # + context delete
│   │   │   │   ├── DomainListView.swift         # + inline records, edit, delete
│   │   │   │   ├── CreateNetworkView.swift      # Form: label, CIDR
│   │   │   │   ├── CreateFirewallView.swift     # Form: name, network
│   │   │   │   ├── CreateDomainView.swift       # Form: domain name
│   │   │   │   └── CreateDNSRecordView.swift    # Form: type, name, value, TTL
│   │   │   ├── Storage/
│   │   │   │   ├── DatabaseListView.swift       # + toolbar, sheet, overlay
│   │   │   │   ├── VolumeListView.swift         # + toolbar, sheet, overlay
│   │   │   │   ├── ObjectStoreListView.swift    # + toolbar, sheet, overlay, show credentials
│   │   │   │   ├── CreateDatabaseView.swift     # Form: name, software, size, ...
│   │   │   │   ├── CreateVolumeView.swift       # Form: name, size, network
│   │   │   │   └── CreateObjectStoreView.swift  # Form: name, max size
│   │   │   └── Account/
│   │   │       └── RegionListView.swift
│   │   └── Shared/
│   │       ├── StatusBadge.swift
│   │       ├── QuotaGauge.swift
│   │       ├── ResourceListRow.swift
│   │       ├── EmptyStateView.swift
│   │       ├── ErrorBanner.swift
│   │       ├── SuccessOverlay.swift             # Green checkmark, spring auto-dismiss
│   │       ├── DeleteConfirmationSheet.swift   # Name-match confirmation for deletes
│   │       ├── StaggeredAppear.swift           # ViewModifier for staggered row animations
│   │       └── PaywallView.swift              # Buy-once paywall + ToS/Privacy links
│   └── Utilities/
│       └── Logger.swift
├── Tests/
│   └── APIDecodingTests.swift                  # 21 model decoding tests
├── README.md
├── CLAUDE.md
├── LICENSE
└── .gitignore
```

## License

Proprietary. Copyright (c) 2025-2026 Marcel R. G. Berger / Berger & Rosenstock GbR. All rights reserved. Distributed exclusively via the Apple App Store.
