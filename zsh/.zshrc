# Dotfiles root
export DOTFILES="$HOME/workspace/personal/dotfiles"

# Base environment
source "$DOTFILES/zsh/exports.zsh"

# Plugin manager
source "$DOTFILES/zsh/zinit.zsh"

# Plugins
source "$DOTFILES/zsh/plugins.zsh"

# Prompt
eval "$(starship init zsh)"

# Shell config
source "$DOTFILES/zsh/aliases.zsh"
source "$DOTFILES/zsh/functions.zsh"

# Tool integrations
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi
command -v atuin >/dev/null && eval "$(atuin init zsh)"
