#!/usr/bin/env bash
# macos/defaults.sh — system preferences for macOS, codified.
# Called from bootstrap.sh on Darwin; also safe to run standalone:  bash macos/defaults.sh
#
# Values reflect THIS machine's captured state (the determining factor) plus two
# explicit preferences: smart-text OFF and reversed (non-natural) scrolling.
# Settings the machine left at macOS defaults are intentionally NOT forced here —
# see the OPTIONAL block at the bottom for opt-in extras.
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "macos/defaults.sh: not macOS, skipping"; exit 0; }

echo "→ applying macOS defaults"

# Don't let an open System Settings window clobber our writes.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ── Keyboard: disable "smart" text substitutions (you chose this) ──────────────
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled     -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled   -bool false

# ── Trackpad: lock in this machine's state ────────────────────────────────────
# Tap-to-click ON (a real customization — macOS defaults this OFF).
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Two-finger secondary click ON; three-finger drag OFF (matches this machine).
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false

# ── Scrolling: reversed / non-natural (you chose this; matches this machine) ───
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# ── Apply ─────────────────────────────────────────────────────────────────────
for app in Finder Dock SystemUIServer; do killall "$app" 2>/dev/null || true; done
echo "  ✓ defaults applied (a logout fully settles a few keyboard toggles)"

###############################################################################
# OPTIONAL — NOT captured from this machine. Uncomment to opt in on a new Mac.
###############################################################################
# # Faster key repeat + hold-to-repeat (good for vim; breaks accent popup)
# defaults write NSGlobalDomain KeyRepeat -int 2
# defaults write NSGlobalDomain InitialKeyRepeat -int 15
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# # F1/F2… act as standard function keys (hold Globe for brightness/volume)
# defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool true
# # Finder: show all extensions, path/status bar, search current folder
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# defaults write com.apple.finder ShowPathbar -bool true
# defaults write com.apple.finder ShowStatusBar -bool true
# defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# # Don't scatter .DS_Store on network/USB volumes
# defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# # Dock behaviour + pinned layout now live in macos/dock.sh (run from bootstrap).
# # Screenshots to ~/Screenshots as PNG
# mkdir -p "$HOME/Screenshots"
# defaults write com.apple.screencapture location -string "$HOME/Screenshots"
# defaults write com.apple.screencapture type -string png
