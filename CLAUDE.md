# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CC Noti (ClaudeCodeNotifier) is a macOS menu bar app that listens for `claudenotifier://notify` URL scheme callbacks and displays native macOS notifications. It runs as a background-only menu bar app with no main window.

## Build Commands

```bash
# Build
xcodebuild -project "CC Noti.xcodeproj" -scheme ClaudeCodeNotifier -configuration Debug

# Run tests
xcodebuild test -project "CC Noti.xcodeproj" -scheme ClaudeCodeNotifier

# Release build
xcodebuild -project "CC Noti.xcodeproj" -scheme ClaudeCodeNotifier -configuration Release
```

## Architecture

- **ClaudeCodeNotifierApp.swift** — App entry point using `MenuBarExtra` for background menu bar presence. Contains `AppDelegate` that handles URL scheme registration, notification permissions, and `UNUserNotificationCenter` delegation.
- **ContentView.swift** — Unused SwiftUI stub from template.
- **Info.plist** — Declares `claudenotifier` URL scheme.

Flow: External caller opens `claudenotifier://notify` → macOS routes to app → `AppDelegate` handles Apple Event → triggers `UNUserNotification` with "Claude Code - Done!".

## Key Details

- Bundle ID: `ii23.CCNoti`
- Target: macOS 26.2
- Swift concurrency: MainActor default isolation, approachable concurrency enabled
- Standard Xcode project (no SPM/CocoaPods)
