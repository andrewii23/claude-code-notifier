import SwiftUI

struct AboutView: View {
    var updater = Updater.shared

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Bundle.main.appName)
                            .font(.headline)
                        Text("Version \(Bundle.main.appVersion ?? "1.0")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Check for Updates") {
                        Task { await updater.checkForUpdates() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(updater.state == .checking)
                }

                switch updater.state {
                case .checking:
                    HStack {
                        Text("Checking for updates...")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    }
                case .available:
                    HStack {
                        Text("Version \(updater.targetRelease?.tagName ?? "") available")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Update") {
                            Task { await updater.installUpdate() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .downloading, .installing:
                    HStack {
                        Text(updater.state == .downloading ? "Downloading..." : "Installing...")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView(value: updater.progress)
                            .frame(width: 100)
                    }
                case .upToDate:
                    HStack {
                        Text("You're up to date.")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                case .failed(let message):
                    HStack {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                case .idle:
                    EmptyView()
                }
            }

            Section {
                Toggle("Automatically check and install updates", isOn: Binding(
                    get: { updater.autoUpdateEnabled },
                    set: { updater.autoUpdateEnabled = $0 }
                ))
                .tint(Color.accentOrange)
            }

            Section {
                LabeledContent("Developer", value: "ii23")
                LabeledContent("Description", value: "Notification bridge for Claude Code")
                LabeledContent("GitHub") {
                    Link("andrewii23/claude-code-notifier", destination: URL(string: "https://github.com/andrewii23/claude-code-notifier")!)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
