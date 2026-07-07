export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/go/bin"
  "$HOME/.dotnet/tools"
  $path
)

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

export NVM_DIR="$HOME/.nvm"

case "$(uname)" in
Darwin)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    _jetbrains_scripts="$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    [[ -d "$_jetbrains_scripts" ]] && path=("$_jetbrains_scripts" $path)

    _onepassword_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    [[ -S "$_onepassword_sock" ]] && export SSH_AUTH_SOCK="$_onepassword_sock"
    unset _jetbrains_scripts _onepassword_sock
;;
Linux)
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    [[ -d /usr/local/go/bin ]] && path=(/usr/local/go/bin $path)
;;
esac

[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

if command -v code >/dev/null 2>&1; then
  export EDITOR="code --wait"
elif command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
else
  export EDITOR="nano"
fi

export VISUAL="$EDITOR"
