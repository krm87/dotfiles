#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

INSTALL_PACKAGES=1
SETUP_SYMLINKS=1
ENABLE_CODEX_SANDBOX=0
DRY_RUN=0

info() {
  printf "\033[1;34m[dotfiles]\033[0m %s\n" "$1"
}

warn() {
  printf "\033[1;33m[dotfiles]\033[0m %s\n" "$1"
}

usage() {
  cat <<USAGE
Usage: ./install.sh [options]

Options:
  --dry-run                 Print planned actions without changing the system.
  --no-packages             Skip package and language-tool installation.
  --no-symlinks             Skip dotfile symlink creation.
  --enable-codex-sandbox    Install the scoped AppArmor profile used by Codex.
  -h, --help                Show this help.
USAGE
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: $*"
    return 0
  fi

  "$@"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --no-packages)
        INSTALL_PACKAGES=0
        ;;
      --no-symlinks)
        SETUP_SYMLINKS=0
        ;;
      --enable-codex-sandbox)
        ENABLE_CODEX_SANDBOX=1
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        warn "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

link_file() {
  local source="$1"
  local target="$2"

  if [ ! -e "$source" ]; then
    warn "Missing source: $source"
    return 1
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    info "Already linked $target -> $source"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: link $target -> $source"
    return 0
  fi

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    local backup
    backup="$target.backup.$(date +%Y%m%d-%H%M%S)"
    mv "$target" "$backup"
    warn "Moved existing $target to $backup"
  fi

  ln -s "$source" "$target"
  info "Linked $target -> $source"
}

install_macos() {
  local brewfile="$DOTFILES_DIR/packages/macos/Brewfile"

  info "Detected macOS"

  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found. Install Homebrew first: https://brew.sh"
    exit 1
  fi

  info "Installing Homebrew bundle"
  run brew bundle --file "$brewfile"
}

read_package_file() {
  local package_file="$1"
  local package

  while IFS= read -r package || [ -n "$package" ]; do
    case "$package" in
      "" | \#*)
        continue
        ;;
      *)
        printf "%s\n" "$package"
        ;;
    esac
  done <"$package_file"
}

install_apt_packages() {
  local package_file="$1"
  local packages=()
  local package

  while IFS= read -r package; do
    packages+=("$package")
  done < <(read_package_file "$package_file")

  if [ "${#packages[@]}" -eq 0 ]; then
    warn "No apt packages found in $package_file"
    return 0
  fi

  run sudo apt-get update
  run sudo apt-get install -y "${packages[@]}"
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    info "Starship already installed"
    return 0
  fi

  info "Installing Starship"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install Starship from https://starship.rs/install.sh"
    return 0
  fi

  curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_atuin() {
  if command -v atuin >/dev/null 2>&1; then
    info "Atuin already installed"
    return 0
  fi

  info "Installing Atuin"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install Atuin from https://setup.atuin.sh"
    return 0
  fi

  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

render_codex_apparmor_profile() {
  local attachment="$1"
  local template="$DOTFILES_DIR/apparmor/codex.template"
  local line

  while IFS= read -r line || [ -n "$line" ]; do
    printf "%s\n" "${line/__CODEX_APPARMOR_ATTACHMENT__/$attachment}"
  done <"$template"
}

warn_legacy_codex_sysctl() {
  local legacy_sysctl="/etc/sysctl.d/99-codex-sandbox.conf"

  if [ -f "$legacy_sysctl" ]; then
    warn "$legacy_sysctl exists from the old installer."
    warn "Remove it manually if you want to rely only on the scoped AppArmor profile."
  fi
}

install_codex_apparmor_profile() {
  if [ "$ENABLE_CODEX_SANDBOX" -ne 1 ]; then
    return 0
  fi

  if [ "$OS" != "Linux" ]; then
    warn "Codex AppArmor profile only applies on Linux"
    return 0
  fi

  if ! command -v apparmor_parser >/dev/null 2>&1; then
    warn "apparmor_parser not found. Install AppArmor before enabling the Codex sandbox profile."
    return 1
  fi

  local attachment="${CODEX_APPARMOR_ATTACHMENT:-}"
  local profile_target="/etc/apparmor.d/codex"
  local tmp_profile

  if [ -z "$attachment" ]; then
    attachment='@{HOME}/{.local/bin/codex,.codex/packages/standalone/{current,releases/*}/bin/codex}'
  fi

  case "$attachment" in
    *\"*)
      warn "CODEX_APPARMOR_ATTACHMENT cannot contain double quotes"
      return 1
      ;;
  esac

  warn "Installing scoped AppArmor profile for Codex sandbox support"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: render Codex AppArmor attachment: $attachment"
    info "DRY RUN: install $profile_target"
    info "DRY RUN: sudo apparmor_parser -r $profile_target"
    return 0
  fi

  tmp_profile="$(mktemp)"
  render_codex_apparmor_profile "$attachment" >"$tmp_profile"
  sudo install -m 0644 "$tmp_profile" "$profile_target"
  sudo apparmor_parser -r "$profile_target"
  rm -f "$tmp_profile"

  warn_legacy_codex_sysctl
}

install_ubuntu() {
  local package_file="$DOTFILES_DIR/packages/ubuntu/apt.txt"

  info "Detected Linux"

  if command -v apt-get >/dev/null 2>&1; then
    install_apt_packages "$package_file"
  else
    warn "Unsupported Linux package manager. Install dependencies manually."
  fi

  install_starship
  install_atuin
}

install_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [ -d "$nvm_dir" ]; then
    info "nvm already installed"
    return 0
  fi

  info "Installing nvm"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install nvm into $nvm_dir"
    return 0
  fi

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_go_tools() {
  local tools_file="$DOTFILES_DIR/packages/go/global.txt"
  local tool

  [ -f "$tools_file" ] || return 0

  if ! command -v go >/dev/null 2>&1; then
    warn "Go not found. Skipping Go tools from $tools_file"
    return 0
  fi

  while IFS= read -r tool || [ -n "$tool" ]; do
    case "$tool" in
      "" | \#*)
        continue
        ;;
      *)
        run go install "$tool"
        ;;
    esac
  done <"$tools_file"
}

install_npm_tools() {
  local tools_file="$DOTFILES_DIR/packages/npm/global.txt"
  local tool

  [ -f "$tools_file" ] || return 0

  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found. Install Node with nvm, then rerun to install npm tools."
    return 0
  fi

  while IFS= read -r tool || [ -n "$tool" ]; do
    case "$tool" in
      "" | \#*)
        continue
        ;;
      *)
        run npm install -g "$tool"
        ;;
    esac
  done <"$tools_file"
}

install_language_tools() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [ -s "$nvm_dir/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$nvm_dir/nvm.sh"
  fi

  install_go_tools
  install_npm_tools
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

  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: ensure $HOME/.ssh exists with 700 permissions"
  else
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
  fi

  if [ ! -f "$HOME/.ssh/config" ] && [ -f "$DOTFILES_DIR/ssh/config.example" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      info "DRY RUN: create $HOME/.ssh/config from ssh/config.example"
    else
      cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
      chmod 600 "$HOME/.ssh/config"
      info "Created ~/.ssh/config from example"
    fi
  fi

  if [ -f "$DOTFILES_DIR/tmux/tmux.conf" ]; then
    link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  fi
}

setup_shell() {
  if command -v zsh >/dev/null 2>&1; then
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ "${SHELL:-}" != "$zsh_path" ]; then
      warn "Default shell is not zsh. Run manually if desired:"
      warn "chsh -s $zsh_path"
    fi
  fi
}

main() {
  parse_args "$@"

  info "Using dotfiles directory: $DOTFILES_DIR"

  if [ "$INSTALL_PACKAGES" -eq 1 ]; then
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
    install_language_tools
  else
    info "Skipping package installation"
  fi

  install_codex_apparmor_profile

  if [ "$SETUP_SYMLINKS" -eq 1 ]; then
    setup_symlinks
  else
    info "Skipping symlink setup"
  fi

  setup_shell

  info "Done. Restart your terminal or run: exec zsh"
}

main "$@"
