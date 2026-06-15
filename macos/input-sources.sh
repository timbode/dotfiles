#!/usr/bin/env bash
# macos/input-sources.sh — enable two keyboard layouts: ABC (US/English) + German.
# Structure captured verbatim from the reference Mac, so it's known-good.
# Switch between them from the menu-bar input menu or with Ctrl+Space.
# Applies fully after a LOGOUT — the input system only reloads this at login.
#
# Layout IDs: ABC = 252, German = 3, "U.S." = 0 (swap ABC→U.S. below if you
# prefer the classic "U.S." layout name over Apple's modern "ABC").
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "input-sources.sh: not macOS, skipping"; exit 0; }

echo "→ keyboard input sources: ABC (US) + German"

defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
  '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 252; "KeyboardLayout Name" = ABC; }' \
  '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 3;   "KeyboardLayout Name" = German; }' \
  '{ "Bundle ID" = "com.apple.CharacterPaletteIM";               InputSourceKind = "Non Keyboard Input Method"; }' \
  '{ "Bundle ID" = "com.apple.PressAndHold";                     InputSourceKind = "Non Keyboard Input Method"; }' \
  '{ "Bundle ID" = "com.apple.inputmethod.EmojiFunctionRowItem"; InputSourceKind = "Non Keyboard Input Method"; }'

echo "  ✓ set. Log out and back in to see both layouts in the menu bar."
