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
    # Rust toolchain (needed for eza)
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi

    if ! command -v eza &>/dev/null; then
        echo "→ installing eza"
        cargo install eza
    fi

    if ! command -v starship &>/dev/null; then
        echo "→ installing starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
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
        ~/.fzf/install --all --no-bash --no-fish
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

# Remove p10k instant-prompt block (top of file, before/after guard)
_sedi '/# Enable Powerlevel10k instant prompt/,/^fi$/d' ~/.zshrc
# Remove ZSH_THEME=powerlevel10k line
_sedi '/ZSH_THEME="powerlevel10k/d' ~/.zshrc
# Remove the [[ ! -f ~/.p10k.zsh ]] || source line
_sedi '/p10k\.zsh/d' ~/.zshrc

# Append machine_type + tools source — idempotent
if ! grep -q 'machine_type.zsh' ~/.zshrc; then
    printf '\nsource ~/.machine_type.zsh\nsource ~/.config/shell/tools.zsh\n' >> ~/.zshrc
fi

echo ""
echo "Done. Open a new shell or run: source ~/.zshrc"
echo "Machine type set to: $MACHINE_TYPE"
