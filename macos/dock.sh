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

# Desired tiles, left-to-right. System apps live under /System/Applications;
# third-party and the Safari web app only exist on some machines.
CANDIDATES=(
    "/System/Applications/Apps.app"            # macOS Apps launcher (macOS 15+)
    "/Applications/Safari.app"
    "/Applications/Firefox.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Photos.app"
    "/System/Applications/FaceTime.app"
    "/System/Applications/Phone.app"
    "/System/Applications/Calendar.app"
    "/System/Applications/System Settings.app"
    "$HOME/Applications/CRM - Aufgaben.app"    # Safari web app (this machine)
    "/Applications/Microsoft Teams.app"
)

# Keep only the apps that actually exist on this machine.
apps=()
for path in "${CANDIDATES[@]}"; do
    if [[ -d "$path" ]]; then apps+=("$path")
    else echo "  • skipping (not installed): $(basename "$path" .app)"; fi
done

# Safety net: never wipe the Dock unless we have something to put back, so a
# path mismatch can't strand you with an empty Dock.
if (( ${#apps[@]} == 0 )); then
    echo "  no known apps found here — leaving the existing Dock untouched"
    killall Dock 2>/dev/null || true
    echo "  ✓ Dock behaviour applied (layout left as-is)"
    exit 0
fi

# Tiles the Dock already has that this script did not put there: Shortcuts
# droplets, anything dragged in by hand. The rebuild below wipes everything, so
# without this they are destroyed — which has already cost two Shortcuts tiles
# once. Collect them first and put them back afterwards.
#
# Match on bundle identifier, not path. Safari's Dock entry points into
# /System/Volumes/Preboot/Cryptexes/App/..., not /Applications/Safari.app, so a
# path comparison would read it as foreign and pin a second copy.
known_ids=()
for path in "${apps[@]}"; do
    id=$(defaults read "$path/Contents/Info" CFBundleIdentifier 2>/dev/null || true)
    [[ -n "$id" ]] && known_ids+=("$id")
done

extras=()
while IFS=$'\t' read -r _name url section _plist bundle; do
    [[ "$section" == persistentApps ]] || continue
    for id in ${known_ids[@]+"${known_ids[@]}"}; do
        [[ "$bundle" == "$id" ]] && continue 2
    done
    # dockutil prints URL-escaped paths but only accepts plain ones.
    esc="${url#file://}"; esc="${esc%/}"
    extras+=("$(printf '%b' "${esc//%/\\x}")")
done < <(dockutil --list 2>/dev/null || true)

if (( ${#extras[@]} > 0 )); then
    echo "  preserving ${#extras[@]} tile(s) added outside this script"
fi

# Rebuild: wipe, then re-add. Individual dockutil failures are non-fatal — a
# single bad tile must never abort the script and leave the Dock empty.
# --no-restart batches the writes so the Dock only restarts once, at the end.
dockutil --no-restart --remove all >/dev/null 2>&1 || true
for path in "${apps[@]}"; do
    dockutil --no-restart --add "$path" >/dev/null 2>&1 \
        || echo "  • could not add: $(basename "$path" .app)"
done

# Preserved tiles go back after the pinned set, in the order they were found.
for path in ${extras[@]+"${extras[@]}"}; do
    dockutil --no-restart --add "$path" >/dev/null 2>&1 \
        || echo "  • could not restore: $(basename "$path" .app)"
done

# Downloads stack on the right: fan view, sorted by date added, stack icon.
if [[ -d "$HOME/Downloads" ]]; then
    dockutil --no-restart --add "$HOME/Downloads" \
        --view fan --display stack --sort dateadded >/dev/null 2>&1 || true
fi

killall Dock 2>/dev/null || true
echo "  ✓ Dock configured (knobs + pinned layout)"
