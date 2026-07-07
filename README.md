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

`--enable-codex-sandbox` installs a scoped AppArmor profile for Codex so it can create unprivileged user namespaces for its sandbox without disabling `kernel.apparmor_restrict_unprivileged_userns` globally. It is intentionally opt-in because it changes system security policy.

If an older version of this installer created `/etc/sysctl.d/99-codex-sandbox.conf`, remove that file after installing the AppArmor profile if you want the scoped policy to be the only sandbox exception.

The installer backs up existing files before replacing them with symlinks.

## Package Layout

- `packages/macos/Brewfile`: Homebrew formulae and casks for macOS Apple Silicon.
- `packages/ubuntu/apt.txt`: apt packages for Ubuntu-style Linux. Go is intentionally not installed from apt.
- `packages/go/global.txt`: Go tools installed with `go install`.
- `packages/npm/global.txt`: npm tools installed with `npm install -g` when npm is available.
- `packages/npm/allow-scripts.txt`: npm global packages whose install scripts are approved via `--allow-scripts`.
- `apparmor/codex.template`: AppArmor profile template used by `--enable-codex-sandbox`.

The Ubuntu package list assumes your configured apt sources provide the listed packages. Add distro-specific setup scripts later if a package needs an external repository.

On Linux, the installer fetches the latest stable Go release metadata from `go.dev`, downloads the matching tarball, verifies its SHA-256 checksum, and installs it to `/usr/local/go`.

Atuin is installed under `~/.atuin/bin` on Linux. The dotfiles add that directory to PATH directly and remove Atuin installer profile hooks so generated lines do not get written into the tracked `.zshrc` symlink.

Claude Code has an npm `postinstall` script, so it is listed in `packages/npm/allow-scripts.txt`. This keeps npm 11+ global installs quiet without allowing install scripts for every npm package.

Ghostty is configured by `ghostty/config`, which is linked to `~/.config/ghostty/config`.

tmux uses `bin/tmux-copy` for cross-platform copy-mode clipboard integration. The helper is linked to `~/.local/bin/tmux-copy`; on Linux it uses `wl-copy`, `xclip`, or `xsel`, and on macOS it uses `pbcopy`.

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

The check script runs Bash syntax checks, ShellCheck when available, Zsh syntax checks, Git config parsing, Ghostty config parsing when available, AppArmor template parsing when available, and package manifest presence checks.

Run a read-only machine health check with:

```sh
make doctor
```

or:

```sh
./bin/doctor
```

The doctor reports tool versions, PATH ordering, managed symlinks, package manager availability, Go and Atuin setup, SSH agent status, tmux shell behavior, AppArmor status on Linux, and local override file presence.

## Growth Notes

This repo currently uses a small custom installer. If host-specific templates, secrets, or many machine profiles become hard to manage, `chezmoi` would be the next reasonable tool to evaluate.
