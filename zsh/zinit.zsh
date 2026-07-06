export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

if [[ ! -f "$XDG_DATA_HOME/zinit/zinit.git/zinit.zsh" ]]; then
    if ! command -v git >/dev/null; then
        print -P "%F{33}Git not found; skipping Zinit install.%f"
        return 0
    fi

    print -P "%F{33}Installing Zinit…%f"
    command mkdir -p "$XDG_DATA_HOME/zinit"
    command chmod g-rwX "$XDG_DATA_HOME/zinit"
    command git clone https://github.com/zdharma-continuum/zinit \
        "$XDG_DATA_HOME/zinit/zinit.git"
fi

[[ -f "$XDG_DATA_HOME/zinit/zinit.git/zinit.zsh" ]] || return 0

source "$XDG_DATA_HOME/zinit/zinit.git/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
