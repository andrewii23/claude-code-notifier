# ClaudeCodeNotifier

Native macOS notification bridge for [Claude Code](https://claude.ai/code). Get notified when Claude finishes a task.

## How It Works

1. A Claude Code [hook](https://docs.anthropic.com/en/docs/claude-code/hooks) fires when a task completes
2. The hook calls `open -g "claudenotifier://notify?transcript=<path>"`
3. The app reads Claude's last response from the transcript
4. A native macOS notification appears with the summary

## Install

### From Source

```bash
git clone https://github.com/andrewii23/claude-code-notifier.git
cd claude-code-notifier
open ClaudeCodeNotifier.xcodeproj
```

Build and run in Xcode (Cmd+R). The app appears in your menu bar.

### Hook Setup

Create `~/.claude/hooks/notify_stop.sh`:

```bash
#!/bin/bash
read -r JSON
TRANSCRIPT=$(echo "$JSON" | plutil -extract transcript_path raw -o - -)
[ -z "$TRANSCRIPT" ] && exit 0
ENCODED=$(osascript -l JavaScript -e "encodeURIComponent('$TRANSCRIPT')")
open -g "claudenotifier://notify?transcript=$ENCODED"
```

Make it executable:

```bash
chmod +x ~/.claude/hooks/notify_stop.sh
```

Add to your Claude Code hooks config (`~/.claude/hooks.json`):

```json
{
  "hooks": [
    {
      "event": "stop",
      "command": "~/.claude/hooks/notify_stop.sh"
    }
  ]
}
```

## Features

- Native macOS notifications via `UNUserNotificationCenter`
- Reads Claude's last response from JSONL transcripts
- Custom notification title, sound, and fixed message options
- Launch at login support
- Light/dark/auto appearance
- Menu bar app with no Dock icon
- In-app updates via GitHub Releases
- Settings UI using native `NavigationSplitView` and `Form`

## Settings

| Setting | Description |
|---------|-------------|
| Launch at login | Auto-start with macOS |
| Hide menu bar icon | Show Dock icon instead |
| Appearance | Auto / Light / Dark |
| Notification title | Custom title (default: "Claude Code") |
| Fixed message | Always show the same message |
| Alert sound | Choose from system sounds |

## Requirements

- macOS 14.0+
- Xcode 16.0+ (to build from source)

## Architecture

```
Hook script
  -> open -g "claudenotifier://notify?transcript=..."
  -> macOS URL routing
  -> AppDelegate.handleURLEvent
  -> Parse JSONL transcript
  -> Apply user preferences
  -> UNUserNotification
```

The app runs as a background menu bar app (`.accessory` activation policy). Settings use a custom `NSWindow` that switches to `.regular` policy when open.

## License

[MIT](LICENSE)
