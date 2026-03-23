import SwiftUI

struct PodExecView: View {
    let pod: K8sPod
    @Bindable var vm: KubernetesViewModel
    let onBack: () -> Void

    @State private var command = ""
    @State private var output: [OutputLine] = []
    @State private var isRunning = false

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let isCommand: Bool
        let timestamp = Date()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            outputArea
            Divider()
            inputBar
        }
        .navigationTitle("Exec: \(pod.name)")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Back", systemImage: "chevron.left") { onBack() }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    output.removeAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "terminal")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(pod.name)
                    .font(.headline)
                Text(pod.namespace)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: pod.status?.phase ?? "Unknown")
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
    }

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if output.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "terminal")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Enter a command below")
                                .foregroundStyle(.secondary)
                            Text("Commands run in an ephemeral container in the same namespace.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        ForEach(output) { line in
                            HStack(alignment: .top, spacing: 6) {
                                Text(line.isCommand ? "$" : " ")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(line.isCommand ? .green : .secondary)
                                    .frame(width: 14, alignment: .leading)
                                Text(line.text)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(line.isCommand ? .primary : .secondary)
                                    .textSelection(.enabled)
                            }
                            .id(line.id)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .onChange(of: output.count) { _, _ in
                if let last = output.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(.black.opacity(0.03))
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.green)

            TextField("Enter command...", text: $command)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit { runCommand() }
                .disabled(isRunning)

            if isRunning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button {
                    runCommand()
                } label: {
                    Image(systemName: "return")
                }
                .buttonStyle(.borderless)
                .disabled(command.isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func runCommand() {
        let cmd = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty, !isRunning else { return }

        output.append(OutputLine(text: cmd, isCommand: true))
        command = ""
        isRunning = true

        Task {
            let result = await vm.runCommand(
                namespace: pod.namespace,
                command: ["/bin/sh", "-c", cmd]
            )
            if !result.isEmpty {
                for line in result.components(separatedBy: "\n") {
                    output.append(OutputLine(text: line, isCommand: false))
                }
            }

            isRunning = false
        }
    }
}
