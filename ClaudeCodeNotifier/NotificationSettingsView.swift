import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

enum SoundVolume: String, CaseIterable {
    case soft = "Soft"
    case balanced = "Balanced"
    case loud = "Loud"

    var level: Float {
        switch self {
        case .soft: 0.25
        case .balanced: 0.6
        case .loud: 1.0
        }
    }

    var icon: String {
        switch self {
        case .soft: "speaker.wave.1.fill"
        case .balanced: "speaker.wave.2.fill"
        case .loud: "speaker.wave.3.fill"
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notificationTitle") private var notificationTitle = ""
    @AppStorage("useFixedMessage") private var useFixedMessage = false
    @AppStorage("fixedMessage") private var fixedMessage = ""
    @AppStorage("notificationSound") private var notificationSound = "Default"
    @AppStorage("customSoundFile") private var customSoundFile = ""
    @AppStorage("soundVolume") private var soundVolume = SoundVolume.balanced.rawValue
    @State private var showFilePicker = false

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
                    Divider()
                    Text("Custom").tag("Custom")
                }
                .onChange(of: notificationSound) { _, newValue in
                    if newValue == "Custom" {
                        if !customSoundFile.isEmpty {
                            previewSound()
                        }
                    } else if newValue != "Default" {
                        previewSound()
                    }
                }

                if notificationSound == "Custom" {
                    HStack {
                        Text("Custom sound")
                        Spacer()
                        if customSoundFile.isEmpty {
                            Text("None")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(customSoundFile.replacingOccurrences(of: "ClaudeCodeNotifier_", with: ""))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button("Choose...") {
                            showFilePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.aiff, .wav, .audio],
                        allowsMultipleSelection: false
                    ) { result in
                        handleFileImport(result)
                    }
                }

                Picker("Volume", selection: $soundVolume) {
                    ForEach(SoundVolume.allCases, id: \.rawValue) { vol in
                        Text(vol.rawValue).tag(vol.rawValue)
                    }
                }
                .onChange(of: soundVolume) { _, _ in
                    previewSound()
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

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }

        let ext = url.pathExtension.lowercased()
        guard ["aiff", "aif", "wav", "caf", "m4a"].contains(ext) else { return }

        let soundsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Sounds")

        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

            let destName = "ClaudeCodeNotifier_\(url.deletingPathExtension().lastPathComponent).\(ext)"
            let dest = soundsDir.appendingPathComponent(destName)

            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }

            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            try FileManager.default.copyItem(at: url, to: dest)
            customSoundFile = destName
            previewSound()
        } catch {
            customSoundFile = ""
        }
    }

    private func previewSound() {
        let volume = SoundVolume(rawValue: soundVolume) ?? .balanced
        Self.playSound(name: notificationSound, customFile: customSoundFile, volume: volume)
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle.isEmpty ? "Claude Code" : notificationTitle
        content.body = useFixedMessage ? (fixedMessage.isEmpty ? "Done!" : fixedMessage) : "Test notification"
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
        let volume = SoundVolume(rawValue: soundVolume) ?? .balanced
        Self.playSound(name: notificationSound, customFile: customSoundFile, volume: volume)
    }

    static func playSound(name: String, customFile: String, volume: SoundVolume) {
        let sound: NSSound?
        if name == "Default" {
            sound = NSSound(named: "Tink")
        } else if name == "Custom" && !customFile.isEmpty {
            let path = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Sounds")
                .appendingPathComponent(customFile).path
            sound = NSSound(contentsOfFile: path, byReference: true)
        } else {
            sound = NSSound(named: NSSound.Name(name))
        }
        sound?.volume = volume.level
        sound?.play()
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
