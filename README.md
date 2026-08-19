# dotfiles

Terminal setup for zsh on macOS and Linux. Covers prompt, file listing, history, and directory navigation. Designed to layer safely on top of existing machine-local config (conda, juliaup, etc.) without touching it.

## Stack

| Tool | Purpose |
|------|---------|
| [zsh](https://www.zsh.org) + [oh-my-zsh](https://ohmyz.sh) | Shell and plugin framework |
| [Starship](https://starship.rs) | Prompt — monochromatic powerline, machine-specific palette |
| [eza](https://github.com/eza-community/eza) | `ls` replacement with icons and git status |
| [atuin](https://atuin.sh) | Synced shell history, replaces Ctrl-R |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — Ctrl-T (files), Alt-C (cd) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Frecent directory jumps: `z`, `zi` |
| [glab](https://gitlab.com/gitlab-org/cli) | GitLab CLI |

## Machine palettes

Each machine type gets a fully monochromatic colour palette applied consistently to both the starship prompt and all eza listing columns (headers, dates, sizes, permissions, git status, filenames):

| Machine type | Palette | Directory segment | eza directories |
|---|---|---|---|
| `mac` | warm amber | `#d79921` golden | `#d79921` |
| `server` | deep teal | `#0d9488` teal-600 | `#0d9488` |
| `cluster` | deep violet | `#7c3aed` violet-600 | `#7c3aed` |
| `gpu` | deep blue | `#1e88e5` blue-600 | `#1e88e5` |

The colour is set once in `MACHINE_TYPE` (written by bootstrap, not in this repo) and picked up by both starship and `EZA_COLORS` at shell startup.

## Install

```bash
git clone https://github.com/YOU/dotfiles ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh <mac|server|cluster|gpu>
```

The script will:

1. **Linux only:** install zsh and btop via apt-get if missing, install oh-my-zsh if `~/.oh-my-zsh` is absent, and switch the default shell to zsh
2. **macOS only:** install oh-my-zsh if absent
3. Install any missing tools (Homebrew + casks on macOS; curl/binary installers on Linux)
4. Symlink `config/` into `~/.config/`
5. Write `~/.machine_type.zsh` (machine-local, not in this repo)
6. Patch the existing `~/.zshrc`:
   - Remove the p10k instant-prompt block, `ZSH_THEME=powerlevel10k/...`, and the `source ~/.p10k.zsh` line
   - Append `source ~/.machine_type.zsh` and `source ~/.config/shell/tools.zsh`
   - Back up the original to `~/.zshrc.bak.TIMESTAMP` first

Re-running on an existing machine is safe — every step is idempotent.

Conda, juliaup, TeX, and any other runtime setup already in `~/.zshrc` are never touched.

## macOS system settings

On `mac`, `bootstrap.sh` also applies system preferences via `macos/`:

- `macos/defaults.sh` — keyboard (smart-text substitutions off), trackpad
  (tap-to-click on, three-finger-drag off, secondary click on), reversed
  (non-natural) scrolling. Captured from the reference Mac; an `OPTIONAL`
  block at the bottom holds opt-in extras (key-repeat speed, Finder
  tweaks, screenshots folder) — uncomment to enable.
- `macos/dock.sh` — Dock **behaviour** (auto-hide on, magnification on,
  38px icons / 93px magnified, recents shown, bottom-right hot corner →
  Quick Note) plus the **pinned-app layout**, rebuilt with `dockutil`. Apps
  that aren't installed are skipped, so third-party/web-app tiles appear only
  once their `.app` exists. Re-capture the knobs from `defaults read
  com.apple.dock`; edit the `add_app` list to change pinned apps.
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
Claude) plus CLI formulas (`dockutil` used by `dock.sh`, `btop`); `install_mac`
runs `brew bundle` over it. Add a `cask "…"` (or `brew "…"`) line and re-run to
install more.

All of these are idempotent and run only on Darwin. Run any standalone, e.g.
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
  shell/tools.zsh             sourced at the bottom of ~/.zshrc; sets EZA_COLORS per machine
  starship/{mac,server,cluster,gpu}.toml
  eza/
    theme.yml                 minimal shared base (colourful + file_type only)
    {server,cluster,gpu}.yml  per-machine theme files (symlinking handled by bootstrap)
  atuin/config.toml
macos/                        macOS-only (Darwin); run from bootstrap.sh
  defaults.sh                 system preferences via `defaults write`
  dock.sh                     Dock behaviour + pinned-app layout (dockutil)
  keyremap.sh                 Left Control <-> Globe/Fn swap (hidutil)
  com.dotfiles.keyremap.plist LaunchAgent that persists the swap
  rectangle.sh + rectangle.plist  restore Rectangle window-manager settings
  input-sources.sh            ABC (US) + German keyboard layouts
  window-shortcuts.sh         OPT-IN native tiling (not run by bootstrap)
  Brewfile                    GUI apps (casks) installed via `brew bundle`
  HANDOFF.md                  design rationale + open items
```
