#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

dnf_cmd config-manager setopt max_parallel_downloads=10
dnf_cmd config-manager setopt fastestmirror=True
# Optional extras (uncomment in Makefile target if desired):
# dnf_cmd config-manager setopt defaultyes=True
# dnf_cmd config-manager setopt keepcache=True
dnf_cmd config-manager setopt sslcacert=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem 2>/dev/null || true

dnf --dump-main-config | grep -E '^(fastestmirror|max_parallel_downloads) = ' || true
echo "DNF speed tweaks applied."
