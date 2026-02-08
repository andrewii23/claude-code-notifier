# ClaudeCodeNotifier

Native macOS notification bridge for [Claude Code](https://claude.ai/code). Get notified when Claude finishes a task.

## How It Works

1. A Claude Code [hook](https://docs.anthropic.com/en/docs/claude-code/hooks) fires when a task completes
2. The hook calls `open -g "claudenotifier://notify?transcript=<path>"`
3. The app reads Claude's last response from the transcript
4. A native macOS notification appears with the summary

## Install

### Download

Download the latest release from [Releases](https://github.com/andrewii23/claude-code-notifier/releases), unzip, and drag to Applications.

### From Source

```bash
git clone https://github.com/andrewii23/claude-code-notifier.git
cd claude-code-notifier
open ClaudeCodeNotifier.xcodeproj
```

Build and run in Xcode (Cmd+R). The app appears in your menu bar.

### Hook Setup

Open Settings > Setup and click **Install**. This automatically creates the hook script and updates your Claude Code settings.

<details>
<summary>Manual setup</summary>

Create `~/.claude/hooks/notify_stop.sh`:

```bash
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
```

Make it executable:

```bash
chmod +x ~/.claude/hooks/notify_stop.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify_stop.sh"
          }
        ]
      }
    ]
  }
}
```

</details>

## Features

- Native macOS notifications via `UNUserNotificationCenter`
- Reads Claude's last response from JSONL transcripts
- One-click hook installer (Settings > Setup)
- Custom notification title, sound, and fixed message options
- Custom sound file support (aiff, wav, caf, m4a)
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
| Alert sound | Choose from system sounds or custom file |
| Hook installer | One-click install/uninstall Claude Code hook |

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
