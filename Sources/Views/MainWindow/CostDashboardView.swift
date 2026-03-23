import SwiftUI

struct CostDashboardView: View {
    let instanceVM: InstanceViewModel
    let kubernetesVM: KubernetesViewModel
    let databaseVM: DatabaseViewModel
    let volumeVM: VolumeViewModel

    private var costItems: [CostItem] {
        var items: [CostItem] = []

        // Instances
        for instance in instanceVM.instances {
            let monthlyCost = estimateInstanceCost(cpuCores: instance.cpuCores ?? 0, ramMb: instance.ramMb ?? 0)
            items.append(CostItem(
                name: instance.hostname ?? instance.id,
                type: "Instance",
                icon: "desktopcomputer",
                iconColor: .green,
                monthlyCost: monthlyCost
            ))
        }

        // Kubernetes clusters (per node)
        for cluster in kubernetesVM.clusters {
            let nodeCount = cluster.pools?.reduce(0, { $0 + ($1.count ?? 0) }) ?? 0
            let monthlyCost = estimateK8sCost(nodeCount: nodeCount, size: cluster.pools?.first?.size ?? "")
            items.append(CostItem(
                name: cluster.name ?? cluster.id,
                type: "Kubernetes",
                icon: "helm",
                iconColor: .blue,
                monthlyCost: monthlyCost
            ))
        }

        // Databases
        for db in databaseVM.databases {
            let nodes = db.nodes ?? 1
            let monthlyCost = Double(nodes) * 15.0
            items.append(CostItem(
                name: db.name ?? db.id,
                type: "Database",
                icon: "cylinder.split.1x2",
                iconColor: .purple,
                monthlyCost: monthlyCost
            ))
        }

        // Volumes
        for volume in volumeVM.volumes {
            let sizeGb = volume.sizeGb ?? 0
            let monthlyCost = Double(sizeGb) * 0.10
            items.append(CostItem(
                name: volume.name ?? volume.id,
                type: "Volume",
                icon: "cylinder",
                iconColor: .orange,
                monthlyCost: monthlyCost
            ))
        }

        // Object Stores
        for store in volumeVM.objectStores {
            let maxSize = store.maxSize ?? 500
            let monthlyCost = Double(maxSize) / 1000.0 * 5.0
            items.append(CostItem(
                name: store.name ?? store.id,
                type: "Object Store",
                icon: "tray.2",
                iconColor: .cyan,
                monthlyCost: monthlyCost
            ))
        }

        return items.sorted { $0.monthlyCost > $1.monthlyCost }
    }

    private var totalMonthlyCost: Double {
        costItems.reduce(0) { $0 + $1.monthlyCost }
    }

    private var costByType: [(type: String, cost: Double, color: Color)] {
        let grouped = Dictionary(grouping: costItems, by: \.type)
        return grouped.map { (type: $0.key, cost: $0.value.reduce(0) { $0 + $1.monthlyCost }, color: $0.value.first?.iconColor ?? .gray) }
            .sorted { $0.cost > $1.cost }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Total
                GroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Estimated Monthly Cost")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(totalMonthlyCost, specifier: "%.2f") / month")
                                .font(.title.bold())
                        }
                        Spacer()
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                    }
                }

                // Breakdown by type
                GroupBox("Cost by Resource Type") {
                    VStack(spacing: 8) {
                        ForEach(costByType, id: \.type) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                Text(item.type)
                                    .font(.callout)
                                Spacer()
                                Text("$\(item.cost, specifier: "%.2f")")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(4)
                }

                // Individual resources
                GroupBox("All Resources") {
                    VStack(spacing: 2) {
                        ForEach(costItems) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .foregroundStyle(item.iconColor)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name)
                                        .font(.callout)
                                    Text(item.type)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Text("$\(item.monthlyCost, specifier: "%.2f")/mo")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding(4)
                }

                Text("Estimates based on Civo standard pricing. Actual charges may vary.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
        .navigationTitle("Cost Estimate")
    }

    // MARK: - Cost Estimation

    private func estimateInstanceCost(cpuCores: Int, ramMb: Int) -> Double {
        // Civo pricing: roughly $5/mo per vCPU + $2.50/GB RAM
        Double(cpuCores) * 5.0 + Double(ramMb) / 1024.0 * 2.50
    }

    private func estimateK8sCost(nodeCount: Int, size: String) -> Double {
        // Base K8s management fee + per-node cost
        // Small nodes ~$10, medium ~$20, large ~$40
        let perNode: Double
        if size.contains("small") { perNode = 10.0 }
        else if size.contains("large") || size.contains("xlarge") { perNode = 40.0 }
        else { perNode = 20.0 }
        return Double(nodeCount) * perNode
    }
}

private struct CostItem: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let icon: String
    let iconColor: Color
    let monthlyCost: Double
}
