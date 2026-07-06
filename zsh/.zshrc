# Resolve through the ~/.zshrc symlink so the repo can live anywhere.
if [[ -z "${DOTFILES:-}" ]]; then
  _dotfiles_zshrc="${${(%):-%x}:A}"
  export DOTFILES="${_dotfiles_zshrc:h:h}"
  unset _dotfiles_zshrc
fi

source "$DOTFILES/zsh/exports.zsh"

mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

setopt append_history
setopt autocd
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history
setopt interactive_comments
setopt share_history

# Zsh completion system
autoload -Uz compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
compinit -i -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

source "$DOTFILES/zsh/zinit.zsh"
source "$DOTFILES/zsh/plugins.zsh"

command -v starship >/dev/null && eval "$(starship init zsh)"

source "$DOTFILES/zsh/aliases.zsh"
source "$DOTFILES/zsh/functions.zsh"

command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

if [[ -f "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
elif command -v fzf >/dev/null && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
else
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi

command -v atuin >/dev/null && eval "$(atuin init zsh)"

_dotfiles_local_zsh="$XDG_CONFIG_HOME/dotfiles/local.zsh"
[[ -r "$_dotfiles_local_zsh" ]] && source "$_dotfiles_local_zsh"
unset _dotfiles_local_zsh
