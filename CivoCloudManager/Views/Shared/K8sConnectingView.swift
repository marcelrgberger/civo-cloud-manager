import SwiftUI

struct K8sConnectingView: View {
    @State private var step = 0
    @State private var pulse = false

    private let steps = [
        ("lock.shield", "Opening firewall..."),
        ("doc.text", "Fetching kubeconfig..."),
        ("key.horizontal", "Importing certificates..."),
        ("network", "Connecting to API server..."),
        ("chart.bar", "Loading metrics & workloads..."),
    ]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.3 : 0.6)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "helm")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(pulse ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: pulse)
            }

            VStack(spacing: 8) {
                Text("Connecting to Kubernetes API")
                    .font(.headline)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, stepInfo in
                    HStack(spacing: 8) {
                        if index < step {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else if index == step {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.quaternary)
                        }

                        Image(systemName: stepInfo.0)
                            .font(.caption)
                            .foregroundStyle(index <= step ? .primary : .tertiary)
                            .frame(width: 16)

                        Text(stepInfo.1)
                            .font(.caption)
                            .foregroundStyle(index <= step ? .secondary : .tertiary)

                        Spacer()
                    }
                    .animation(.spring(duration: 0.3), value: step)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            pulse = true
            advanceSteps()
        }
        .onDisappear {
            stepTask?.cancel()
        }
    }

    @State private var stepTask: Task<Void, Never>?

    private func advanceSteps() {
        stepTask?.cancel()
        stepTask = Task {
            for i in 1...steps.count {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                withAnimation { step = i }
            }
        }
    }
}
