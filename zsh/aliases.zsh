alias ll="eza -lah --git"
alias la="eza -a"
alias lt="eza --tree"

if command -v bat >/dev/null; then
  alias cat="bat"
elif command -v batcat >/dev/null; then
  alias cat="batcat"
fi

alias fd="fdfind"

alias grep="rg"

alias ws="cd ~/workspace"

alias dots="cd ~/workspace/personal/dotfiles"

alias mc="cd ~/workspace/matchcare"

alias backend="cd ~/workspace/matchcare/backend/dev"

alias frontend="cd ~/workspace/matchcare/frontend/dev"
