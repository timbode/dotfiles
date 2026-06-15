# ~/.local/bin is where Linux binary installers (eza, zoxide, atuin, fzf) land
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ── eza ───────────────────────────────────────────────────────────────────────
export EZA_CONFIG_DIR="$HOME/.config/eza"
# EZA_COLORS per machine type — keeps file-kind colours uniform with the
# active starship palette. theme.yml auto-discovery is unreliable so this
# also serves as a reliable fallback.
case "${MACHINE_TYPE:-mac}" in
    gpu)
        # Deep blue: dir=#1e88e5 exe=#26a69a ln=#00acc1 (color_yellow/green/aqua)
        export EZA_COLORS="reset:di=1;38;2;30;136;229:ex=1;38;2;38;166;154:ln=1;38;2;0;172;193:pi=38;2;217;119;6:bd=38;2;239;83;80:cd=38;2;239;83;80:so=38;2;121;134;203"
        ;;
    server)
        # Teal/green: dir=#689d6a exe=#458588 ln=#98971a (color_yellow/blue/green)
        export EZA_COLORS="reset:di=1;38;2;104;157;106:ex=1;38;2;69;133;136:ln=1;38;2;152;151;26:pi=38;2;214;93;14:bd=38;2;204;36;29:cd=38;2;204;36;29:so=38;2;177;98;134"
        ;;
    cluster)
        # Magenta-orange: dir=#d65d0e exe=#689d6a ln=#458588 (color_yellow/aqua/blue)
        export EZA_COLORS="reset:di=1;38;2;214;93;14:ex=1;38;2;104;157;106:ln=1;38;2;69;133;136:pi=38;2;177;98;134:bd=38;2;204;36;29:cd=38;2;204;36;29:so=38;2;177;98;134"
        ;;
    *)
        # Warm amber (mac): dir=#d79921 exe=#98971a ln=#458588 (color_yellow/green/blue)
        export EZA_COLORS="reset:di=1;38;2;215;153;33:ex=1;38;2;152;151;26:ln=1;38;2;69;133;136:pi=38;2;214;93;14:bd=38;2;204;36;29:cd=38;2;204;36;29:so=38;2;177;98;134"
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
