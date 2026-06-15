# ~/.local/bin is where Linux binary installers (eza, zoxide, atuin, fzf) land
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ── eza ───────────────────────────────────────────────────────────────────────
export EZA_CONFIG_DIR="$HOME/.config/eza"
# Comprehensive EZA_COLORS per machine type — covers every visible column so
# theme.yml (which wins over EZA_COLORS for any key it defines) cannot bleed
# warm gruvbox into palette-themed machines.  theme.yml is stripped to only
# colourful:true + file_type + mount_point/special filekinds.
#
# Key codes: di=dir  ex=exec  ln=symlink  pi=pipe  bd/cd=devices  so=socket
#            hd=header  da=date  uu=you  un=other-user  gu=your-group  gn=other-group
#            nk/nm/ng/nt=size(k/M/G/T)  uk/um/ug/ut=units
#            uw=user-write  ux=user-exec  gr/gw/gx=group-perms  tr/tw/tx=other-perms
#            xx=punctuation  ga/gm/gd/gv/gt/gi/gc=git  Gm/Go/Gc/Gd=repo
case "${MACHINE_TYPE:-mac}" in
    gpu)
        # Blue/indigo palette — dir=#1e88e5  date/kilo=#00acc1  user=#26a69a
        _ec="reset"
        _ec+=":di=1;38;2;30;136;229:ex=1;38;2;38;166;154:ln=1;38;2;0;172;193"
        _ec+=":pi=38;2;57;73;171:bd=38;2;239;83;80:cd=38;2;239;83;80:so=38;2;57;73;171"
        _ec+=":hd=1;4;38;2;30;136;229:da=38;2;0;172;193"
        _ec+=":uu=1;38;2;38;166;154:un=2;38;2;38;166;154:gu=38;2;30;136;229:gn=2;38;2;38;166;154"
        _ec+=":nk=38;2;0;172;193:nm=38;2;30;136;229:ng=38;2;57;73;171:nt=38;2;57;73;171"
        _ec+=":uk=2;38;2;38;166;154:um=2;38;2;38;166;154:ug=2;38;2;38;166;154:ut=2;38;2;38;166;154"
        _ec+=":uw=38;2;121;134;203:ux=38;2;239;83;80"
        _ec+=":gr=2;38;2;38;166;154:gw=2;38;2;38;166;154:gx=2;38;2;38;166;154"
        _ec+=":tr=2;38;2;38;166;154:tw=2;38;2;38;166;154:tx=2;38;2;38;166;154:xx=2;38;2;38;166;154"
        _ec+=":ga=1;38;2;38;166;154:gm=38;2;30;136;229:gd=38;2;239;83;80:gv=38;2;0;172;193"
        _ec+=":gt=38;2;57;73;171:gi=2;38;2;38;166;154:gc=1;38;2;239;83;80"
        _ec+=":Gm=38;2;38;166;154:Go=38;2;121;134;203:Gc=38;2;38;166;154:Gd=38;2;30;136;229"
        export EZA_COLORS="$_ec"; unset _ec
        ;;
    server)
        # Teal palette — dir=#0d9488  date/kilo=#2dd4bf  user=#14b8a6
        _ec="reset"
        _ec+=":di=1;38;2;13;148;136:ex=1;38;2;45;212;191:ln=1;38;2;94;234;212"
        _ec+=":pi=38;2;15;118;110:bd=38;2;248;113;113:cd=38;2;248;113;113:so=38;2;17;94;89"
        _ec+=":hd=1;4;38;2;13;148;136:da=38;2;45;212;191"
        _ec+=":uu=1;38;2;20;184;166:un=2;38;2;20;184;166:gu=38;2;13;148;136:gn=2;38;2;20;184;166"
        _ec+=":nk=38;2;45;212;191:nm=38;2;20;184;166:ng=38;2;13;148;136:nt=38;2;15;118;110"
        _ec+=":uk=2;38;2;20;184;166:um=2;38;2;20;184;166:ug=2;38;2;20;184;166:ut=2;38;2;20;184;166"
        _ec+=":uw=38;2;94;234;212:ux=38;2;248;113;113"
        _ec+=":gr=2;38;2;20;184;166:gw=2;38;2;20;184;166:gx=2;38;2;20;184;166"
        _ec+=":tr=2;38;2;20;184;166:tw=2;38;2;20;184;166:tx=2;38;2;20;184;166:xx=2;38;2;20;184;166"
        _ec+=":ga=1;38;2;45;212;191:gm=38;2;20;184;166:gd=38;2;248;113;113:gv=38;2;94;234;212"
        _ec+=":gt=38;2;15;118;110:gi=2;38;2;20;184;166:gc=1;38;2;248;113;113"
        _ec+=":Gm=38;2;45;212;191:Go=38;2;15;118;110:Gc=38;2;45;212;191:Gd=38;2;20;184;166"
        export EZA_COLORS="$_ec"; unset _ec
        ;;
    cluster)
        # Violet palette — dir=#7c3aed  date/kilo=#a78bfa  user=#8b5cf6
        _ec="reset"
        _ec+=":di=1;38;2;124;58;237:ex=1;38;2;167;139;250:ln=1;38;2;196;181;253"
        _ec+=":pi=38;2;109;40;217:bd=38;2;248;113;113:cd=38;2;248;113;113:so=38;2;91;33;182"
        _ec+=":hd=1;4;38;2;124;58;237:da=38;2;167;139;250"
        _ec+=":uu=1;38;2;139;92;246:un=2;38;2;139;92;246:gu=38;2;124;58;237:gn=2;38;2;139;92;246"
        _ec+=":nk=38;2;167;139;250:nm=38;2;139;92;246:ng=38;2;124;58;237:nt=38;2;109;40;217"
        _ec+=":uk=2;38;2;139;92;246:um=2;38;2;139;92;246:ug=2;38;2;139;92;246:ut=2;38;2;139;92;246"
        _ec+=":uw=38;2;196;181;253:ux=38;2;248;113;113"
        _ec+=":gr=2;38;2;139;92;246:gw=2;38;2;139;92;246:gx=2;38;2;139;92;246"
        _ec+=":tr=2;38;2;139;92;246:tw=2;38;2;139;92;246:tx=2;38;2;139;92;246:xx=2;38;2;139;92;246"
        _ec+=":ga=1;38;2;167;139;250:gm=38;2;139;92;246:gd=38;2;248;113;113:gv=38;2;196;181;253"
        _ec+=":gt=38;2;109;40;217:gi=2;38;2;139;92;246:gc=1;38;2;248;113;113"
        _ec+=":Gm=38;2;167;139;250:Go=38;2;109;40;217:Gc=38;2;167;139;250:Gd=38;2;139;92;246"
        export EZA_COLORS="$_ec"; unset _ec
        ;;
    *)
        # Warm amber (mac) — dir=#d79921  date/kilo=#689d6a  user=#d79921
        _ec="reset"
        _ec+=":di=1;38;2;215;153;33:ex=1;38;2;152;151;26:ln=1;38;2;69;133;136"
        _ec+=":pi=38;2;214;93;14:bd=38;2;204;36;29:cd=38;2;204;36;29:so=38;2;177;98;134"
        _ec+=":hd=1;4;38;2;215;153;33:da=38;2;104;157;106"
        _ec+=":uu=1;38;2;215;153;33:un=2;38;2;152;151;26:gu=38;2;214;93;14:gn=2;38;2;152;151;26"
        _ec+=":nk=38;2;104;157;106:nm=38;2;214;93;14:ng=38;2;204;36;29:nt=38;2;204;36;29"
        _ec+=":uk=2;38;2;152;151;26:um=2;38;2;152;151;26:ug=2;38;2;152;151;26:ut=2;38;2;152;151;26"
        _ec+=":uw=38;2;215;153;33:ux=38;2;204;36;29"
        _ec+=":gr=2;38;2;152;151;26:gw=2;38;2;152;151;26:gx=2;38;2;152;151;26"
        _ec+=":tr=2;38;2;152;151;26:tw=2;38;2;152;151;26:tx=2;38;2;152;151;26:xx=2;38;2;152;151;26"
        _ec+=":ga=1;38;2;104;157;106:gm=38;2;215;153;33:gd=38;2;204;36;29:gv=38;2;104;157;106"
        _ec+=":gt=38;2;177;98;134:gi=2;38;2;152;151;26:gc=1;38;2;204;36;29"
        _ec+=":Gm=38;2;104;157;106:Go=38;2;177;98;134:Gc=38;2;104;157;106:Gd=38;2;215;153;33"
        export EZA_COLORS="$_ec"; unset _ec
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
