import SwiftUI

struct QuotaEditView: View {
    @Bindable var vm: DashboardViewModel
    let currentQuota: CivoQuota

    @State private var instanceCount: Int
    @State private var cpuCores: Int
    @State private var ramGb: Int
    @State private var diskGb: Int
    @State private var volumes: Int
    @State private var publicIps: Int
    @State private var networks: Int
    @State private var loadBalancers: Int
    @State private var objectStoreGb: Int
    @State private var databases: Int
    @State private var dbCpuCores: Int
    @State private var dbRamGb: Int
    @State private var dbDiskGb: Int

    @State private var submitted = false

    init(vm: DashboardViewModel, currentQuota: CivoQuota) {
        self.vm = vm
        self.currentQuota = currentQuota
        _instanceCount = State(initialValue: currentQuota.instanceCountLimit)
        _cpuCores = State(initialValue: currentQuota.cpuCoreLimit)
        _ramGb = State(initialValue: currentQuota.ramMbLimit / 1024)
        _diskGb = State(initialValue: currentQuota.diskGbLimit)
        _volumes = State(initialValue: currentQuota.diskVolumeCountLimit)
        _publicIps = State(initialValue: currentQuota.publicIpAddressLimit)
        _networks = State(initialValue: currentQuota.networkCountLimit)
        _loadBalancers = State(initialValue: currentQuota.loadbalancerCountLimit)
        _objectStoreGb = State(initialValue: currentQuota.objectstoreGbLimit)
        _databases = State(initialValue: currentQuota.databaseCountLimit)
        _dbCpuCores = State(initialValue: currentQuota.databaseCpuCoreLimit)
        _dbRamGb = State(initialValue: currentQuota.databaseRamMbLimit / 1024)
        _dbDiskGb = State(initialValue: currentQuota.databaseDiskGbLimit)
    }

    private var changes: [(label: String, from: Int, to: Int)] {
        var result: [(String, Int, Int)] = []
        func check(_ label: String, old: Int, new: Int) {
            if old != new { result.append((label, old, new)) }
        }
        check("Instances", old: currentQuota.instanceCountLimit, new: instanceCount)
        check("CPU Cores", old: currentQuota.cpuCoreLimit, new: cpuCores)
        check("RAM (GB)", old: currentQuota.ramMbLimit / 1024, new: ramGb)
        check("Disk (GB)", old: currentQuota.diskGbLimit, new: diskGb)
        check("Volumes", old: currentQuota.diskVolumeCountLimit, new: volumes)
        check("Public IPs", old: currentQuota.publicIpAddressLimit, new: publicIps)
        check("Networks", old: currentQuota.networkCountLimit, new: networks)
        check("Load Balancers", old: currentQuota.loadbalancerCountLimit, new: loadBalancers)
        check("Object Store (GB)", old: currentQuota.objectstoreGbLimit, new: objectStoreGb)
        check("Database Count", old: currentQuota.databaseCountLimit, new: databases)
        check("DB CPU Cores", old: currentQuota.databaseCpuCoreLimit, new: dbCpuCores)
        check("DB RAM (GB)", old: currentQuota.databaseRamMbLimit / 1024, new: dbRamGb)
        check("DB Disk (GB)", old: currentQuota.databaseDiskGbLimit, new: dbDiskGb)
        return result
    }

    var body: some View {
        if submitted {
            successView
        } else {
            formView
        }
    }

    private var formView: some View {
        Form {
            Section("Compute") {
                quotaRow("Instances", value: $instanceCount, step: 1)
                quotaRow("CPU Cores", value: $cpuCores, step: 1)
                quotaRow("RAM (GB)", value: $ramGb, step: 1)
                quotaRow("Disk (GB)", value: $diskGb, step: 50)
            }

            Section("Networking") {
                quotaRow("Volumes", value: $volumes, step: 1)
                quotaRow("Public IPs", value: $publicIps, step: 1)
                quotaRow("Networks", value: $networks, step: 1)
                quotaRow("Load Balancers", value: $loadBalancers, step: 1)
            }

            Section("Storage") {
                quotaRow("Object Store (GB)", value: $objectStoreGb, step: 500)
            }

            Section("Databases") {
                quotaRow("Database Count", value: $databases, step: 1)
                quotaRow("DB CPU Cores", value: $dbCpuCores, step: 1)
                quotaRow("DB RAM (GB)", value: $dbRamGb, step: 1)
                quotaRow("DB Disk (GB)", value: $dbDiskGb, step: 50)
            }

            if let error = vm.quotaSaveError {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Request Quota Change")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { vm.isEditingQuota = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Send Request") {
                    Task { await sendRequest() }
                }
                .disabled(vm.isSavingQuota || changes.isEmpty)
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Quota Change Submitted")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(changes, id: \.label) { change in
                    HStack {
                        Text(change.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(change.from)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("\(change.to)")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(.quinary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("Done") { vm.isEditingQuota = false }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(minWidth: 400)
    }

    private func quotaRow(_ label: String, value: Binding<Int>, step: Int) -> some View {
        Stepper(value: value, in: 0...100000, step: step) {
            Text(verbatim: "\(label): \(value.wrappedValue)")
        }
    }

    private func sendRequest() async {
        let body: [String: Any] = [
            "instance_count_limit": instanceCount,
            "cpu_core_limit": cpuCores,
            "ram_mb_limit": ramGb * 1024,
            "disk_gb_limit": diskGb,
            "disk_volume_count_limit": volumes,
            "public_ip_address_limit": publicIps,
            "network_count_limit": networks,
            "loadbalancer_count_limit": loadBalancers,
            "objectstore_gb_limit": objectStoreGb,
            "database_count_limit": databases,
            "database_cpu_core_limit": dbCpuCores,
            "database_ram_mb_limit": dbRamGb * 1024,
            "database_disk_gb_limit": dbDiskGb,
        ]
        let success = await vm.requestQuotaChange(body)
        if success {
            withAnimation { submitted = true }
        }
    }
}
