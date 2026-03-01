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
                LabeledContent("Script", value: "~/.claude/hooks/notify_stop.sh")
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
    private static let scriptPath = hooksDir.appendingPathComponent("notify_stop.sh")
    private static let settingsPath = claudeDir.appendingPathComponent("settings.json")

    // Leading whitespace is trimmed by the closing """ alignment
    private static let scriptContent = """
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

    static func checkStatus() -> Status {
        let fm = FileManager.default
        let scriptExists = fm.fileExists(atPath: scriptPath.path)
        let settingsHasHook = readSettingsHook() != nil

        if scriptExists && settingsHasHook { return .installed }
        if scriptExists || settingsHasHook { return .partial }
        return .notInstalled
    }

    static func install() throws {
        let fm = FileManager.default

        try fm.createDirectory(at: hooksDir, withIntermediateDirectories: true)

        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = ["+x", scriptPath.path]
        try process.run()
        process.waitUntilExit()

        try addSettingsHook()
    }

    static func uninstall() throws {
        let fm = FileManager.default

        if fm.fileExists(atPath: scriptPath.path) {
            try fm.removeItem(at: scriptPath)
        }

        try removeSettingsHook()
    }

    private static func readSettingsHook() -> [[String: Any]]? {
        guard let data = FileManager.default.contents(atPath: settingsPath.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any],
              let stop = hooks["Stop"] as? [[String: Any]] else {
            return nil
        }

        let hasOurHook = stop.contains { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains("notify_stop.sh") == true
            }
        }

        return hasOurHook ? stop : nil
    }

    private static func addSettingsHook() throws {
        var json: [String: Any] = [:]

        if let data = FileManager.default.contents(atPath: settingsPath.path),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooks = json["hooks"] as? [String: Any] ?? [:]
        var stop = hooks["Stop"] as? [[String: Any]] ?? []

        let alreadyInstalled = stop.contains { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains("notify_stop.sh") == true
            }
        }

        if !alreadyInstalled {
            let hookEntry: [String: Any] = [
                "matcher": "",
                "hooks": [
                    [
                        "type": "command",
                        "command": "~/.claude/hooks/notify_stop.sh"
                    ]
                ]
            ]
            stop.append(hookEntry)
        }

        hooks["Stop"] = stop
        json["hooks"] = hooks

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsPath)
    }

    private static func removeSettingsHook() throws {
        guard let data = FileManager.default.contents(atPath: settingsPath.path),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        guard var hooks = json["hooks"] as? [String: Any],
              var stop = hooks["Stop"] as? [[String: Any]] else {
            return
        }

        stop.removeAll { entry in
            guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
            return entryHooks.contains { hook in
                (hook["command"] as? String)?.contains("notify_stop.sh") == true
            }
        }

        if stop.isEmpty {
            hooks.removeValue(forKey: "Stop")
        } else {
            hooks["Stop"] = stop
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
