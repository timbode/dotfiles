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
```
