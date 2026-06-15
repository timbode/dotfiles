#!/usr/bin/env bash
# macos/window-shortcuts.sh — give macOS-native window tiling the Rectangle-style
# Ctrl+Option+Arrow shortcuts, so you can drop Rectangle and keep the muscle memory.
# Requires the native "Window ▸ Move & Resize" menu (macOS 15 Sequoia / 26 Tahoe+).
#
# OPT-IN / NOT run by bootstrap.sh. Only use this if you go Rectangle-free — it
# CONFLICTS with Rectangle's shortcuts, and unlike Rectangle it cannot move
# windows across displays or cycle window sizes on repeated presses.
#
# These are App Shortcuts (System Settings ▸ Keyboard ▸ Keyboard Shortcuts ▸ App
# Shortcuts → All Applications). macOS matches them by MENU-ITEM TITLE, so the
# strings below must equal the exact titles under Window ▸ Move & Resize.
#
# Modifier codes:  ^ control   ~ option   $ shift   @ command
# Arrow glyphs (Cocoa interprets \\Uxxxx here):  ← \\U2190  → \\U2192  ↑ \\U2191  ↓ \\U2193
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "window-shortcuts.sh: not macOS, skipping"; exit 0; }

echo "→ native window shortcuts: Ctrl+Option+Arrows = halves"

# Halves — the four you mentioned.
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Left"   '^~\U2190'
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Right"  '^~\U2192'
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Top"    '^~\U2191'
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Bottom" '^~\U2193'

# Optional extras — uncomment if the menu titles match on your macOS version.
# (Rectangle: maximize = ⌃⌥↵, center = ⌃⌥C.  ↩ = \U21A9)
# defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Fill"   '^~\U21A9'
# defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Center" '^~c'

echo "  ✓ set. Applies to apps launched afterwards (log out to apply everywhere)."
echo "    NOTE: native tiling is per-app menu-driven and less capable than Rectangle"
echo "    (halves/quarters/fill/center only). If a title differs on your build, open"
echo "    the Window ▸ Move & Resize menu and match the exact wording here."
