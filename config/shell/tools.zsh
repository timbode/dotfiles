# ~/.local/bin is where Linux binary installers (eza, zoxide, atuin, fzf) land
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ── eza ───────────────────────────────────────────────────────────────────────
export EZA_CONFIG_DIR="$HOME/.config/eza"
# EZA_COLORS per machine type — keeps file-kind colours uniform with the
# active starship palette. theme.yml auto-discovery is unreliable so this
# also serves as a reliable fallback.
case "${MACHINE_TYPE:-mac}" in
    gpu)
        # Deep blue palette matching gpu.toml (color_yellow/aqua/green/red/purple)
        export EZA_COLORS="reset:di=1;38;2;30;136;229:ex=1;38;2;38;166;154:ln=1;38;2;0;172;193:pi=38;2;217;119;6:bd=38;2;239;83;80:cd=38;2;239;83;80:so=38;2;121;134;203"
        ;;
    *)
        # Warm gruvbox palette matching mac/server/cluster starship configs
        export EZA_COLORS="reset:di=1;38;2;104;157;106:ex=1;38;2;22;163;74:ln=1;38;2;8;145;178:pi=38;2;217;119;6:bd=38;2;220;38;38:cd=38;2;220;38;38:so=38;2;147;51;234"
        ;;
esac

if command -v eza &>/dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias l="eza --icons --group-directories-first -lh --git --time-style=long-iso"
    alias la="eza --icons --group-directories-first -lah --git --time-style=long-iso"
    alias lt="eza --icons --group-directories-first --tree --level=2 --git-ignore"
    alias ll="eza --icons --group-directories-first -lh --git --group --time-style=long-iso"
fi

# ── fzf: Ctrl-T (files), Alt-C (cd) ─────────────────────────────────────────
command -v fzf &>/dev/null && source <(fzf --zsh)

# ── zoxide: z <partial>, zi (interactive) ────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── atuin: synced history, rebinds Ctrl-R and Up ─────────────────────────────
# installer drops the binary in ~/.atuin/bin; source its env to get it into PATH
[[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# ── starship: pick palette by machine type ────────────────────────────────────
# MACHINE_TYPE is set in ~/.machine_type.zsh (written by bootstrap.sh, not in repo)
if command -v starship &>/dev/null; then
    case "${MACHINE_TYPE:-mac}" in
        server)  export STARSHIP_CONFIG="$HOME/.config/starship/server.toml"  ;;
        cluster) export STARSHIP_CONFIG="$HOME/.config/starship/cluster.toml" ;;
        gpu)     export STARSHIP_CONFIG="$HOME/.config/starship/gpu.toml"     ;;
        *)       export STARSHIP_CONFIG="$HOME/.config/starship/mac.toml"     ;;
    esac
    eval "$(starship init zsh)"
fi
