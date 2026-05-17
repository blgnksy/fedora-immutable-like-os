#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

dnf_cmd install -y snapper python3-dnf-plugin-snapper btrfs-assistant
[[ -d /.snapshots ]] || sudo snapper -c root create-config /
sudo snapper -c root set-config ALLOW_USERS="${USER}"
sudo snapper -c root set-config SYNC_ACL=yes
snapper list
echo "Snapper configured for ${USER}."
