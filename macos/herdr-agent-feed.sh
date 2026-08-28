#!/usr/bin/env bash
# macos/herdr-agent-feed.sh — keep the Herdr agent sidebar populated.
# Called from bootstrap.sh on Darwin; also safe to run standalone.
#
# Herdr's agent panel lists local panes only. On the hub Mac every pane is a
# viewer onto another machine, so the panel is structurally empty — the agents
# are processes on the remotes and screen detection cannot reach them. The feed
# polls each remote's own server and reports the rollup back in via
# `herdr pane report-agent`. See bin/herdr-agent-feed for the full reasoning.
#
# The plist is GENERATED, not symlinked like keyremap's: it has to name an
# absolute path to the script, launchd does not expand $HOME, and this repo is
# installed on machines with different home directories.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "herdr-agent-feed.sh: not macOS, skipping"; exit 0; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTFILES/macos/com.dotfiles.herdr-agent-feed.plist.in"
DST="$HOME/Library/LaunchAgents/com.dotfiles.herdr-agent-feed.plist"

echo "→ herdr agent feed"

# No herdr, nothing to report into. Not an error: most machines never run it.
if ! command -v herdr &>/dev/null; then
    echo "  herdr not installed — skipping"
    exit 0
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed "s|__HOME__|$HOME|g" "$SRC" > "$DST"

# Unload first so a re-run picks up an edited plist; the feed releases its
# sidebar claims on SIGTERM, so this never strands a stale row.
launchctl unload "$DST" 2>/dev/null || true
launchctl load   "$DST"
echo "  ✓ LaunchAgent installed (com.dotfiles.herdr-agent-feed)"
