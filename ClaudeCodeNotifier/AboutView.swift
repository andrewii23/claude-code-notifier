import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        SettingsSection {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ClaudeCodeNotifier")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version \(appVersion)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            SettingsInfoRow(label: "Developer", value: "ii23")
            SettingsInfoRow(label: "Description", value: "Notification bridge for Claude Code")
        }
    }
}
