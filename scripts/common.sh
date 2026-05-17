#!/usr/bin/env bash
# Shared helpers for workstation setup scripts
set -euo pipefail

dnf_cmd() {
  if command -v dnf-host >/dev/null 2>&1; then
    sudo dnf-host "$@"
  else
    sudo dnf "$@"
  fi
}

brew_shellenv() {
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    :
  else
    echo "Homebrew not installed — skip or run: make phase3-brew-deps" >&2
    return 1
  fi
}
