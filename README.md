# Dotfiles

Cross-platform personal dotfiles for macOS Apple Silicon and Ubuntu-style Linux.

## Install

Preview the install first:

```sh
./install.sh --dry-run
```

Run the full bootstrap:

```sh
./install.sh
```

Useful options:

```sh
./install.sh --no-packages
./install.sh --no-symlinks
./install.sh --enable-codex-sandbox
```

`--enable-codex-sandbox` applies the Ubuntu AppArmor sysctl used by Codex. It is intentionally opt-in because it changes a system security setting.

The installer backs up existing files before replacing them with symlinks.

## Package Layout

- `packages/macos/Brewfile`: Homebrew formulae and casks for macOS Apple Silicon.
- `packages/ubuntu/apt.txt`: apt packages for Ubuntu-style Linux.
- `packages/go/global.txt`: Go tools installed with `go install`.
- `packages/npm/global.txt`: npm tools installed with `npm install -g` when npm is available.

The Ubuntu package list assumes your configured apt sources provide the listed packages. Add distro-specific setup scripts later if a package needs an external repository.

## Local Overrides

Machine-local customizations should live outside the repo:

- `~/.config/dotfiles/local.zsh` is sourced at the end of `.zshrc`.
- `~/.gitconfig.local` is included by the tracked Git config.
- `~/.ssh/config.local` is included before the tracked SSH hosts.

Examples are provided in:

- `zsh/local.example.zsh`
- `git/gitconfig.local.example`
- `ssh/config.local.example`

## SSH

The SSH example assumes 1Password is the SSH agent on macOS. The `.pub` identity paths are intentional for that setup, and the agent is expected to be forwarded to Ubuntu where needed.

## Checks

Run local checks with:

```sh
make check
```

or:

```sh
./bin/check
```

The check script runs Bash syntax checks, ShellCheck when available, Zsh syntax checks, Git config parsing, and package manifest presence checks.

## Growth Notes

This repo currently uses a small custom installer. If host-specific templates, secrets, or many machine profiles become hard to manage, `chezmoi` would be the next reasonable tool to evaluate.
