#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

info() {
  printf "\033[1;34m[dotfiles]\033[0m %s\n" "$1"
}

warn() {
  printf "\033[1;33m[dotfiles]\033[0m %s\n" "$1"
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target.backup.$(date +%Y%m%d-%H%M%S)"
  fi

  ln -s "$source" "$target"
  info "Linked $target -> $source"
}

install_macos() {
  info "Detected macOS"

  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found. Install Homebrew first: https://brew.sh"
    exit 1
  fi

  info "Installing Homebrew bundle"
  brew bundle --file "$DOTFILES_DIR/Brewfile"
}

install_ubuntu() {
  info "Detected Linux"

  if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y \
      zsh \
      git \
      curl \
      fzf \
      direnv \
      zoxide \
      ripgrep \
      fd-find \
      bat \
      eza \
      shellcheck \
      unzip \
      ca-certificates \
      bubblewrap
  else
    warn "Unsupported Linux package manager. Install dependencies manually."
  fi

  if ! command -v starship >/dev/null 2>&1; then
    info "Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  if ! command -v atuin >/dev/null 2>&1; then
    info "Installing Atuin"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  fi
  echo "kernel.apparmor_restrict_unprivileged_userns=0" | \
  sudo tee /etc/sysctl.d/99-codex-sandbox.conf

  sudo sysctl --system
}

install_nvm() {
  if [ ! -d "$HOME/.nvm" ]; then
    info "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  else
    info "nvm already installed"
  fi
}

setup_symlinks() {
  info "Creating symlinks"

  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

  if [ -f "$DOTFILES_DIR/git/gitconfig" ]; then
    link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
  fi

  if [ -f "$DOTFILES_DIR/git/gitignore_global" ]; then
    link_file "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ ! -f "$HOME/.ssh/config" ] && [ -f "$DOTFILES_DIR/ssh/config.example" ]; then
    cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    info "Created ~/.ssh/config from example"
  fi
  if [ -f "$DOTFILES_DIR/tmux/tmux.conf" ]; then
    link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  fi
}

setup_shell() {
  if command -v zsh >/dev/null 2>&1; then
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ "$SHELL" != "$zsh_path" ]; then
      warn "Default shell is not zsh. Run manually if desired:"
      warn "chsh -s $zsh_path"
    fi
  fi
}

main() {
  info "Using dotfiles directory: $DOTFILES_DIR"

  case "$OS" in
    Darwin)
      install_macos
      ;;
    Linux)
      install_ubuntu
      ;;
    *)
      warn "Unsupported OS: $OS"
      exit 1
      ;;
  esac

  install_nvm
  setup_symlinks
  setup_shell

  info "Done. Restart your terminal or run: exec zsh"
}

main "$@"
