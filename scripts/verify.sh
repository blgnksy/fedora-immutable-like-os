#!/usr/bin/env bash
# Post-install verification for workstation setup phases.
# Usage: verify.sh <phase0|phase1|phase1-gpu|phase2|phase3|phase4|phase5|phase6|all>
# Do not use sudo — host checks need no root; sudo breaks brew and ~/.local paths.
set -uo pipefail

SETUP_VERIFY_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
# shellcheck source=setup-user-env.sh
source "$(dirname "${BASH_SOURCE[0]}")/setup-user-env.sh"

FAIL=0
WARN=0

ok()   { echo "  OK   $*"; }
warn() { echo "  WARN $*"; WARN=$((WARN + 1)); }
fail() { echo "  FAIL $*"; FAIL=$((FAIL + 1)); }

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    ok "$desc"
  else
    fail "$desc"
  fi
}

check_warn() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    ok "$desc"
  else
    warn "$desc"
  fi
}

section() {
  echo ""
  echo "=== $* ==="
}

phase0() {
  section "Phase 0 — Btrfs layout"
  check "Root is btrfs" test "$(findmnt -no FSTYPE /)" = "btrfs"
  check_warn "Home subvolume mount" bash -c 'findmnt -no SUBVOLNAME /home 2>/dev/null | grep -qx home'
}

phase1() {
  section "Phase 1 — host (pre-GPU checks)"
  check "DNF fastestmirror enabled" grep -q '^fastestmirror=True' /etc/dnf/dnf.conf
  check "DNF max_parallel_downloads" grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf
  check "RPM Fusion free repo" bash -c 'test -f /etc/yum.repos.d/rpmfusion-free-updates.repo || ls /etc/yum.repos.d/rpmfusion-free*.repo &>/dev/null'
  check "openssh-server installed" rpm -q openssh-server
  check "sshd active" systemctl is-active sshd
  check "sshd hardening drop-in (run: make phase1-ssh)" bash "$(dirname "${BASH_SOURCE[0]}")/sshd-hardening-ok.sh"
  check "gdb installed" rpm -q gdb
  check "NVIDIA 580xx akmod package" rpm -q akmod-nvidia-580xx
  check "Podman installed" rpm -q podman
  check "Distrobox installed (dnf or brew)" bash "$(dirname "${BASH_SOURCE[0]}")/distrobox-available.sh"
  check "CDI spec exists" test -f /etc/cdi/nvidia.yaml
  check_warn "nvidia-ctk lists GPUs" nvidia-ctk cdi list
  check "refresh-cdi script (run: make phase1-refresh-cdi-script)" test -x "${SETUP_HOME}/.local/bin/refresh-cdi"
  check_warn "ffmpeg (not ffmpeg-free)" rpm -q ffmpeg
  check_warn "fail2ban (optional)" systemctl is-active fail2ban
}

phase1_gpu() {
  section "Phase 1 — GPU (run after reboot)"
  check "nvidia-smi works" nvidia-smi
  check_warn "GTX 1070 / driver 580 visible" nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
  check_warn "VA-API (vainfo)" vainfo
  check_warn "Rootless GPU podman smoke test" \
    podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable \
      nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
}

phase2() {
  section "Phase 2 — Snapper + grub-btrfs"
  check "Snapper installed" rpm -q snapper
  check "/.snapshots exists" test -d /.snapshots
  check_warn "snapper list (no sudo)" snapper list
  check "grub-btrfsd active" systemctl is-active grub-btrfsd
  check "snapper-timeline timer" systemctl is-active snapper-timeline.timer
  check "snapper-cleanup timer" systemctl is-active snapper-cleanup.timer
  check_warn "GRUB snapshot submenu" sudo grep -q "snapshots-btrfs" /boot/grub2/grub.cfg
  check_warn "python3-dnf-plugin-snapper" rpm -q python3-dnf-plugin-snapper
}

phase3() {
  section "Phase 3 — Homebrew / shell"
  check_warn "Homebrew installed" command -v brew
  if command -v brew >/dev/null 2>&1; then
    check_warn "brew zsh" brew --prefix zsh 2>/dev/null
    check_warn "neovim via brew" brew list neovim 2>/dev/null
    check_warn "ublue tap" bash -c 'brew tap 2>/dev/null | grep -q ublue-os/tap'
  fi
  check_warn "Brew zsh is login shell" bash -c '[[ "$(getent passwd "$USER" | cut -d: -f7)" == *linuxbrew*zsh* ]]'
  check_warn "oh-my-zsh" test -d "${SETUP_HOME}/.oh-my-zsh"
}

phase4() {
  section "Phase 4 — Flatpak + host GUI exceptions"
  check_warn "Flathub remote" bash -c 'flatpak remote-list | grep -q flathub'
  check_warn "qemu-kvm" rpm -q qemu-kvm
  check_warn "virt-manager" rpm -q virt-manager
  check_warn "libvirt group (re-login if missing)" bash -c 'id -nG "$USER" | grep -qw libvirt'
  check_warn "libvirtd active" systemctl is-active libvirtd
  check_warn "gnupg2 + kgpg" rpm -q gnupg2 kgpg
  check_warn "pinentry-qt in gpg-agent.conf" grep -q pinentry-qt "${SETUP_HOME}/.gnupg/gpg-agent.conf" 2>/dev/null
  check_warn "okular for PDF signing" rpm -q okular
}

phase5() {
  section "Phase 5 — Distrobox"
  check "distrobox.conf" test -f "${SETUP_HOME}/.config/distrobox/distrobox.conf"
  check_warn "/var/mount in distrobox.conf" grep -q '/var/mount' "${SETUP_HOME}/.config/distrobox/distrobox.conf"
  if bash "$(dirname "${BASH_SOURCE[0]}")/distrobox-available.sh"; then
    check_warn "dev container exists" bash -c 'distrobox list 2>/dev/null | grep -qw dev'
    check_warn "deepstream container exists" bash -c 'distrobox list 2>/dev/null | grep -qw deepstream'
  fi
}

phase6() {
  section "Phase 6 — host lockdown"
  check_warn "dnf-host wrapper" test -x /usr/local/bin/dnf-host
  check_warn "dnf guard wrapper" test -x /usr/local/bin/dnf
  check "dnf5-automatic timer" systemctl is-active dnf5-automatic.timer
  check_warn "NVIDIA versionlock" bash -c 'dnf versionlock list 2>/dev/null | grep -qi nvidia'
}

phase7() {
  section "Phase 7 — dotfiles & reproducibility"
  check_warn "Brewfile exists" test -f "${SETUP_HOME}/Brewfile"
  check_warn "chezmoi installed" command -v chezmoi
  check_warn "host-setup.sh executable" test -x "$(dirname "${BASH_SOURCE[0]}")/host-setup.sh"
}

phase_all() {
  phase0
  phase1
  phase1_gpu
  phase2
  phase3
  phase4
  phase5
  phase6
  phase7
}

main() {
  local target="${1:-all}"
  echo "Workstation setup verification: ${target}"
  case "$target" in
    phase0|0) phase0 ;;
    phase1|1) phase1 ;;
    phase1-gpu|1-gpu) phase1_gpu ;;
    phase2|2) phase2 ;;
    phase3|3) phase3 ;;
    phase4|4) phase4 ;;
    phase5|5) phase5 ;;
    phase6|6) phase6 ;;
    phase7|7) phase7 ;;
    all) phase_all ;;
    *)
      echo "Unknown phase: $target"
      echo "Use: phase0 phase1 phase1-gpu phase2 phase3 phase4 phase5 phase6 phase7 all"
      exit 2
      ;;
  esac
  echo ""
  echo "Summary: ${FAIL} failed, ${WARN} warnings"
  if [[ "$FAIL" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
