if command -v eza >/dev/null; then
  alias ls="eza"
  alias ll="eza -lah --git"
  alias la="eza -a"
  alias lt="eza --tree"
else
  case "$(uname)" in
    Linux)
      alias ls="ls --color=auto"
      ;;
    Darwin)
      alias ls="ls -G"
      ;;
  esac

  alias ll="ls -lah"
  alias la="ls -A"
  if command -v tree >/dev/null; then
    alias lt="tree"
  else
    alias lt="find . -maxdepth 2 -print"
  fi
fi

if command -v bat >/dev/null; then
  alias cat="bat"
elif command -v batcat >/dev/null; then
  alias cat="batcat"
fi

if command -v fd >/dev/null; then
  alias fd="fd"
elif command -v fdfind >/dev/null; then
  alias fd="fdfind"
fi

command -v rg >/dev/null && alias grep="rg"

alias ws='cd ~/workspace'
alias dots='cd "$DOTFILES"'

[[ -d "$HOME/workspace/matchcare" ]] && alias mc="cd ~/workspace/matchcare"
[[ -d "$HOME/workspace/matchcare/backend/dev" ]] && alias backend="cd ~/workspace/matchcare/backend/dev"
[[ -d "$HOME/workspace/matchcare/frontend/dev" ]] && alias frontend="cd ~/workspace/matchcare/frontend/dev"
