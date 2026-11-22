import SwiftUI

struct HelpView: View {
    @State private var searchText = ""

    private var filteredSections: [HelpSection] {
        if searchText.isEmpty { return HelpSection.all }
        let query = searchText.lowercased()
        return HelpSection.all.filter { section in
            section.localizedTitle.lowercased().contains(query) ||
            section.localizedItems.contains { $0.lowercased().contains(query) }
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
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
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

    var localizedTitle: String {
        Bundle.main.localizedString(forKey: title, value: title, table: nil)
    }

    var localizedItems: [String] {
        items.map { Bundle.main.localizedString(forKey: $0, value: $0, table: nil) }
    }

    static let all: [HelpSection] = [
        HelpSection(title: "Getting Started", icon: "play.circle", items: [
            "The app runs as a menu bar icon (shield). Click it to open the popover.",
            "On first launch, the Setup Wizard guides you through API key, region, and firewall configuration.",
            "Enter your Civo API key (found at civo.com > Account > Security > API Keys).",
            "Select your region (e.g. fra1, lon1, nyc1).",
            "Choose which firewalls to manage and set the port for each.",
            "Click 'Dashboard' in the menu bar popover to open the full management window.",
            "Resource lists load every page from Civo. An orange notice means not all pages could be loaded and results may be missing; refresh to try again.",
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
            "Showing or copying the initial password requires Touch ID or the system password. It hides again after 30 seconds, when the app becomes inactive, and when the screen locks or the Mac sleeps.",
            "Right-click an instance to stop, start, soft reboot or hard reboot it via the context menu. Each of these actions asks for confirmation first.",
            "Create Instance stays disabled until hostname, size, disk image and network are set. The default network is preselected, and only firewalls of the selected network are offered.",
            "Advanced in Create Instance sets the number of instances (limited by the remaining quota), whether a public IP address is created, the initial user, the reverse DNS (prefilled with the hostname) and a startup script in a monospaced editor.",
            "Creating more than one instance asks for confirmation first and shows the estimated total cost per hour from your hourly rates. Public IP addresses are not included in the estimate.",
            "Without an SSH key, Civo sets an initial password. After creation, a notice says where to find it: on the instance's detail page under Security, after Touch ID or your system password. The notice never contains the password.",
            "Add SSH keys by pasting the public key.",
        ]),
        HelpSection(title: "Kubernetes", icon: "helm", items: [
            "Click a cluster to see details: version, API endpoint, conditions, node pools, apps.",
            "Click 'Upgrade...' on a cluster to move it to a newer Kubernetes version from Civo's list. Only newer versions are offered, since Civo does not support downgrades. Civo's own recommendation is preselected, and you confirm the current and the target version before anything is sent.",
            "Civo decides whether an upgrade path is allowed and may refuse it. After Civo accepts the request, the cluster shows the requested upgrade until it reports the new version; refresh to see its status. The app never upgrades a cluster on its own.",
            "When creating a cluster, pick a Kubernetes version or keep 'Civo default', which sends no version so Civo installs its default one.",
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
            "Right-click a rule and choose 'Edit Rule' to change its protocol, ports, CIDR, direction or label. The action cannot be changed. A comparison shows the values before and after.",
            "Saving loads the rule again first. A removed rule is not recreated, and a rule changed elsewhere is shown with its current values to save again. Allowing every address or changing the rule that admits your own IP asks for confirmation.",
            "Rules the app opens and closes itself, from the menu bar, a timer or the Kubernetes connection, show a lock and cannot be edited.",
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
            "Calendar boundaries use UTC rather than local time, so they can fall a few hours before or after local midnight. This Month, Last Quarter and This Year include the current month so far; Last Month covers the previous complete UTC month.",
            "Periods spanning several months are loaded month by month in UTC, Civo's billing time zone, and added up to one total without counting a month boundary twice.",
            "Last Quarter covers the three previous calendar months plus the current month so far.",
            "Completed months are cached locally per Civo account. The month that just ended is loaded again from Civo for 7 days after it ends; older completed months stay fixed. The current month and any month not cached yet are always loaded from Civo.",
            "Refresh loads every month of the selected period again from Civo, including completed months, and updates the cache.",
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
            "The 'Copy & Open Terminal' button copies the command for moving the key to ~/.ssh/ and opens Terminal.",
            "SSH command with key path shown in instance detail view.",
            "Backup button in SSH Keys toolbar: recover private keys from encrypted backup.",
            "'Export' restores a key from the app's backup storage to your chosen location.",
        ]),
        HelpSection(title: "Instance Management", icon: "desktopcomputer", items: [
            "Start, Stop and Reboot instances from the detail view. Reboot restarts the instance through its operating system; its menu also offers a hard reboot for an instance that no longer responds, which may lose unsaved data.",
            "Open Console opens the console of an active instance in its own window (Full Access). Log in with a password of a user on the instance.",
            "Closing the console window only disconnects you. 'End session' ends the console session on Civo for everyone.",
            "A console session is requested for one hour. If a session is already active, it is reused and may end sooner.",
            "The console scales the remote screen to the window, keeps its aspect ratio and follows when you resize the window.",
            "Above the console, the initial user and password reported by Civo are shown. The password stays masked until you show or copy it with Touch ID or your system password. If Civo reports no initial login, the console says so.",
            "A password changed later on the instance does not update the initial password shown by Civo. Save the current login as credentials instead.",
            "'Credentials…' saves a username and password per instance in this Mac's keychain only, without iCloud sync. Showing, copying and editing require Touch ID or your system password.",
            "Add, edit or delete saved credentials with 'Credentials' in the instance detail view or the instance list context menu, for running and stopped instances. An open edit closes after 30 seconds.",
            "Saved credentials are also shown in the console window so you can type them in. Copy and paste are not available in the console.",
            "Saved credentials hold only a username and a password. SSH keys and certificates are not stored there; manage SSH keys under SSH Keys.",
            "'Delete...' in the Actions & Metadata box deletes the instance permanently after you type its name, as in the list's context menu. Only after Civo confirmed the deletion is it logged and the page returns to the list. If it fails, the error is shown and the page stays open.",
            "Deleting an instance also deletes its saved credentials. If they cannot be removed, the app shows an error.",
            "Instance actions always go to the region the instance list was loaded from. If the region changes or the instance is no longer listed while a confirmation is open, the action is cancelled and nothing is sent.",
            "Resize instances with the visual size picker grid.",
            "'Change...' next to the firewall in the Security box switches the instance to another firewall of its network. A second confirmation follows; Full Access, the region and the firewall list are checked again before anything is sent. The new rules apply right away and can block SSH or other access.",
            "The Volumes box lists the volumes attached to the instance. 'Attach Volume...' offers only volumes that are not attached and are in the network and region of the instance; the volume then still has to be mounted on the instance; format it only if it is new and empty. 'Detach...' asks for confirmation; unmount the volume in the operating system of the instance first. Full Access, the region and the volume list are checked again before anything is sent.",
            "The Recovery Mode box shows whether recovery mode is on. 'Enter Recovery Mode...' boots an emergency operating system on the next reboot, so you can inspect and repair the boot volume; 'Exit Recovery Mode...' returns to the instance's own system on the next reboot. Both ask for confirmation, and Full Access and the region are checked again before anything is sent. Until a reboot is sent from this app, a warning stays in the box with 'Soft Reboot...' and 'Hard Reboot...'. While recovery mode is active, the instance can be reached only through the console; 'Open Console' appears once the instance is running.",
            "SSH access command with correct key path and copy button.",
            "Edit Reverse DNS inline.",
            "Edit tags inline in the Actions & Metadata box. Separate tags with commas; a tag cannot contain spaces. Saving never clears the tags: only 'Remove All Tags...' does that, after a confirmation.",
            "Filter the instance list by tag with the field above the list. The filter runs on this Mac and matches part of a tag, ignoring case.",
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
            "All features are free for seven elapsed days from first use.",
            "After the trial, a one-time Full Access purchase unlocks the dashboard. The price is shown before purchase.",
            "'Restore Purchase' recovers previous purchases. 'Redeem Code' for Apple offer codes.",
            "Family Sharing is enabled.",
        ]),
    ]
}
