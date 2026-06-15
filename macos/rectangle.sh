#!/usr/bin/env bash
# macos/rectangle.sh — restore Rectangle settings from the versioned plist.
# Rectangle stays the window manager because it does what native tiling can't:
#   • move windows across displays  (Move to Next/Previous Display)
#   • cycle window sizes on repeated presses  (subsequentExecutionMode)
# Config (alternate shortcuts, cycling, Todo mode) lives in rectangle.plist.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "rectangle.sh: not macOS, skipping"; exit 0; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d /Applications/Rectangle.app && ! -d "$HOME/Applications/Rectangle.app" ]]; then
    echo "rectangle.sh: Rectangle not installed yet (brew bundle installs it) — skipping"
    exit 0
fi

echo "→ importing Rectangle config"
osascript -e 'quit app "Rectangle"' 2>/dev/null || true
defaults import com.knollsoft.Rectangle "$DIR/rectangle.plist"
open -a Rectangle 2>/dev/null || true
echo "  ✓ Rectangle config restored"
echo "    (First launch: grant Accessibility permission in System Settings ▸"
echo "     Privacy & Security ▸ Accessibility — macOS requires this manually.)"
