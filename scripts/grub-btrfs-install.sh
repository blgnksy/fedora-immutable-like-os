#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

dnf_cmd install -y git make inotify-tools
dnf_cmd remove -y grub-btrfs 2>/dev/null || true

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
git clone --depth 1 https://github.com/Antynea/grub-btrfs "$tmpdir/grub-btrfs"
cd "$tmpdir/grub-btrfs"
sed -i \
  -e 's|^#GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=.*|GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"|' \
  -e 's|^#GRUB_BTRFS_GRUB_DIRNAME=.*|GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"|' \
  -e 's|^#GRUB_BTRFS_MKCONFIG=.*|GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig|' \
  -e 's|^#GRUB_BTRFS_SCRIPT_CHECK=.*|GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check|' \
  config
sudo make install
sudo systemctl enable --now grub-btrfsd.service
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
echo "grub-btrfsd installed."
