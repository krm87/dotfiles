export EDITOR="code --wait"

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

case "$(uname)" in
Darwin)
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

    export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
;;
Linux)
    :
;;
esac
