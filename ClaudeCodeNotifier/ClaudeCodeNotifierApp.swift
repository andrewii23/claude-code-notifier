import SwiftUI
import UserNotifications

@main
struct ClaudeCodeNotifierApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hideMenuBarIcon") private var hideMenuBarIcon = false

    var body: some Scene {
        MenuBarExtra("ClaudeCodeNotifier", image: "menubarIcon", isInserted: Binding(
            get: { !hideMenuBarIcon },
            set: { hideMenuBarIcon = !$0 }
        )) {
            Button("Settings...") {
                SettingsWindowManager.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

@MainActor
final class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.delegate = self
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func windowWillClose(_ notification: Notification) {
        let hideIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
        if !hideIcon {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        let hideIcon = UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
        NSApp.setActivationPolicy(hideIcon ? .regular : .accessory)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                SettingsWindowManager.shared.show()
                return nil
            }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowManager.shared.show()
        return true
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        if url.scheme == "claudenotifier" && url.host == "notify" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems

            var dynamicMessage: String
            if let transcriptPath = queryItems?.first(where: { $0.name == "transcript" })?.value {
                dynamicMessage = parseTranscript(at: transcriptPath) ?? "Done!"
            } else {
                dynamicMessage = queryItems?.first(where: { $0.name == "message" })?.value ?? "Done!"
            }

            let defaults = UserDefaults.standard
            let title = defaults.string(forKey: "notificationTitle").flatMap { $0.isEmpty ? nil : $0 } ?? "Claude Code"
            let useFixed = defaults.bool(forKey: "useFixedMessage")
            let fixedMessage = defaults.string(forKey: "fixedMessage").flatMap { $0.isEmpty ? nil : $0 } ?? "Done!"
            let body = useFixed ? fixedMessage : dynamicMessage

            showNotification(title: title, message: body)
        }
    }

    private func parseTranscript(at path: String) -> String? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines)

        for line in lines.reversed() {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  json["type"] as? String == "assistant" else {
                continue
            }

            guard let message = json["message"] as? [String: Any],
                  let contentArray = message["content"] as? [[String: Any]] else {
                continue
            }

            let texts = contentArray.compactMap { item -> String? in
                guard item["type"] as? String == "text" else { return nil }
                return item["text"] as? String
            }

            guard !texts.isEmpty else { continue }

            var result = texts.joined(separator: " ")
            let markdownChars = CharacterSet(charactersIn: "*_`#~[]")
            result = String(result.unicodeScalars.filter { !markdownChars.contains($0) })
            result = result.replacingOccurrences(of: "\n", with: " ")
            result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            result = result.trimmingCharacters(in: .whitespaces)

            return result.isEmpty ? nil : result
        }

        return nil
    }

    func showNotification(title: String, message: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        let soundName = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
        let customFile = UserDefaults.standard.string(forKey: "customSoundFile") ?? ""
        content.sound = NotificationSettingsView.notificationSound(name: soundName, customFile: customFile)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
