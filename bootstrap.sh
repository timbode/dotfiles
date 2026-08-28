#!/usr/bin/env bash
# Usage: bash bootstrap.sh <mac|server|cluster|gpu>
# Installs zsh + oh-my-zsh (if absent), then tools, symlinks configs, patches ~/.zshrc.
# Idempotent: safe to re-run on machines where bootstrap already ran.
# Never touches conda / juliaup / TeX blocks — only removes p10k and appends 2 lines.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── validate ─────────────────────────────────────────────────────────────────
if [[ $# -lt 1 || ! "$1" =~ ^(mac|server|cluster|gpu)$ ]]; then
    echo "usage: bash bootstrap.sh <mac|server|cluster|gpu>"
    exit 1
fi
MACHINE_TYPE="$1"

# ── portable sed -i ───────────────────────────────────────────────────────────
_sedi() {
    if [[ $(uname -s) == Darwin ]]; then sed -i '' "$@"; else sed -i "$@"; fi
}

# ── install tools ─────────────────────────────────────────────────────────────
_install_fonts_linux() {
    if ! command -v fc-cache &>/dev/null; then
        echo "  ⚠ fontconfig not found — skipping font install (install fontconfig and re-run)"
        return
    fi
    if ! command -v unzip &>/dev/null; then
        echo "  ⚠ unzip not found — skipping font install (install unzip and re-run)"
        return
    fi
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    local tmp url
    if ! fc-list | grep -qi "Fira Code"; then
        echo "→ installing Fira Code"
        tmp=$(mktemp -d)
        url=$(curl -s https://api.github.com/repos/tonsky/FiraCode/releases/latest \
            | grep "browser_download_url" | grep "\.zip" \
            | sed 's/.*"\(https[^"]*\)".*/\1/' | head -1)
        curl -fsSL "$url" -o "$tmp/firacode.zip"
        unzip -q "$tmp/firacode.zip" "ttf/*.ttf" -d "$tmp"
        mv "$tmp/ttf/"*.ttf "$font_dir/"
        rm -rf "$tmp"
    fi
    if ! fc-list | grep -qi "Fira Sans"; then
        echo "→ installing Fira Sans"
        tmp=$(mktemp -d)
        url=$(curl -s https://api.github.com/repos/mozilla/Fira/releases/latest \
            | grep "browser_download_url" | grep "\.zip" \
            | sed 's/.*"\(https[^"]*\)".*/\1/' | head -1)
        curl -fsSL "$url" -o "$tmp/firasans.zip"
        unzip -q "$tmp/firasans.zip" "*/otf/FiraSans*.otf" -d "$tmp"
        find "$tmp" -name "FiraSans*.otf" -exec mv {} "$font_dir/" \;
        rm -rf "$tmp"
    fi
    fc-cache -f "$font_dir"
}

install_linux() {
    # Every guard below is `command -v <tool>`, but bootstrap runs
    # non-interactively, where .zshrc -- and so tools.zsh, which is what puts
    # ~/.local/bin on PATH -- never loads. So every check failed and every tool
    # was redownloaded and reinstalled on each run, however many times it had
    # already been installed.
    #
    # That was not merely wasteful: re-running atuin's installer re-registers its
    # Claude Code hooks into ~/.claude/settings.json, which is a symlink into
    # dotclaude, so a routine bootstrap silently added tracked-config changes and
    # put a second hook alongside the git-push guard on every Bash call.
    # Three prefixes, because the installers disagree: ~/.local/bin for the
    # ones bootstrap places by hand, ~/.atuin/bin and ~/.fzf/bin for the two
    # that insist on their own home.
    export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$HOME/.fzf/bin:$PATH"

    # ── zsh ──────────────────────────────────────────────────────────────────
    if ! command -v zsh &>/dev/null; then
        echo "→ installing zsh"
        sudo apt-get update -qq && sudo apt-get install -y zsh
    fi

    # ── btop ─────────────────────────────────────────────────────────────────
    if ! command -v btop &>/dev/null; then
        echo "→ installing btop"
        sudo apt-get update -qq && sudo apt-get install -y btop
    fi

    # ── oh-my-zsh ─────────────────────────────────────────────────────────────
    # RUNZSH=no  → don't exec zsh when done; CHSH=no → we handle chsh ourselves
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "→ installing oh-my-zsh"
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    # ── default shell ─────────────────────────────────────────────────────────
    if [[ "$(basename "$SHELL")" != "zsh" ]]; then
        echo "→ setting default shell to zsh"
        chsh -s "$(command -v zsh)" || \
            echo "  chsh failed — run manually: chsh -s $(command -v zsh)"
    fi

    if ! command -v eza &>/dev/null; then
        echo "→ installing eza"
        mkdir -p ~/.local/bin
        EZA_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep "browser_download_url.*eza_x86_64-unknown-linux-gnu.tar.gz\"" \
            | sed 's/.*"\(https[^"]*\)".*/\1/')
        curl -fsSL "$EZA_URL" | tar xz -C /tmp
        mv /tmp/eza ~/.local/bin/eza
    fi

    if ! command -v starship &>/dev/null; then
        echo "→ installing starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir ~/.local/bin
    fi

    if ! command -v atuin &>/dev/null; then
        echo "→ installing atuin"
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    fi

    if ! command -v zoxide &>/dev/null; then
        echo "→ installing zoxide"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    if ! command -v fzf &>/dev/null; then
        echo "→ installing fzf"
        [[ ! -d ~/.fzf ]] && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --bin   # binary only; tools.zsh handles shell integration
    fi

    if ! command -v glab &>/dev/null; then
        echo "→ installing glab"
        GLAB_TAG=$(curl -s "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" \
            | grep -o '"tag_name":"[^"]*"' | head -1 | sed 's/"tag_name":"//;s/"//')
        GLAB_VER="${GLAB_TAG#v}"
        GLAB_TMP=$(mktemp -d)
        curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_TAG}/downloads/glab_${GLAB_VER}_linux_amd64.tar.gz" \
            | tar xz -C "$GLAB_TMP"
        mv "$GLAB_TMP/bin/glab" ~/.local/bin/glab
        rm -rf "$GLAB_TMP"
    fi

    # Fonts are cosmetic, headless servers render none, and this is the last step
    # before the symlink section -- so an unguarded failure here (missing unzip, a
    # changed archive layout, a rate-limited API yielding an empty URL) aborts
    # bootstrap under `set -e` and silently skips every symlink and the ~/.zshrc
    # patch. Same lesson as the macOS block below.
    _install_fonts_linux || echo "  ⚠ font install failed — continuing"
}

install_mac() {
    # ── oh-my-zsh (macOS ships with zsh already) ──────────────────────────────
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "→ installing oh-my-zsh"
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if ! command -v brew &>/dev/null; then
        echo "→ installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Put brew on PATH for THIS script run (fresh installs aren't on PATH yet —
    # .zprofile only adds it for new shells). Covers Apple Silicon + Intel paths.
    if ! command -v brew &>/dev/null; then
        for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
        done
    fi
    for tool in eza starship atuin zoxide fzf glab; do
        command -v "$tool" &>/dev/null || brew install "$tool"
    done
    for cask in font-fira-code-nerd-font font-fira-code font-fira-sans; do
        brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
    done
    # GUI apps (idempotent: skips anything already installed)
    brew bundle --file="$DOTFILES/macos/Brewfile"
}

case "$(uname -s)" in
    Darwin) install_mac  ;;
    Linux)  install_linux ;;
esac

# ── macOS system settings (Darwin only) ───────────────────────────────────────
# Each step is independent — guard every call so one failure can't abort the
# rest (bootstrap runs under `set -e`; an unguarded non-zero exit here would
# skip every later step, e.g. a broken dock.sh silently dropping keyremap.sh).
if [[ $(uname -s) == Darwin ]]; then
    for script in defaults dock keyremap rectangle input-sources herdr-agent-feed; do
        bash "$DOTFILES/macos/$script.sh" || echo "  ⚠ macos/$script.sh failed — continuing"
    done
    # window-shortcuts.sh (native tiling) is intentionally NOT run here — it would
    # collide with Rectangle. Run it by hand only if you go Rectangle-free.
fi

# ── symlink configs ───────────────────────────────────────────────────────────
mkdir -p ~/.config/{starship,eza,atuin,shell}

ln -sfn "$DOTFILES/config/shell/tools.zsh"         ~/.config/shell/tools.zsh
ln -sfn "$DOTFILES/config/eza/theme.yml"            ~/.config/eza/theme.yml
ln -sfn "$DOTFILES/config/atuin/config.toml"        ~/.config/atuin/config.toml
for variant in mac server cluster gpu; do
    ln -sfn "$DOTFILES/config/starship/$variant.toml" ~/.config/starship/$variant.toml
done
for variant in server cluster gpu; do
    mkdir -p ~/.config/eza/$variant
    ln -sfn "$DOTFILES/config/eza/$variant.yml" ~/.config/eza/$variant/theme.yml
done

# ── link repo scripts into ~/.local/bin ───────────────────────────────────────
# tools.zsh already puts ~/.local/bin on PATH. Linking rather than copying means
# a later `git pull` updates the script with no bootstrap re-run.
mkdir -p ~/.local/bin
for script in "$DOTFILES"/bin/*; do
    [[ -e "$script" ]] || continue   # unmatched glob stays literal when bin/ is empty
    ln -sfn "$script" ~/.local/bin/"$(basename "$script")"
done

# ── write machine type (machine-local, not in repo) ───────────────────────────
echo "export MACHINE_TYPE=\"$MACHINE_TYPE\"" > ~/.machine_type.zsh

# ── patch ~/.zshrc ────────────────────────────────────────────────────────────
[[ -f ~/.zshrc ]] || touch ~/.zshrc

# Snapshot before the edits, but keep it only if they actually changed anything.
# This script is meant to be re-runnable, and an unconditional backup left a
# ~/.zshrc.bak.<timestamp> behind on every single run.
_zshrc_before="$(mktemp)"
cp ~/.zshrc "$_zshrc_before"

# Neutralise ZSH_THEME (handles any quote style)
_sedi 's/ZSH_THEME=.*/ZSH_THEME=""/' ~/.zshrc
# Remove direct source lines for p10k (covers both install styles)
_sedi '/powerlevel10k\/powerlevel10k\.zsh-theme/d' ~/.zshrc
_sedi '/p10k\.zsh/d' ~/.zshrc
# Remove atuin init — tools.zsh handles it (avoids double init)
_sedi '/atuin\/bin\/env/d' ~/.zshrc
_sedi '/atuin init zsh/d' ~/.zshrc
# Disable p10k wizard in case p10k is still on the load path
grep -q 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD' ~/.zshrc || \
    echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Append machine_type + tools source — idempotent
if ! grep -q 'machine_type.zsh' ~/.zshrc; then
    printf '\nsource ~/.machine_type.zsh\nsource ~/.config/shell/tools.zsh\n' >> ~/.zshrc
fi

if cmp -s "$_zshrc_before" ~/.zshrc; then
    rm -f "$_zshrc_before"
else
    BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$_zshrc_before" "$BACKUP"
    echo "Backed up ~/.zshrc → $BACKUP"
fi

echo ""
echo "Done. Open a new shell or run: source ~/.zshrc"
echo "Machine type set to: $MACHINE_TYPE"
