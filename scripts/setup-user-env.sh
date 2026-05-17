#!/usr/bin/env bash
# Resolve the workstation account for user-scoped checks (brew, ~/.local).
# When invoked via "sudo make …-verify", re-exec as SUDO_USER with their HOME.
set -uo pipefail

if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  _home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
  exec sudo -u "${SUDO_USER}" -H \
    SETUP_USER="${SUDO_USER}" SETUP_HOME="${_home}" \
    bash "${SETUP_VERIFY_SCRIPT:-$0}" "$@"
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "verify: do not run as root. Use: make -C ~/setup <phase>-verify (without sudo)." >&2
  exit 2
fi

export SETUP_USER="${SETUP_USER:-${USER}}"
export SETUP_HOME="${SETUP_HOME:-${HOME}}"
