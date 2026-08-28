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

# Add what is missing; never replace the whole array. Writing -array wholesale
# deletes any layout enabled outside this script, which is the same trap that
# cost two Shortcuts tiles in the Dock: a "captured from the reference Mac"
# snapshot silently reimposed on every run. Enabling a third language should
# survive a bootstrap.
#
# Comparison ignores whitespace because `defaults read` reformats what it prints.
_source_enabled() {
    # Args: needle — a whitespace-free fragment identifying one input source.
    defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null \
        | tr -d ' ' | grep -qF "$1"
}

_ensure_source() {
    # Args: needle, plist dict for `defaults -array-add`, human label.
    if _source_enabled "$1"; then
        echo "  • already enabled: $3"
    else
        defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add "$2"
        echo "  + enabled: $3"
    fi
}

_ensure_source '"KeyboardLayoutName"=ABC;' \
    '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 252; "KeyboardLayout Name" = ABC; }' \
    'ABC (US)'
_ensure_source '"KeyboardLayoutName"=German;' \
    '{ InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 3; "KeyboardLayout Name" = German; }' \
    'German'
_ensure_source '"BundleID"="com.apple.CharacterPaletteIM";' \
    '{ "Bundle ID" = "com.apple.CharacterPaletteIM"; InputSourceKind = "Non Keyboard Input Method"; }' \
    'Character Palette'
_ensure_source '"BundleID"="com.apple.PressAndHold";' \
    '{ "Bundle ID" = "com.apple.PressAndHold"; InputSourceKind = "Non Keyboard Input Method"; }' \
    'Press and Hold'
_ensure_source '"BundleID"="com.apple.inputmethod.EmojiFunctionRowItem";' \
    '{ "Bundle ID" = "com.apple.inputmethod.EmojiFunctionRowItem"; InputSourceKind = "Non Keyboard Input Method"; }' \
    'Emoji / Fn row'

echo "  ✓ set. Log out and back in to see both layouts in the menu bar."
