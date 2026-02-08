import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("notificationTitle") private var notificationTitle = ""
    @AppStorage("useFixedMessage") private var useFixedMessage = false
    @AppStorage("fixedMessage") private var fixedMessage = ""
    @AppStorage("notificationSound") private var notificationSound = "Default"

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $notificationTitle, prompt: Text("Claude Code"))

                Toggle("Use fixed message", isOn: $useFixedMessage)
                    .tint(Color.accentOrange)

                if useFixedMessage {
                    TextField("Message", text: $fixedMessage, prompt: Text("Done!"))
                }

                Picker("Alert sound", selection: $notificationSound) {
                    Text("Default").tag("Default")
                    Divider()
                    ForEach(Self.systemSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .onChange(of: notificationSound) { _, newValue in
                    guard newValue != "Default" else { return }
                    NSSound(named: NSSound.Name(newValue))?.play()
                }

                HStack {
                    Spacer()
                    Button("Test Notification") {
                        sendTestNotification()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle.isEmpty ? "Claude Code" : notificationTitle
        content.body = useFixedMessage ? (fixedMessage.isEmpty ? "Done!" : fixedMessage) : "Test notification"
        content.sound = notificationSound == "Default"
            ? .default
            : UNNotificationSound(named: UNNotificationSoundName(notificationSound + ".aiff"))
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }

    private static let systemSounds: [String] = {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: "/System/Library/Sounds") else { return [] }
        return files
            .filter { $0.hasSuffix(".aiff") }
            .map { $0.replacingOccurrences(of: ".aiff", with: "") }
            .sorted()
    }()
}
