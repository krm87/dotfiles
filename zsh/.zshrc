export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

if [[ -d "$HOME/workspace/personal/dotfiles" ]]; then
  export DOTFILES="$HOME/workspace/personal/dotfiles"
fi

source "$DOTFILES/zsh/exports.zsh"
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

. "$HOME/.atuin/bin/env"
