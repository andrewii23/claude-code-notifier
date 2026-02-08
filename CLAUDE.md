# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeCodeNotifier is a macOS menu bar app that listens for `claudenotifier://notify` URL scheme callbacks and displays native macOS notifications. It runs as a background-only menu bar app (`.accessory` activation policy) with no main window. App Sandbox is disabled to allow direct reading of transcript files from `~/.claude/projects/`.

## Build Commands

```bash
# Build
xcodebuild -project "ClaudeCodeNotifier.xcodeproj" -scheme ClaudeCodeNotifier -configuration Debug

# Run tests
xcodebuild test -project "ClaudeCodeNotifier.xcodeproj" -scheme ClaudeCodeNotifier

# Release build
xcodebuild -project "ClaudeCodeNotifier.xcodeproj" -scheme ClaudeCodeNotifier -configuration Release
```

## Architecture

### Notification Flow

Hook (`~/.claude/hooks/notify_stop.sh`) receives stop event JSON via stdin → `plutil` extracts `transcript_path` → `osascript -l JavaScript` URL-encodes the path → `open -g "claudenotifier://notify?transcript=<encoded-path>"` → macOS routes to app → `AppDelegate.handleURLEvent` checks for `transcript` param first, falls back to `message`, then `"Done!"` → `parseTranscript(at:)` reads JSONL, finds last assistant message, strips markdown → applies user preferences (title, fixed message override, sound) from `UserDefaults` → fires `UNUserNotification`.

### App Structure

- **ClaudeCodeNotifierApp.swift** — `@main` entry point. `MenuBarExtra` provides menu bar icon with Settings/Quit. `SettingsWindowManager` (singleton) manages a custom `NSWindow` hosting SwiftUI settings. `AppDelegate` handles URL scheme via Apple Events, notification permissions, `Cmd+,` shortcut, and JSONL transcript parsing (`parseTranscript(at:)` using `JSONSerialization`).
- **SettingsView.swift** — `NavigationSplitView` with `List(selection:)` sidebar and detail pane. Contains `SettingsIconView` for sidebar icon badges.
- **SettingsTab.swift** — `SettingsTab` enum defines tabs (general, notification, setup, about) with icons, titles, and view routing. Also defines `Color.accentOrange`.
- **GeneralSettingsView.swift** — Launch-at-login (`SMAppService`), hide menu bar icon, appearance picker. Uses native `Form` with `.formStyle(.grouped)`, `Toggle`, `Picker`, `LabeledContent`.
- **NotificationSettingsView.swift** — Custom title, fixed message toggle, sound picker (reads `/System/Library/Sounds`), custom sound file importer (copies to `~/Library/Sounds`), test notification button. `notificationSound()` static helper resolves sound name to `UNNotificationSound`. Uses native `Form` with `.formStyle(.grouped)`.
- **HookInstallerView.swift** — One-click hook installer/uninstaller. `HookInstaller` enum creates `~/.claude/hooks/notify_stop.sh` and updates `~/.claude/settings.json` with the Stop hook entry. Shows install status (installed/not installed/partial).
- **AboutView.swift** — App icon, version, developer info, check for updates. Uses native `Form` with `LabeledContent`.
- **Updater.swift** — `@Observable` singleton that checks GitHub Releases API for updates, downloads `.zip`, unzips with `/usr/bin/ditto`, and atomically swaps the app bundle via `FileManager.replaceItemAt`. Also defines `Release` model and `Bundle` extensions (`appName`, `appVersion`, `appBuild`).

### UserDefaults Keys (`@AppStorage`)

| Key | Type | Default | Used in |
|-----|------|---------|---------|
| `hideMenuBarIcon` | Bool | `false` | App, General |
| `launchAtLogin` | Bool | `false` | General |
| `appearance` | String | `"auto"` | General, Settings |
| `notificationTitle` | String | `""` | Notification, AppDelegate |
| `useFixedMessage` | Bool | `false` | Notification, AppDelegate |
| `fixedMessage` | String | `""` | Notification, AppDelegate |
| `notificationSound` | String | `"Default"` | Notification, AppDelegate |
| `customSoundFile` | String | `""` | Notification |

### Settings Window Pattern

The app uses a custom `NSWindow` (not `Settings` scene) managed by `SettingsWindowManager`. When opened, activation policy switches to `.regular`; on close, back to `.accessory` unless `hideMenuBarIcon` is true (Dock icon stays visible to prevent lockout).

## Key Details

- Bundle ID: `ii23.ClaudeCodeNotifier`
- Target: macOS 26.2
- Swift concurrency: MainActor default isolation, approachable concurrency enabled
- Standard Xcode project (no SPM/CocoaPods)
- URL scheme: `claudenotifier` (declared in Info.plist)
- Settings views use native SwiftUI `Form`, `Toggle`, `Picker`, `LabeledContent` — no custom row components
- Hook script (`~/.claude/hooks/notify_stop.sh`) is pure bash — uses `plutil` for JSON extraction and `osascript -l JavaScript` for URL encoding (no Python/jq dependency)
