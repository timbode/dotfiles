#!/usr/bin/env bash
# macos/dock.sh — Dock behaviour + pinned-app layout, codified.
# Called from bootstrap.sh on Darwin; also safe to run standalone:  bash macos/dock.sh
#
# Behaviour knobs reflect THIS machine's captured state. The pinned layout is
# rebuilt from scratch with dockutil (installed via the Brewfile) so a fresh Mac
# ends up with the same Dock. Apps that aren't installed are skipped, not fatal —
# third-party / Safari web-app tiles only appear once their .app exists.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "dock.sh: not macOS, skipping"; exit 0; }

echo "→ configuring Dock"

# ── Behaviour & appearance (captured from this machine) ───────────────────────
defaults write com.apple.dock autohide      -bool true   # auto-hide the Dock
defaults write com.apple.dock magnification -bool true   # magnify icons on hover
defaults write com.apple.dock tilesize      -int  38     # resting icon size
defaults write com.apple.dock largesize     -int  93     # magnified icon size
defaults write com.apple.dock show-recents  -bool true   # show the recent-apps section
# Bottom-right hot corner → Quick Note (action 14), no modifier key (0)
defaults write com.apple.dock wvous-br-corner   -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# ── Pinned apps ───────────────────────────────────────────────────────────────
# Without dockutil we can still apply the knobs above; just skip the layout.
if ! command -v dockutil &>/dev/null; then
    echo "  dockutil not found (brew bundle installs it) — applied knobs only, skipping layout"
    killall Dock 2>/dev/null || true
    echo "  ✓ Dock behaviour applied"
    exit 0
fi

# Wipe the Dock, then re-add each tile in order. --no-restart batches the writes
# so the Dock only restarts once, at the end.
dockutil --no-restart --remove all >/dev/null

# Add an app tile if its .app exists; otherwise note the skip and move on.
add_app() {
    local path="$1"
    if [[ -d "$path" ]]; then
        dockutil --no-restart --add "$path" >/dev/null
    else
        echo "  • skipping (not installed): $(basename "$path" .app)"
    fi
}

# Left-to-right order. System apps live under /System/Applications; third-party
# and the Safari web app are guarded by the existence check in add_app.
add_app "/System/Applications/Apps.app"            # macOS Apps launcher
add_app "/Applications/Safari.app"
add_app "/Applications/Firefox.app"
add_app "/System/Applications/Messages.app"
add_app "/System/Applications/Mail.app"
add_app "/System/Applications/Photos.app"
add_app "/System/Applications/FaceTime.app"
add_app "/System/Applications/Phone.app"
add_app "/System/Applications/Calendar.app"
add_app "/System/Applications/System Settings.app"
add_app "$HOME/Applications/CRM - Aufgaben.app"    # Safari web app (this machine)
add_app "/Applications/Microsoft Teams.app"

# Downloads stack on the right: fan view, sorted by date added, stack icon.
if [[ -d "$HOME/Downloads" ]]; then
    dockutil --no-restart --add "$HOME/Downloads" \
        --view fan --display stack --sort dateadded >/dev/null
fi

killall Dock 2>/dev/null || true
echo "  ✓ Dock configured (knobs + pinned layout)"
