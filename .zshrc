eval $(/opt/homebrew/bin/brew shellenv)

# ALIASES
alias vim="nvim"
alias vi="nvim"
alias nano="nvim"

## OH MY ZSH
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
eval "$(direnv hook zsh)"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit

## Terraform
complete -o nospace -C /opt/homebrew/bin/terraform terraform
