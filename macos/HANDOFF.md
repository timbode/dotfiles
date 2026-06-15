# macOS setup — handoff notes

Working notes for whoever (human or agent) picks this up later. The user-facing
summary is in the repo `README.md`; this file is the *why* and the *loose ends*.

## Goal

Setting up a freshly repaired Mac from scratch. Extend the existing dotfiles repo
(previously shell/prompt only) with a macOS **system-settings** layer so
`bash bootstrap.sh mac` reproduces the user's environment end to end.

## What was added (all under `macos/`, Darwin-guarded, idempotent)

| File | Purpose |
|------|---------|
| `defaults.sh` | Keyboard (smart-text OFF), trackpad (tap-to-click ON, 3-finger-drag OFF, secondary click ON), reversed scroll. Opt-in extras commented at bottom. |
| `keyremap.sh` + `com.dotfiles.keyremap.plist` | Swap **Left Control ↔ Globe/Fn** via `hidutil`, persisted by a LaunchAgent (`com.dotfiles.keyremap`). |
| `rectangle.sh` + `rectangle.plist` | Restore Rectangle window-manager config via `defaults import`. |
| `input-sources.sh` | Enable **ABC (US) + German** keyboard layouts. |
| `window-shortcuts.sh` | **OPT-IN, not auto-run.** Native tiling shortcuts; only for going Rectangle-free. |
| `Brewfile` | GUI casks: vscode, iterm2, rectangle, firefox, logseq, claude. |

`bootstrap.sh` wiring: `install_mac` runs `brew bundle`; a Darwin block runs
`defaults.sh → keyremap.sh → rectangle.sh → input-sources.sh`.

## Key decisions & rationale

- **Values captured from the live reference Mac**, not guessed — the user said
  "the settings here should be the determining factor." Settings already at macOS
  defaults were intentionally left alone (see commented OPTIONAL block in
  `defaults.sh`). Only two explicit user preferences override current state:
  smart-text substitutions OFF, reversed (non-natural) scrolling.
- **Rectangle kept, not replaced by native tiling.** Native macOS `Move & Resize`
  cannot move windows **across displays** (no keyboard shortcut) and cannot
  **cycle** window sizes on repeated presses — both are core to the user's
  workflow. So Rectangle stays and its config is versioned. `window-shortcuts.sh`
  remains as an opt-in native alternative only.
- **No app-cleanup script.** The target is a *fresh* Mac, so there's nothing
  pre-existing to remove. (The reference machine carried some leftover
  third-party apps and LaunchAgents from a prior setup, but they're irrelevant
  to a clean install.)
- **Zoom excluded** from the Brewfile — not one of the user's apps.
- **Brew PATH fix**: after a fresh Homebrew install, `brew` isn't on PATH for the
  rest of the script run; `install_mac` now `eval`s `brew shellenv`
  (`/opt/homebrew` or `/usr/local`).

## Verified vs NOT verified

- ✅ All `*.sh` pass `bash -n`; both `*.plist` pass `plutil -lint`; all 6 cask
  names resolve via `brew info --cask`.
- ⚠️ **Nothing has been applied to any machine and nothing run end-to-end.** This
  has not been exercised on a real fresh Mac.
- ⚠️ `window-shortcuts.sh` menu-item titles ("Left/Right/Top/Bottom") are
  **unverified on macOS 26 Tahoe**. If used, confirm against the actual
  `Window ▸ Move & Resize` menu and adjust. (Opt-in only, so low risk.)
- ⚠️ `input-sources.sh` needs a **logout** to take effect; `defaults`-set
  `AppleEnabledInputSources` occasionally gets massaged by the system — verify
  both layouts appear after first login.
- ⚠️ Rectangle needs **Accessibility permission** granted manually on first launch
  (macOS won't let a script do this).

## Open / future ideas

- Fold the user's extra CLI tools into the Brewfile or `install_mac` (currently
  installed but NOT bootstrapped): `gh node uv micro pandoc typst tectonic
  ffmpeg poppler ghostscript weasyprint sshpass python@3.11`.
- Grow `defaults.sh` via the capture trick: `defaults read > /tmp/a`, change a
  setting in System Settings, `defaults read > /tmp/b`, `diff /tmp/a /tmp/b`, add
  the resulting `defaults write` line.
- Re-capture Rectangle after any change:
  `defaults export com.knollsoft.Rectangle macos/rectangle.plist && plutil -convert xml1 macos/rectangle.plist`.
- `input-sources.sh` uses ABC (id 252) = Apple's modern US layout. Swap to the
  classic "U.S." (id 0) if the user prefers that name.

## Environment facts

- Reference machine: macOS **26.5.1** (Tahoe), Apple Silicon (Homebrew at
  `/opt/homebrew`). Login shell zsh. User is German (US + German layouts).
- Repo is multi-machine: `bash bootstrap.sh <mac|server|cluster|gpu>`. The new
  `macos/` layer is Darwin-only and no-ops elsewhere.
