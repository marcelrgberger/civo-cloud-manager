# Civo Access Manager

macOS menu bar app for managing Civo firewall access rules. Wraps the `civo` CLI to open and close firewall rules for your current public IP address.

## Features

- Detect current public IP automatically
- Open/close firewall access per firewall or all at once
- Monitor which firewalls are currently open
- Auto-refresh status every 60 seconds
- Menu bar icon with color-coded status (green = all closed, yellow = some open, red = error)

## Managed Firewalls

| Firewall     | Port | Purpose              |
|-------------|------|----------------------|
| fw-cluster  | 6443 | Kubernetes API       |
| fw-db-dev   | 5432 | Development Database |
| fw-db-prod  | 5432 | Production Database  |

## Prerequisites

- macOS 15.0+
- [civo CLI](https://github.com/civo/cli) installed and authenticated
- Swift 6.0+

## Build & Run

```bash
swift build
swift run CivoAccessManager
```

## Install

```bash
swift build -c release
cp .build/release/CivoAccessManager /usr/local/bin/
```

## Architecture

```
Sources/
├── App/
│   └── CivoAccessManagerApp.swift      # @main, MenuBarExtra
├── Views/
│   ├── AppState.swift                  # @Observable state management
│   └── MenuBarView.swift               # Main popover content
├── Services/
│   ├── CivoAdapter.swift               # Wraps civo CLI
│   └── IPDetector.swift                # Detects public IP
├── Models/
│   └── FirewallRule.swift              # Data models
└── Utilities/
    ├── ProcessRunner.swift             # Async process execution
    └── Logger.swift                    # os.Logger wrapper
```
