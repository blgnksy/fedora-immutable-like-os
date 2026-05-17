#!/usr/bin/env bash
# Exit 0 when distrobox is on PATH, installed as an RPM, or via Homebrew.
set -euo pipefail

_uhome="${SETUP_HOME:-${HOME}}"

if command -v distrobox >/dev/null 2>&1; then
  exit 0
fi

if rpm -q distrobox >/dev/null 2>&1; then
  exit 0
fi

_brew_bin() {
  local b
  for b in \
    "${BREW:-}" \
    "$(command -v brew 2>/dev/null || true)" \
    /home/linuxbrew/.linuxbrew/bin/brew \
    "${_uhome}/.linuxbrew/Homebrew/bin/brew" \
    "${_uhome}/.linuxbrew/bin/brew"; do
    [[ -n "$b" && -x "$b" ]] || continue
    echo "$b"
    return 0
  done
  return 1
}

if brew="$(_brew_bin)"; then
  if "$brew" list distrobox &>/dev/null 2>&1; then
    prefix="$("$brew" --prefix distrobox 2>/dev/null || true)"
    if [[ -n "${prefix}" && -x "${prefix}/bin/distrobox" ]]; then
      exit 0
    fi
  fi
fi

exit 1
