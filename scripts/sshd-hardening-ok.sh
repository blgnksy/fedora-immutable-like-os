#!/usr/bin/env bash
# Return 0 when SSH hardening drop-in exists and disables password auth.
set -euo pipefail

_dropin=/etc/ssh/sshd_config.d/00-hardening.conf

if [[ -r "$_dropin" ]] && \
   grep -qE '^[[:space:]]*PasswordAuthentication[[:space:]]+no' "$_dropin" 2>/dev/null; then
  exit 0
fi

if command -v sudo >/dev/null 2>&1 && \
   sudo -n grep -qE '^[[:space:]]*PasswordAuthentication[[:space:]]+no' "$_dropin" 2>/dev/null; then
  exit 0
fi

# Effective merged config (works when drop-in is applied but not user-readable)
if out="$(sshd -T 2>/dev/null)"; then
  grep -qE '^passwordauthentication no$' <<<"$out" && exit 0
fi
if command -v sudo >/dev/null 2>&1 && out="$(sudo -n sshd -T 2>/dev/null)"; then
  grep -qE '^passwordauthentication no$' <<<"$out" && exit 0
fi

exit 1
