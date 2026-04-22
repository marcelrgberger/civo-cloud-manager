import SwiftUI

struct HelpView: View {
    @State private var searchText = ""

    private var filteredSections: [HelpSection] {
        if searchText.isEmpty { return HelpSection.all }
        let query = searchText.lowercased()
        return HelpSection.all.filter { section in
            section.title.lowercased().contains(query) ||
            section.items.contains { $0.lowercased().contains(query) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                ForEach(Array(filteredSections.enumerated()), id: \.element.title) { index, section in
                    sectionView(section)
                        .modifier(StaggeredAppear(index: index))
                }
            }
            .padding(24)
        }
        .searchable(text: $searchText, prompt: "Search Help")
        .navigationTitle("Help")
        .frame(minWidth: 500, minHeight: 400)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Civo Cloud Manager")
                        .font(.title.bold())
                    Text("Help & Documentation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func sectionView(_ section: HelpSection) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                        Text(LocalizedStringKey(item))
                            .font(.callout)
                    }
                }
            }
            .padding(4)
        } label: {
            Label(LocalizedStringKey(section.title), systemImage: section.icon)
                .font(.headline)
        }
    }
}

struct HelpSection {
    let title: String
    let icon: String
    let items: [String]

    static let all: [HelpSection] = [
        HelpSection(title: "Getting Started", icon: "play.circle", items: [
            "The app runs as a menu bar icon (shield). Click it to open the popover.",
            "On first launch, the Setup Wizard guides you through API key, region, and firewall configuration.",
            "Enter your Civo API key (found at civo.com > Account > Security > API Keys).",
            "Select your region (e.g. fra1, lon1, nyc1).",
            "Choose which firewalls to manage and set the port for each.",
            "Click 'Dashboard' in the menu bar popover to open the full management window.",
        ]),
        HelpSection(title: "Menu Bar", icon: "menubar.rectangle", items: [
            "Green shield: All firewalls closed.",
            "Yellow shield: Some firewalls open for your IP.",
            "Red shield: Setup not complete.",
            "'Open' creates a firewall rule allowing your current public IP.",
            "'Close' removes the rule. 'Open All / Close All' for bulk actions.",
            "Your public IP is auto-detected. The app only manages rules it created.",
        ]),
        HelpSection(title: "Dashboard", icon: "gauge.with.dots.needle.33percent", items: [
            "Resource cards are clickable — navigate directly to any section.",
            "Quota gauges show usage vs. limits (RAM and DB RAM displayed in GB).",
            "'Request Change' opens a form to request quota limit adjustments.",
        ]),
        HelpSection(title: "Compute & Instances", icon: "desktopcomputer", items: [
            "Click an instance to see CPU, RAM, Disk specs, IPs, initial password, and tags.",
            "Initial password has a show/hide toggle for security.",
            "Right-click an instance to Stop, Start, or Reboot it via the context menu.",
            "Add SSH keys by pasting the public key.",
        ]),
        HelpSection(title: "Kubernetes", icon: "helm", items: [
            "Click a cluster to see details: version, API endpoint, conditions, node pools, apps.",
            "The K8s API connects automatically when you select a cluster (no manual button needed).",
            "An animated progress view shows 5 connection steps: firewall, kubeconfig, certificates, API server, metrics.",
            "The app auto-opens port 6443 on the cluster firewall for your IP.",
            "Use the Namespace filter picker to show only deployments and services in a specific namespace.",
            "Workloads (Deployments, DaemonSets, StatefulSets, CronJobs) are in a collapsible section.",
            "Networking (Services, Ingresses) and Storage (PVCs, PVs) are also collapsible.",
            "Scale deployments up or down directly from the cluster detail view.",
            "Events show relative timestamps like '2m ago' or '1h ago'.",
            "PVCs show linked Civo Volume IDs. PVs list capacity and Civo Volume ID.",
            "Click a node name to see CPU, Memory, Pods capacity, conditions, and system info.",
            "'View Pods on this Node' shows all pods with status and restart count.",
            "Right-click a pod and select 'Restart Pod' to delete and restart it.",
            "Click a pod to view its logs (scrollable, auto-scroll toggle, refresh).",
            "Toggle 'Auto-Refresh' to have pod logs update every 3 seconds automatically.",
            "'Save Kubeconfig' exports the kubeconfig as a .yaml file.",
            "Node pool labels can be edited (add/remove) via the Edit button.",
        ]),
        HelpSection(title: "Networking", icon: "point.3.connected.trianglepath.dotted", items: [
            "Click a firewall to see all its rules (protocol, ports, CIDR, direction, action).",
            "Add new rules with '+' in the rule detail view.",
            "Create networks with a label and optional CIDR range.",
            "Default network cannot be deleted.",
            "Expand a domain to see DNS records. Add, edit, or delete records inline.",
            "Load balancers show algorithm, IPs, traffic policy, and backend list.",
        ]),
        HelpSection(title: "Database Credentials", icon: "lock.shield", items: [
            "Click a database to see its detail view with connection info, config, and credentials.",
            "The username is displayed directly in the Credentials section.",
            "The password is protected — tap the eye icon to reveal it via Touch ID or system password.",
            "Authentication uses the system's LocalAuthentication framework (same as unlocking your Mac).",
        ]),
        HelpSection(title: "Credential Management", icon: "key.horizontal", items: [
            "The 'Credentials' section in the sidebar (under Storage & Data) manages Object Store credentials.",
            "View all credentials with access key ID and status.",
            "Secret access keys are hidden by default — reveal them via Touch ID or system password.",
            "Create new credentials by entering a name and clicking 'Create'.",
            "Delete credentials via right-click context menu (requires typing the name to confirm).",
            "Hover over a credential row for a visual animation (key icon rotation + orange highlight).",
            "When creating a new Object Store, you can pick from existing credentials.",
        ]),
        HelpSection(title: "Storage & Data", icon: "cylinder.split.1x2", items: [
            "Click a database to see connection info (host, port, DNS), credentials, config, and network.",
            "Click a volume to see attachment status, size, mountpoint, and bootable flag.",
            "'Cleanup Available' deletes all volumes with status 'available' (requires typing DELETE ALL DATA).",
            "Click an object store to see its credentials, endpoint, config, and resize option.",
            "Object store size can be changed via the stepper in the detail view.",
            "Credentials (access key ID, secret access key) come from a linked credential via the Civo API.",
            "Click 'Browse Files' in the object store detail view to open the S3 file browser.",
            "**Pause/Resume**: Right-click an object store and select 'Pause' to archive it and save costs.",
            "Pausing copies all files to a central vault store, verifies the copy, then deletes the original.",
            "Paused stores appear in a separate section with an orange icon and a 'Resume' button.",
            "Resuming recreates the store with the same name and credentials, then restores all files.",
            "A progress sheet shows live file counts, byte counters, and the current file being copied.",
            "Enable the Pause feature by clicking 'Enable' in the banner at the top of the Object Store list.",
            "The vault ('civo-cloud-manager') auto-resizes as needed and shrinks after resume.",
            "If a paused store is missing its credential, the Resume button lets you select an existing credential or create a new one.",
        ]),
        HelpSection(title: "S3 File Browser", icon: "folder.fill", items: [
            "Browse files and folders in a Table view with Name and Size columns.",
            "Click a folder to select, double-click to navigate into it.",
            "Select files/folders with Click, Cmd+Click, or Shift+Click.",
            "Download selected items via the toolbar Download button.",
            "Single file: choose where to save, opens Finder with file selected.",
            "Multiple files/folders: choose a folder, downloads all recursively, opens Finder.",
            "Cancel button in the download bar stops the current download.",
            "Breadcrumb navigation shows your path. Click any breadcrumb to jump back.",
        ]),
        HelpSection(title: "Quick Search", icon: "magnifyingglass", items: [
            "Press ⌘K anywhere to open Quick Search.",
            "Search across all resources by name: clusters, instances, databases, etc.",
            "Arrow keys to navigate results, Enter to jump to that section, Esc to close.",
        ]),
        HelpSection(title: "Cost Estimate", icon: "dollarsign.circle", items: [
            "Shows actual charges from the Civo billing API.",
            "Period picker: This Month, Last Month, Last Quarter, This Year.",
            "This Month shows actual cost + projected monthly estimate.",
            "Breakdown by resource type with percentage bars.",
            "Breakdown by individual resource with usage hours.",
            "'Edit Rates' lets you customize hourly pricing if needed.",
            "Past months are cached locally for faster loading.",
        ]),
        HelpSection(title: "API Health", icon: "waveform.path.ecg", items: [
            "Tests all 16 Civo API endpoints with response time.",
            "Green checkmark = OK, red X = unavailable.",
            "Response time color: green <200ms, orange <500ms, red >500ms.",
            "Auto-checks when opened, refresh button for manual test.",
        ]),
        HelpSection(title: "Export & Backup", icon: "square.and.arrow.up", items: [
            "Press ⌘⇧E to export resources as JSON backup.",
            "Select which resource types to include.",
            "Sensitive fields (passwords, keys) are automatically redacted.",
            "File opens in Finder for you to save or share.",
        ]),
        HelpSection(title: "IP Presets & Auto-Close", icon: "timer", items: [
            "Save named IP addresses (Home, Office) in the menu bar popover.",
            "One-click open any firewall with a saved IP.",
            "Auto-close timer: set 15min, 30min, 1h, 2h, or unlimited.",
            "Remaining time shown next to open firewalls.",
            "Rules auto-close when the timer expires.",
        ]),
        HelpSection(title: "SSH Key Generation", icon: "key", items: [
            "Generate Ed25519 SSH key pairs directly from the app.",
            "Private key saved to your chosen location and encrypted backup stored in the app.",
            "Public key uploaded to Civo when you click Create.",
            "'Move to ~/.ssh/' button copies the command and opens Terminal.",
            "SSH command with key path shown in instance detail view.",
            "Backup button in SSH Keys toolbar: recover private keys from encrypted backup.",
            "'Export' restores a key from the app's backup storage to your chosen location.",
        ]),
        HelpSection(title: "Instance Management", icon: "desktopcomputer", items: [
            "Start, Stop, Reboot instances from the detail view.",
            "Resize instances with the visual size picker grid.",
            "SSH access command with correct key path and copy button.",
            "Edit Reverse DNS inline.",
            "Activity log shows recent actions with timestamps.",
            "Auto-refresh while instance is building (every 5 seconds).",
        ]),
        HelpSection(title: "Deleting Resources", icon: "trash", items: [
            "All delete operations require typing the exact resource name to confirm.",
            "This prevents accidental deletion of critical cloud infrastructure.",
            "Right-click any resource and select 'Delete' to start.",
        ]),
        HelpSection(title: "Full Access", icon: "cart", items: [
            "Menu bar firewall management is free.",
            "Full Access ($14.99 one-time) unlocks the dashboard and all resource management.",
            "'Restore Purchase' recovers previous purchases. 'Redeem Code' for Apple offer codes.",
            "Family Sharing is enabled.",
        ]),
    ]
}
