# dotfiles

Terminal setup for zsh on macOS and Linux. Covers prompt, file listing, history, and directory navigation. Designed to layer safely on top of existing machine-local config (conda, juliaup, etc.) without touching it.

## Stack

| Tool | Purpose |
|------|---------|
| [Starship](https://starship.rs) | Prompt — Gruvbox powerline, machine-specific accent colour |
| [eza](https://github.com/eza-community/eza) | `ls` replacement with icons and git status |
| [atuin](https://atuin.sh) | Synced shell history, replaces Ctrl-R |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — Ctrl-T (files), Alt-C (cd) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Frecent directory jumps: `z`, `zi` |
| [glab](https://gitlab.com/gitlab-org/cli) | GitLab CLI |

## Machine colours

The first two prompt segments change colour so you know immediately which machine you're on:

| Machine type | Accent | Directory |
|---|---|---|
| `mac` | amber `#d65d0e` | yellow `#d79921` |
| `server` | teal `#458588` | green `#689d6a` |
| `cluster` | purple `#b16286` | amber `#d65d0e` |

## Install

```bash
git clone https://github.com/YOU/dotfiles ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh <mac|server|cluster>
```

The script will:

1. Install any missing tools (Homebrew is installed automatically if absent; other tools via Homebrew on macOS and Rust/curl installers + Homebrew for glab on Linux)
2. Symlink `config/` into `~/.config/`
3. Write `~/.machine_type.zsh` (machine-local, not in this repo)
4. Patch the existing `~/.zshrc`:
   - Remove the p10k instant-prompt block, `ZSH_THEME=powerlevel10k/...`, and the `source ~/.p10k.zsh` line
   - Append `source ~/.machine_type.zsh` and `source ~/.config/shell/tools.zsh`
   - Back up the original to `~/.zshrc.bak.TIMESTAMP` first

Conda, juliaup, TeX, and any other runtime setup already in `~/.zshrc` are never touched.

## macOS system settings

On `mac`, `bootstrap.sh` also applies system preferences via `macos/`:

- `macos/defaults.sh` — keyboard (smart-text substitutions off), trackpad
  (tap-to-click on, three-finger-drag off, secondary click on), reversed
  (non-natural) scrolling. Captured from the reference Mac; an `OPTIONAL`
  block at the bottom holds opt-in extras (key-repeat speed, Finder/Dock
  tweaks, screenshots folder) — uncomment to enable.
- `macos/keyremap.sh` + `com.dotfiles.keyremap.plist` — swaps **Left Control
  ↔ Globe/Fn**. Applied immediately with `hidutil`, then persisted across
  reboots by a LaunchAgent (`com.dotfiles.keyremap`). Edit the plist's JSON to
  remap other keys.

- `macos/rectangle.sh` + `rectangle.plist` — restores [Rectangle](https://rectangleapp.com)
  settings (alternate shortcut set, size **cycling** on repeated presses, Todo
  mode). Rectangle stays the window manager because native tiling can't move
  windows **across displays** or cycle sizes. `bootstrap.sh` imports the plist
  and relaunches Rectangle (first launch needs Accessibility permission, granted
  manually). Re-capture after changes: `defaults export com.knollsoft.Rectangle macos/rectangle.plist && plutil -convert xml1 macos/rectangle.plist`.
- `macos/input-sources.sh` — enables **ABC (US) + German** keyboard layouts.
  Takes effect after a logout.
- `macos/window-shortcuts.sh` — **opt-in alternative**, NOT run by bootstrap.
  Maps Ctrl+Option+Arrows onto native `Window ▸ Move & Resize` halves. Only for
  going Rectangle-free; it has no cross-display or cycling support and would
  collide with Rectangle's shortcuts. Run by hand: `bash macos/window-shortcuts.sh`.

`macos/Brewfile` lists GUI apps (VS Code, iTerm2, Rectangle, Firefox, Logseq,
Claude); `install_mac` runs `brew bundle` over it. Add a `cask "…"` line and
re-run to install more.

All three are idempotent and run only on Darwin. Run any standalone, e.g.
`bash macos/defaults.sh`.

## What stays machine-local

These live in the machine's own `~/.zshrc` and are not managed here:

- conda / miniforge init block
- juliaup PATH block
- TeX PATH
- `alias python=...`
- Any secrets or credentials

## Files

```
bootstrap.sh                  install script
config/
  shell/tools.zsh             sourced at the bottom of ~/.zshrc
  starship/{mac,server,cluster}.toml
  eza/theme.yml
  atuin/config.toml
macos/                        macOS-only (Darwin); run from bootstrap.sh
  defaults.sh                 system preferences via `defaults write`
  keyremap.sh                 Left Control <-> Globe/Fn swap (hidutil)
  com.dotfiles.keyremap.plist LaunchAgent that persists the swap
  rectangle.sh + rectangle.plist  restore Rectangle window-manager settings
  input-sources.sh            ABC (US) + German keyboard layouts
  window-shortcuts.sh         OPT-IN native tiling (not run by bootstrap)
  Brewfile                    GUI apps (casks) installed via `brew bundle`
```
