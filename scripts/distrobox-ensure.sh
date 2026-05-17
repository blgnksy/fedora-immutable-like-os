#!/usr/bin/env bash
# Install distrobox via Homebrew when available, otherwise dnf (DNF env from Makefile).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if bash "${SCRIPT_DIR}/distrobox-available.sh"; then
  if command -v distrobox >/dev/null 2>&1; then
    echo "distrobox: $(command -v distrobox)"
  elif rpm -q distrobox >/dev/null 2>&1; then
    echo "distrobox: $(rpm -q distrobox)"
  else
    echo "distrobox: Homebrew ($(command -v brew || echo /home/linuxbrew/.linuxbrew/bin/brew))"
  fi
  exit 0
fi

_brew_bin() {
  local b
  for b in "${BREW:-}" "$(command -v brew 2>/dev/null)" /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -n "$b" && -x "$b" ]] || continue
    echo "$b"
    return 0
  done
  return 1
}

if brew="$(_brew_bin)"; then
  echo "Installing distrobox via Homebrew..."
  "$brew" install distrobox
  exit 0
fi

echo "Installing distrobox via dnf..."
${DNF:-sudo dnf} install -y distrobox
