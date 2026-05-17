#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${HOME}/.config/distrobox"
tee "${HOME}/.config/distrobox/distrobox.conf" > /dev/null << 'EOF'
container_additional_volumes="/var/mount:/var/mount:rslave"
EOF
echo "Wrote ~/.config/distrobox/distrobox.conf"
