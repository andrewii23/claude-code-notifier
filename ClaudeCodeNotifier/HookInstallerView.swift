import SwiftUI

struct HookInstallerView: View {
    @State private var hookStatus = HookInstaller.Status.checking
    @State private var showError: String?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code Hook")
                            .font(.headline)
                        Text(hookStatus.description)
                            .font(.subheadline)
                            .foregroundStyle(hookStatus.color)
                    }

                    Spacer()

                    switch hookStatus {
                    case .installed:
                        Button("Uninstall") { uninstall() }
                            .buttonStyle(.bordered)
                    case .notInstalled, .partial:
                        Button("Install") { install() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentOrange)
                    case .checking:
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let showError {
                    Text(showError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                LabeledContent("Stop Hook", value: "~/.claude/hooks/notify_stop.sh")
                LabeledContent("Notification Hook", value: "~/.claude/hooks/notify_notification.sh")
                LabeledContent("Settings", value: "~/.claude/settings.json")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .task { checkStatus() }
    }

    private func checkStatus() {
        hookStatus = HookInstaller.checkStatus()
    }

    private func install() {
        showError = nil
        do {
            try HookInstaller.install()
            checkStatus()
        } catch {
            showError = error.localizedDescription
        }
    }

    private func uninstall() {
        showError = nil
        do {
            try HookInstaller.uninstall()
            checkStatus()
        } catch {
            showError = error.localizedDescription
        }
    }
}

enum HookInstaller {
    enum Status {
        case checking
        case installed
        case notInstalled
        case partial

        var description: String {
            switch self {
            case .checking: "Checking..."
            case .installed: "Installed"
            case .notInstalled: "Not installed"
            case .partial: "Partially installed"
            }
        }

        var color: Color {
            switch self {
            case .checking: .secondary
            case .installed: Color.accentOrange
            case .notInstalled: .secondary
            case .partial: .orange
            }
        }
    }

    private static let claudeDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude")
    private static let hooksDir = claudeDir.appendingPathComponent("hooks")
    private static let stopScriptPath = hooksDir.appendingPathComponent("notify_stop.sh")
    private static let notificationScriptPath = hooksDir.appendingPathComponent("notify_notification.sh")
    private static let settingsPath = claudeDir.appendingPathComponent("settings.json")

    private static let stopScriptContent = """
        #!/bin/bash
        INPUT=$(cat)
        sleep 0.5
        TRANSCRIPT=$(printf '%s' "$INPUT" | plutil -extract transcript_path raw -o - -- -)
        if [ -n "$TRANSCRIPT" ] && [ "$TRANSCRIPT" != "<stdin>" ]; then
            ENCODED=$(osascript -l JavaScript -e 'function run(argv) { return encodeURIComponent(argv[0]) }' -- "$TRANSCRIPT")
            open -g "claudenotifier://notify?transcript=${ENCODED}"
        else
            open -g "claudenotifier://notify"
        fi
        exit 0
        """

    private static let notificationScriptContent = """
        #!/bin/bash
        INPUT=$(cat)
        MESSAGE=$(printf '%s' "$INPUT" | plutil -extract message raw -o - -- -)
        ENCODED_MSG=$(osascript -l JavaScript -e 'function run(argv) { return encodeURIComponent(argv[0]) }' -- "$MESSAGE")
        open -g "claudenotifier://attention?message=${ENCODED_MSG}"
        exit 0
        """

    static func checkStatus() -> Status {
        let fm = FileManager.default
        let stopExists = fm.fileExists(atPath: stopScriptPath.path)
        let notifExists = fm.fileExists(atPath: notificationScriptPath.path)
        let hasStopHook = readSettingsHook(event: "Stop", scriptName: "notify_stop.sh") != nil
        let hasNotifHook = readSettingsHook(event: "Notification", scriptName: "notify_notification.sh") != nil

        let allInstalled = stopExists && notifExists && hasStopHook && hasNotifHook
        let noneInstalled = !stopExists && !notifExists && !hasStopHook && !hasNotifHook

        if allInstalled { return .installed }
        if noneInstalled { return .notInstalled }
        return .partial
    }

    static func install() throws {
        let fm = FileManager.default

        try fm.createDirectory(at: hooksDir, withIntermediateDirectories: true)

        for (path, content) in [(stopScriptPath, stopScriptContent), (notificationScriptPath, notificationScriptContent)] {
            try content.write(to: path, atomically: true, encoding: .utf8)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/chmod")
            process.arguments = ["+x", path.path]
            try process.run()
            process.waitUntilExit()
        }

        try addSettingsHook(event: "Stop", scriptPath: "~/.claude/hooks/notify_stop.sh", scriptName: "notify_stop.sh")
        try addSettingsHook(event: "Notification", scriptPath: "~/.claude/hooks/notify_notification.sh", scriptName: "notify_notification.sh")
    }

    static func uninstall() throws {
        let fm = FileManager.default

        for path in [stopScriptPath, notificationScriptPath] {
            if fm.fileExists(atPath: path.path) {
                try fm.removeItem(at: path)
            }
        }

        try removeSettingsHook(event: "Stop", scriptName: "notify_stop.sh")
        try removeSettingsHook(event: "Notification", scriptName: "notify_notification.sh")
    }

    private static func readSettingsHook(event: String, scriptName: String) -> [[String: Any]]? {
        guard let data = FileManager.default.contents(atPath: settingsPath.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any],
              let entries = hooks[event] as? [[String: Any]] else {
            return nil
        }

        let hasOurHook = entries.contains { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains(scriptName) == true
            }
        }

        return hasOurHook ? entries : nil
    }

    private static func addSettingsHook(event: String, scriptPath: String, scriptName: String) throws {
        var json: [String: Any] = [:]

        if let data = FileManager.default.contents(atPath: settingsPath.path),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooks = json["hooks"] as? [String: Any] ?? [:]
        var entries = hooks[event] as? [[String: Any]] ?? []

        let alreadyInstalled = entries.contains { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains(scriptName) == true
            }
        }

        if !alreadyInstalled {
            let hookEntry: [String: Any] = [
                "matcher": "",
                "hooks": [
                    [
                        "type": "command",
                        "command": scriptPath
                    ]
                ]
            ]
            entries.append(hookEntry)
        }

        hooks[event] = entries
        json["hooks"] = hooks

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: self.settingsPath)
    }

    private static func removeSettingsHook(event: String, scriptName: String) throws {
        guard let data = FileManager.default.contents(atPath: settingsPath.path),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        guard var hooks = json["hooks"] as? [String: Any],
              var entries = hooks[event] as? [[String: Any]] else {
            return
        }

        entries.removeAll { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains(scriptName) == true
            }
        }

        if entries.isEmpty {
            hooks.removeValue(forKey: event)
        } else {
            hooks[event] = entries
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        let newData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try newData.write(to: settingsPath)
    }
}
