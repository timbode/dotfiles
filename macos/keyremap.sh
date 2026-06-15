#!/usr/bin/env bash
# macos/keyremap.sh — swap Left Control <-> Globe/Fn, persistently.
# Called from bootstrap.sh on Darwin; also safe to run standalone.
#
# HID usage codes:  Left Control = 0x7000000E0,  Globe/Fn = 0xFF00000003
# `hidutil` applies the swap instantly but forgets it on reboot / re-plug,
# so we also install a LaunchAgent that re-applies it at every login.
#
# To swap OTHER keys: edit the JSON in com.dotfiles.keyremap.plist, then re-run.
# (Caps=0x700000039, ⌥=0x7000000E2, ⌘=0x7000000E3.  Inspect current map with:
#  hidutil property --get "UserKeyMapping")
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "macos/keyremap.sh: not macOS, skipping"; exit 0; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTFILES/macos/com.dotfiles.keyremap.plist"
DST="$HOME/Library/LaunchAgents/com.dotfiles.keyremap.plist"

echo "→ key remap: Left Control <-> Globe/Fn"

# Apply immediately for this session by replaying the plist's argument.
REMAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x7000000E0,"HIDKeyboardModifierMappingDst":0xFF00000003},{"HIDKeyboardModifierMappingSrc":0xFF00000003,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
hidutil property --set "$REMAP" >/dev/null

# Persist across reboots via LaunchAgent.
mkdir -p "$HOME/Library/LaunchAgents"
ln -sfn "$SRC" "$DST"
launchctl unload "$DST" 2>/dev/null || true
launchctl load   "$DST"
echo "  ✓ applied now + installed LaunchAgent (com.dotfiles.keyremap)"
