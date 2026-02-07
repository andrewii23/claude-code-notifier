import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notificationTitle") private var notificationTitle = ""
    @AppStorage("useFixedMessage") private var useFixedMessage = false
    @AppStorage("fixedMessage") private var fixedMessage = ""
    @AppStorage("notificationSound") private var notificationSound = "Default"

    var body: some View {
        SettingsSection("Title") {
            SettingsTextFieldRow(placeholder: "Claude Code", text: $notificationTitle)
        }

        SettingsSection("Message") {
            SettingsToggleRow(title: "Use fixed message", isOn: $useFixedMessage)

            if useFixedMessage {
                SettingsTextFieldRow(placeholder: "Done!", text: $fixedMessage)
            }
        }

        SettingsSection("Sound") {
            SoundPickerRow(selection: $notificationSound)
        }
    }
}

struct SoundPickerRow: View {
    @Binding var selection: String

    private static let systemSounds: [String] = {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: "/System/Library/Sounds") else { return [] }
        return files
            .filter { $0.hasSuffix(".aiff") }
            .map { $0.replacingOccurrences(of: ".aiff", with: "") }
            .sorted()
    }()

    var body: some View {
        HStack {
            Text("Alert sound")
                .padding(.vertical, 4)
            Spacer()
            Picker("Alert sound", selection: $selection) {
                Text("Default").tag("Default")
                Divider()
                ForEach(Self.systemSounds, id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }
            .labelsHidden()
            .onChange(of: selection) { _, newValue in
                guard newValue != "Default" else { return }
                NSSound(named: NSSound.Name(newValue))?.play()
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 30)
    }
}
