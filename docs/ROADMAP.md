# Civo Cloud Manager — Feature Roadmap

The app version in development is **2.2.0** (`MARKETING_VERSION` in the Xcode project; release builds get their build number from Xcode Cloud). The tiers and the release plan below originated from a v2.0.1 comparison and are historical planning, not a verified description of current behavior or a release commitment. See [README](../README.md) for current architecture and capabilities.

Completed reliability work: Kubernetes TLS validation, explicit request-region routing, persistent timed firewall closures and SSH encryption-key preservation. Remaining architecture work is tracked in the README under persistence and current limits.

## Implemented in 2.2.0

This is the delivered 2.2.0 scope (release ticket #72). It was not planned in the historical release plan below.

| Ticket | Change |
|--------|--------|
| #71 | In-app instance console for active instances (Full Access), one-hour sessions, local close versus End session, Reconnect |
| #83 | Console scaled to the window, initial user and password shown in the console window |
| #102 | Initial password shown or copied only after Touch ID or the system password, in the detail view and the console |
| #81 | Cost estimates for Last Month, Last Quarter and This Year split into UTC calendar-month requests, with a per-account cache of completed months |
| #103 | Per-instance credential vault for a username and a password in this Mac's keychain, without iCloud sync |

---

## Tier 1 — Quick Wins (small scope, clear gaps)

| Feature | Endpoints | UI | Effort | Impact |
|---------|-----------|----|--------|--------|
| **Volume Resize** | `PUT /v2/volumes/:id/resize` | Sheet on VolumeDetailView | S | High |
| Instance Hard Reboot | `POST /v2/instances/:id/hard_reboots` | Action menu | XS | Medium |
| API Key show / copy | local | Action in About / Settings | XS | Low |

## Tier 2 — Feature Modules (full sub-features, ~1 day)

| Feature | Endpoints | UI | Effort | Impact |
|---------|-----------|----|--------|--------|
| **Instance Snapshots** | list / create / show / restore / remove | Section in InstanceDetail + 3 sheets | M | High |
| **Reserved IPs** | list / create / assign / unassign / remove | New nav item | M | Medium |
| **Load Balancer Create + Backends** | Implemented in #120: `POST /v2/loadbalancers`, `PUT /v2/loadbalancers/:id`; backends are part of the load balancer, no endpoints of their own | Create sheet with backend table; editor for name, algorithm, a reported traffic policy and added backends. Removing or changing existing backends is not offered yet, since Civo does not document whether an update replaces the list | M | Medium |
| **K8s Node-Pools (dedicated)** | create / scale / list / delete | Extension in ClusterDetail | M | High (K8s users) |
| K8s Marketplace Apps | list / install | Browser + install sheet | M | Medium |

## Tier 3 — Major Features (multiple days)

| Feature | Notes | Effort | Impact |
|---------|-------|--------|--------|
| Instance Console (VNC) | Implemented in #71: Civo-hosted noVNC in a `WKWebView`, no RFB code in the app | M | High |
| Multi-API-Key Account Switcher | CivoConfig refactor | L | Medium |
| Teams & Permissions | B2B feature | L | Low |
| Recovery Mode for Instances | Edge case | M | Low |

---

## Historical Release Plan

Kept as written at planning time. The TBD rows were never filled in; the implemented 2.2.0 scope is listed under [Implemented in 2.2.0](#implemented-in-220).

| Version | Feature |
|---------|---------|
| **2.1.0** | Volume Resize (historical plan) |
| 2.2.0 | TBD (historical plan) |
| 2.3.0 | TBD |

---

## What is App-only (no CLI parity needed)

The app already exceeds the CLI in these areas — no roadmap items needed:

- K8s workload management (pods, logs, exec, metrics, labels, deployments, configmaps, secrets, PVCs, events)
- S3 browser for Object Stores (Get/Put/Delete via SigV4)
- Pause / Resume to vault bucket
- Cost dashboard with Charges API + custom rates
- Auto-firewall: IP detection, one-click rules, auto open/close for K8s API
- API health monitor, quick search ⌘K, sparklines, CSV/JSON export
- Touch ID protection, activity log, 16-language localization
