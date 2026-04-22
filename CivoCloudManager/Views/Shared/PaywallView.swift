import SwiftUI

struct PaywallView: View {
    @State private var store = StoreManager.shared
    @State private var appeared = false

    private let features: [(icon: String, text: String)] = [
        ("gauge.with.dots.needle.33percent", "Dashboard with quota overview"),
        ("helm", "Kubernetes cluster management"),
        ("cylinder.split.1x2", "Database management"),
        ("point.3.connected.trianglepath.dotted", "Network, firewall & load balancer views"),
        ("cylinder", "Volume & object store management"),
        ("desktopcomputer", "Instance & SSH key management"),
        ("map", "Region switching"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)
                header
                featureList
                purchaseSection
                actionButtons
                legalLinks
                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
        }
        .task {
            await store.loadProducts()
            await store.refreshPurchaseStatus()
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Civo Cloud Manager Pro")
                .font(.largeTitle.bold())

            Text("Unlock full access to all Civo Cloud resources")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    Text(feature.text)
                        .font(.body)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green.opacity(0.7))
                        .font(.caption)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -10)
                .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: appeared)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 8) {
            if store.isLoading {
                ProgressView()
                    .controlSize(.large)
            } else if let product = store.products.first {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Unlock for \(product.displayPrice)")
                            .font(.headline)
                        Text("— one-time purchase")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: 400)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                // Fallback when products can't be loaded (no StoreKit config or network issue)
                Button {
                    Task { await store.loadProducts() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Unlock Full Access")
                            .font(.headline)
                    }
                    .frame(maxWidth: 400)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let error = store.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.4), value: appeared)
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 24) {
            Button {
                Task { await store.restorePurchases() }
            } label: {
                Label("Restore Purchase", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.subheadline)

            Button {
                store.redeemPromoCode()
            } label: {
                Label("Redeem Code", systemImage: "ticket")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.subheadline)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.5), value: appeared)
    }

    // MARK: - Legal (Apple Guideline 3.1.2)

    @Environment(\.openWindow) private var openWindow

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Button("Terms of Use") {
                openWindow(id: "legal")
            }
            .buttonStyle(.plain)
            Text("·").foregroundStyle(.tertiary)
            Button("Privacy Policy") {
                openWindow(id: "legal")
            }
            .buttonStyle(.plain)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.6), value: appeared)
    }
}

// MARK: - Free Mode Banner

struct FreeModeBanner: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text("Free — Menu bar only")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Upgrade") {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "main")
                NSApp.activate()
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
