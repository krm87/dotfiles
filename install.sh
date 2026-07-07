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

prepend_path() {
  local dir="$1"

  case ":$PATH:" in
    *:"$dir":*)
      ;;
    *)
      export PATH="$dir:$PATH"
      ;;
  esac
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

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    info "Already linked $target -> $source"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: ensure $(dirname "$target") exists"
    info "DRY RUN: link $target -> $source"
    return 0
  fi

  mkdir -p "$(dirname "$target")"

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

go_linux_arch() {
  case "$(uname -m)" in
    x86_64 | amd64)
      printf "amd64\n"
      ;;
    aarch64 | arm64)
      printf "arm64\n"
      ;;
    armv6l | armv7l)
      printf "armv6l\n"
      ;;
    i386 | i686)
      printf "386\n"
      ;;
    *)
      warn "Unsupported Go architecture: $(uname -m)"
      return 1
      ;;
  esac
}

latest_go_download() {
  local json_file="$1"
  local go_os="$2"
  local go_arch="$3"

  python3 - "$json_file" "$go_os" "$go_arch" <<'PY'
import json
import sys

json_file, go_os, go_arch = sys.argv[1:]

with open(json_file, encoding="utf-8") as fh:
    releases = json.load(fh)

for release in releases:
    if not release.get("stable"):
        continue

    version = release["version"]
    filename = f"{version}.{go_os}-{go_arch}.tar.gz"

    for candidate in release.get("files", []):
        if candidate.get("filename") == filename:
            print(version)
            print(filename)
            print(candidate["sha256"])
            raise SystemExit(0)

raise SystemExit(f"no Go download found for {go_os}-{go_arch}")
PY
}

install_go_linux() {
  local install_prefix="${GO_INSTALL_PREFIX:-/usr/local}"
  local goroot="$install_prefix/go"
  local go_arch
  local json_file
  local archive
  local metadata=()
  local version
  local filename
  local sha256
  local current_version
  local tmp_dir

  if [ "$OS" != "Linux" ]; then
    return 0
  fi

  go_arch="$(go_linux_arch)"

  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install latest stable Go from go.dev to $goroot for linux-$go_arch"
    export PATH="$goroot/bin:$PATH"
    return 0
  fi

  for dependency in curl python3 tar sha256sum; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      warn "$dependency not found. Install dependencies before installing Go."
      return 1
    fi
  done

  case "$install_prefix" in
    "" | /)
      warn "Refusing to install Go with unsafe GO_INSTALL_PREFIX=$install_prefix"
      return 1
      ;;
  esac

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"; trap - RETURN' RETURN
  json_file="$tmp_dir/go-downloads.json"

  info "Fetching latest Go release metadata"
  curl -fsSL "https://go.dev/dl/?mode=json" -o "$json_file"

  mapfile -t metadata < <(latest_go_download "$json_file" "linux" "$go_arch")
  if [ "${#metadata[@]}" -ne 3 ]; then
    warn "Could not determine latest Go download for linux-$go_arch"
    return 1
  fi

  version="${metadata[0]}"
  filename="${metadata[1]}"
  sha256="${metadata[2]}"
  archive="$tmp_dir/$filename"

  current_version="$(go version 2>/dev/null | awk '{print $3}' || true)"
  if [ "$current_version" = "$version" ]; then
    info "Go $version already installed"
    export PATH="$goroot/bin:$PATH"
    return 0
  fi

  info "Downloading $filename"
  curl -fsSL "https://go.dev/dl/$filename" -o "$archive"

  info "Verifying $filename"
  printf "%s  %s\n" "$sha256" "$archive" | sha256sum -c -

  info "Installing Go $version to $goroot"
  sudo rm -rf "$goroot"
  sudo tar -C "$install_prefix" -xzf "$archive"

  export PATH="$goroot/bin:$PATH"
  info "Installed $(go version)"
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
  local atuin_bin_dir="$HOME/.atuin/bin"
  local atuin_bin="$atuin_bin_dir/atuin"

  if command -v atuin >/dev/null 2>&1 || [ -x "$atuin_bin" ]; then
    prepend_path "$atuin_bin_dir"
    info "Atuin already installed"
    remove_atuin_profile_hook
    return 0
  fi

  info "Installing Atuin"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install Atuin from https://setup.atuin.sh"
    info "DRY RUN: remove Atuin installer PATH hook from shell profiles"
    return 0
  fi

  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh |
    INSTALLER_NO_MODIFY_PATH=1 PROFILE=/dev/null sh
  prepend_path "$atuin_bin_dir"
  remove_atuin_profile_hook
}

remove_atuin_profile_hook() {
  local hook=". \"\$HOME/.atuin/bin/env\""
  local source_hook="source \"\$HOME/.atuin/bin/env\""
  local profile
  local tmp

  for profile in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
    [ -e "$profile" ] || continue

    if ! grep -Fq "$hook" "$profile" &&
      ! grep -Fq "$source_hook" "$profile"; then
      continue
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      info "DRY RUN: remove Atuin installer PATH hook from $profile"
      continue
    fi

    tmp="$(mktemp)"
    awk -v hook="$hook" -v source_hook="$source_hook" '
      $0 == hook { next }
      $0 == source_hook { next }
      { print }
    ' "$profile" >"$tmp"
    cat "$tmp" >"$profile"
    rm -f "$tmp"
    info "Removed Atuin installer PATH hook from $profile"
  done
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
  install_go_linux
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

  if ! command -v go >/dev/null 2>&1 && [ "$DRY_RUN" -ne 1 ]; then
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

npm_supports_allow_scripts() {
  npm config ls -l 2>/dev/null |
    grep -E '^[;[:space:]]*allow-scripts =' >/dev/null
}

install_npm_tools() {
  local tools_file="$DOTFILES_DIR/packages/npm/global.txt"
  local allow_scripts_file="$DOTFILES_DIR/packages/npm/allow-scripts.txt"
  local npm_install_args=(install -g)
  local allowed_script
  local tool

  [ -f "$tools_file" ] || return 0

  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found. Install Node with nvm, then rerun to install npm tools."
    return 0
  fi

  if [ -f "$allow_scripts_file" ] && npm_supports_allow_scripts; then
    while IFS= read -r allowed_script; do
      npm_install_args+=(--allow-scripts="$allowed_script")
    done < <(read_package_file "$allow_scripts_file")
  fi

  while IFS= read -r tool || [ -n "$tool" ]; do
    case "$tool" in
      "" | \#*)
        continue
        ;;
      *)
        run npm "${npm_install_args[@]}" "$tool"
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

install_terminfo() {
  local ghostty_terminfo="$DOTFILES_DIR/terminfo/xterm-ghostty.terminfo"
  local tic_output

  if [ "$OS" != "Linux" ]; then
    return 0
  fi

  [ -f "$ghostty_terminfo" ] || return 0

  if ! command -v tic >/dev/null 2>&1; then
    warn "tic not found. Install ncurses-bin to install Ghostty terminfo."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    info "DRY RUN: install xterm-ghostty terminfo into $HOME/.terminfo"
    return 0
  fi

  info "Installing xterm-ghostty terminfo"
  if ! tic_output="$(tic -x -o "$HOME/.terminfo" "$ghostty_terminfo" 2>&1 >/dev/null)"; then
    printf "%s\n" "$tic_output" >&2
    return 1
  fi
}

setup_symlinks() {
  info "Creating symlinks"

  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

  if [ -f "$DOTFILES_DIR/ghostty/config" ]; then
    link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  fi

  if [ -f "$DOTFILES_DIR/bin/tmux-copy" ]; then
    link_file "$DOTFILES_DIR/bin/tmux-copy" "$HOME/.local/bin/tmux-copy"
  fi

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
  install_terminfo

  if [ "$SETUP_SYMLINKS" -eq 1 ]; then
    setup_symlinks
  else
    info "Skipping symlink setup"
  fi

  setup_shell

  info "Done. Restart your terminal or run: exec zsh"
}

main "$@"
