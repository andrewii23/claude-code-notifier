import SwiftUI

struct AboutView: View {
    @State private var isCheckingForUpdates = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

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
                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Check for Updates") {
                        checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCheckingForUpdates)
                }

                if isCheckingForUpdates {
                    HStack {
                        Text("Checking for updates...")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }

            Section {
                LabeledContent("Developer", value: "ii23")
                LabeledContent("Description", value: "Notification bridge for Claude Code")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private func checkForUpdates() {
        isCheckingForUpdates = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            isCheckingForUpdates = false
        }
    }
}
