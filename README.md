# Civo Cloud Manager

macOS menu bar app for **Civo Cloud** — manage firewall access rules for your current IP with one click. Auto-discovers firewalls from your account, configurable ports, onboarding wizard, launch at login.

## Features

- **Auto-discover firewalls** from your Civo account (no hardcoded config)
- **One-click access** — open/close firewall rules for your current public IP
- **Open All / Close All** — bulk manage all configured firewalls
- **Per-firewall port config** — set which port to open for each firewall
- **Auto-detect IP** — detects your public IPv4 via ipify.org
- **Auto-refresh** — checks status every 60 seconds
- **Onboarding wizard** — guides through CLI install, authentication, firewall selection
- **Launch at Login** — starts automatically via SMAppService
- **Menu bar only** — no Dock icon, minimal footprint
- **Rule ownership** — only manages rules created by this app (`civo-cloud-*` prefix)

## Requirements

- **macOS 15+** (Sequoia / Tahoe)
- **Civo CLI** installed and authenticated

```bash
brew install civo
civo apikey save YOUR_API_KEY --name default
civo region use fra1  # or your preferred region
```

## Installation

### Build from source

```bash
git clone https://github.com/marcelrgberger/civo-cloud-manager.git
cd civo-cloud-manager
swift build
.build/debug/CivoCloudManager
```

### Open in Xcode

```bash
open Package.swift
# Then Cmd+R to build and run
```

## Usage

1. **First launch** — the onboarding wizard checks prerequisites and discovers your firewalls
2. **Select firewalls** — choose which firewalls to manage and set the port for each
3. **Click the shield icon** in the menu bar to open the popover
4. **Open/Close** individual firewalls or use bulk actions
5. Status updates automatically every 60 seconds

### Menu Bar Icons

| Icon | Meaning |
|------|---------|
| 🟢 Shield | All firewalls closed |
| 🟡 Shield | Some firewalls open for your IP |
| 🔴 Shield | Error (CLI missing, auth failed) |

## Architecture

```mermaid
graph TB
    subgraph macOS Menu Bar App
        A[CivoCloudManagerApp] --> B[MenuBarView]
        A --> C[OnboardingView]
        B --> D[AppState]
    end

    D --> E[CivoAdapter]
    D --> F[IPDetector]

    E -->|civo CLI| G[Civo Cloud API]
    F -->|HTTPS| H[ipify.org]

    subgraph Civo Operations
        G --> I[Firewall Rules]
        G --> J[Firewall Discovery]
        G --> K[Auth / Region]
    end

    style G fill:#7C3AED,color:#fff
    style H fill:#0EA5E9,color:#fff
```

### Data Flow

```mermaid
sequenceDiagram
    participant U as User
    participant M as Menu Bar
    participant S as AppState
    participant C as CivoAdapter
    participant IP as IPDetector
    participant API as Civo API

    U->>M: Click shield icon
    M->>S: Show popover
    S->>IP: Detect public IP
    IP-->>S: 85.214.x.x
    S->>C: Get firewall status
    C->>API: civo firewall rule ls (per firewall)
    API-->>C: Rules JSON
    C-->>S: FirewallStatus[]
    S-->>M: Display status

    U->>M: Click "Open"
    M->>S: openFirewall(fw)
    S->>C: civo firewall rule create
    C->>API: Add rule IP/32 → port
    API-->>C: Success
    S->>S: Refresh status
    S-->>M: Updated - yellow = open

    U->>M: Click "Close All"
    M->>S: closeAll()
    S->>C: Remove all civo-cloud rules
    C->>API: civo firewall rule remove per rule
    S-->>M: Updated - green = closed
```

### Components

```mermaid
graph LR
    subgraph Sources
        A[App] --> B[Views]
        B --> C[Services]
        C --> D[Utilities]
        B --> E[Models]
    end

    A --- A1[CivoCloudManagerApp]
    B --- B1[MenuBarView]
    B --- B2[AppState]
    B --- B3[OnboardingView]
    C --- C1[CivoAdapter]
    C --- C2[IPDetector]
    D --- D1[ProcessRunner]
    E --- E1[FirewallRule Models]
```

## How It Works

1. **IPDetector** resolves your public IPv4 via `api.ipify.org` (with fallbacks)
2. **CivoAdapter** wraps the `civo` CLI — discovers firewalls, lists rules, creates/removes rules
3. **AppState** coordinates IP detection + firewall status into a unified view model
4. **MenuBarView** renders the popover with per-firewall Open/Close buttons
5. **OnboardingView** guides first-time setup (CLI install, auth, firewall selection)

### Rule Ownership

The app only manages rules it created. Rules are labeled with:

```
civo-cloud-<hostname>-<firewall-name>
```

Example: `civo-cloud-Marcels-MacBook-Pro-fw-cluster`

This ensures the app never touches rules created by other users or tools.

## Configuration

Settings are persisted in UserDefaults:

| Key | Description |
|-----|-------------|
| `CivoCloudManager.managedFirewalls` | JSON array of selected firewalls with ports |
| `CivoCloudManager.launchAtLogin` | Boolean, default true |
| `CivoCloudManager.onboardingComplete` | Boolean |

## Project Structure

```
civo-cloud-manager/
├── Package.swift
├── Sources/
│   ├── Info.plist
│   ├── App/
│   │   └── CivoCloudManagerApp.swift
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   ├── AppState.swift
│   │   └── OnboardingView.swift
│   ├── Services/
│   │   ├── CivoAdapter.swift
│   │   └── IPDetector.swift
│   ├── Models/
│   │   └── FirewallRule.swift
│   └── Utilities/
│       ├── ProcessRunner.swift
│       └── Logger.swift
├── README.md
├── LICENSE
└── .gitignore
```

## License

MIT
