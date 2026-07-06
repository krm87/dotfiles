mkcd() {
  if [[ $# -ne 1 || -z "$1" ]]; then
    print -u2 "usage: mkcd <directory>"
    return 2
  fi

  mkdir -p -- "$1" && cd -- "$1"
}

worktree() {
  local dir="$HOME/workspace/.gitrepos"

  if [[ ! -d "$dir" ]]; then
    print -u2 "missing directory: $dir"
    return 1
  fi

  cd -- "$dir"
}
