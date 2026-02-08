import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ClaudeCodeNotifier")
                            .font(.headline)
                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
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
}
