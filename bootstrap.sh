#!/usr/bin/env bash
# Usage: bash bootstrap.sh <mac|server|cluster>
# Installs tools, symlinks configs, patches existing ~/.zshrc.
# Never touches conda / juliaup / TeX blocks — only removes p10k and appends 2 lines.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── validate ─────────────────────────────────────────────────────────────────
if [[ $# -lt 1 || ! "$1" =~ ^(mac|server|cluster)$ ]]; then
    echo "usage: bash bootstrap.sh <mac|server|cluster>"
    exit 1
fi
MACHINE_TYPE="$1"

# ── portable sed -i ───────────────────────────────────────────────────────────
_sedi() {
    if [[ $(uname -s) == Darwin ]]; then sed -i '' "$@"; else sed -i "$@"; fi
}

# ── install tools ─────────────────────────────────────────────────────────────
install_linux() {
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
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --bin   # binary only; tools.zsh handles shell integration
    fi
}

install_mac() {
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found — install it first: https://brew.sh"
        exit 1
    fi
    for tool in eza starship atuin zoxide fzf; do
        command -v "$tool" &>/dev/null || brew install "$tool"
    done
}

case "$(uname -s)" in
    Darwin) install_mac  ;;
    Linux)  install_linux ;;
esac

# ── symlink configs ───────────────────────────────────────────────────────────
mkdir -p ~/.config/{starship,eza,atuin,shell}

ln -sfn "$DOTFILES/config/shell/tools.zsh"         ~/.config/shell/tools.zsh
ln -sfn "$DOTFILES/config/eza/theme.yml"            ~/.config/eza/theme.yml
ln -sfn "$DOTFILES/config/atuin/config.toml"        ~/.config/atuin/config.toml
for variant in mac server cluster; do
    ln -sfn "$DOTFILES/config/starship/$variant.toml" ~/.config/starship/$variant.toml
done

# ── write machine type (machine-local, not in repo) ───────────────────────────
echo "export MACHINE_TYPE=\"$MACHINE_TYPE\"" > ~/.machine_type.zsh

# ── patch ~/.zshrc ────────────────────────────────────────────────────────────
[[ -f ~/.zshrc ]] || touch ~/.zshrc

BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
cp ~/.zshrc "$BACKUP"
echo "Backed up ~/.zshrc → $BACKUP"

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

echo ""
echo "Done. Open a new shell or run: source ~/.zshrc"
echo "Machine type set to: $MACHINE_TYPE"
