# ~/.local/bin is where Linux binary installers (eza, zoxide, atuin, fzf) land
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ── eza ───────────────────────────────────────────────────────────────────────
# Per-machine eza theme: lazily create ~/.config/eza/<variant>/theme.yml on
# first run by symlinking from the dotfiles dir (derived from the existing
# theme.yml symlink so no hard-coded dotfiles path is needed).
_eza_setup_theme() {
    local variant="$1" dir="$HOME/.config/eza/$variant"
    if [[ ! -f "$dir/theme.yml" ]]; then
        mkdir -p "$dir"
        local src; src="$(readlink "$HOME/.config/eza/theme.yml" 2>/dev/null)"
        [[ -n "$src" ]] && ln -sf "${src%theme.yml}${variant}.yml" "$dir/theme.yml"
    fi
    export EZA_CONFIG_DIR="$dir"
}

case "${MACHINE_TYPE:-mac}" in
    gpu)
        _eza_setup_theme gpu
        # Deep blue: dir=#1e88e5 exe=#26a69a ln=#00acc1
        export EZA_COLORS="reset:di=1;38;2;30;136;229:ex=1;38;2;38;166;154:ln=1;38;2;0;172;193:pi=38;2;217;119;6:bd=38;2;239;83;80:cd=38;2;239;83;80:so=38;2;121;134;203"
        ;;
    server)
        _eza_setup_theme server
        # Deep teal: dir=#0d9488 exe=#2dd4bf ln=#5eead4
        export EZA_COLORS="reset:di=1;38;2;13;148;136:ex=1;38;2;45;212;191:ln=1;38;2;94;234;212:pi=38;2;15;118;110:bd=38;2;248;113;113:cd=38;2;248;113;113:so=38;2;17;94;89"
        ;;
    cluster)
        _eza_setup_theme cluster
        # Deep violet: dir=#7c3aed exe=#a78bfa ln=#c4b5fd
        export EZA_COLORS="reset:di=1;38;2;124;58;237:ex=1;38;2;167;139;250:ln=1;38;2;196;181;253:pi=38;2;109;40;217:bd=38;2;248;113;113:cd=38;2;248;113;113:so=38;2;91;33;182"
        ;;
    *)
        export EZA_CONFIG_DIR="$HOME/.config/eza"
        # Warm amber (mac): dir=#d79921 exe=#98971a ln=#458588
        export EZA_COLORS="reset:di=1;38;2;215;153;33:ex=1;38;2;152;151;26:ln=1;38;2;69;133;136:pi=38;2;214;93;14:bd=38;2;204;36;29:cd=38;2;204;36;29:so=38;2;177;98;134"
        ;;
esac
unset -f _eza_setup_theme

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
