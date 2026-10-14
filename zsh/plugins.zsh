typeset -f zinit >/dev/null || return 0

zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
# Use ZLE on Linux to handle bracketed paste sequences split across SSH reads.
# https://github.com/jeffreytse/zsh-vi-mode/issues/353
if [[ "$OSTYPE" == linux* ]]; then
  ZVM_READKEY_ENGINE=${ZVM_READKEY_ENGINE:-zle}
fi
zinit light jeffreytse/zsh-vi-mode
zinit light zsh-users/zsh-syntax-highlighting
