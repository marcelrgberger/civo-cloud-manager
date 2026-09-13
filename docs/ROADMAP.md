# Civo Cloud Manager — Feature Roadmap

Current app version: **2.1.2 (build 19)**. The feature backlog below originated from a v2.0.1 comparison and is historical planning, not a verified description of current behavior or a release commitment. See [README](../README.md) for current architecture and capabilities.

Completed reliability work: Kubernetes TLS validation, explicit request-region routing, persistent timed firewall closures and SSH encryption-key preservation. Remaining architecture work is tracked in the README under persistence and current limits.

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
| **Load Balancer Create + Backends** | create LB, CRUD backends | CreateLB form + backend editor | M | Medium |
| **K8s Node-Pools (dedicated)** | create / scale / list / delete | Extension in ClusterDetail | M | High (K8s users) |
| K8s Marketplace Apps | list / install | Browser + install sheet | M | Medium |

## Tier 3 — Major Features (multiple days)

| Feature | Notes | Effort | Impact |
|---------|-------|--------|--------|
| Instance Console (VNC) | WebSocket + RFB protocol | XL | High |
| Multi-API-Key Account Switcher | CivoConfig refactor | L | Medium |
| Teams & Permissions | B2B feature | L | Low |
| Recovery Mode for Instances | Edge case | M | Low |

---

## Historical Release Plan

| Version | Feature |
|---------|---------|
| **2.1.0** | Volume Resize (historical plan) |
| 2.2.0 | TBD |
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
- Touch ID protection, activity log, 8-language localization
