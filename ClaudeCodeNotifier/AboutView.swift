import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        SettingsSection {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ClaudeCodeNotifier")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }

        SettingsSection("Info") {
            SettingsInfoRow(label: "Developer", value: "ii23")
            SettingsInfoRow(label: "Description", value: "Notification bridge for Claude Code")
        }
    }
}
