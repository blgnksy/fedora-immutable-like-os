#!/usr/bin/env bash
# host-setup.sh — one-shot Fedora KDE host setup, Phases 1–6
#
# Run on a fresh Fedora KDE install (from the setup repo):
#   bash ~/setup/scripts/host-setup.sh
#   bash ~/setup/scripts/host-setup.sh --from 2   # resume at phase 2
#
# Available resume points: 1  1b  1c  2  3  3b  4  5  6

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")"

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo ""; echo ">>> $*"; }
pause() {
    local msg="$1" resume_phase="$2"
    echo ""
    echo "  MANUAL: $msg"
    echo "  To resume later: bash $0 --from $resume_phase"
    read -rp "  Ready to continue now? [y/N] " _ok
    [[ "${_ok,,}" == "y" ]] || exit 0
}

PHASES=(1 1b 1c 2 3 3b 4 5 6)
FROM_PHASE="1"
[[ "${1:-}" == "--from" && -n "${2:-}" ]] && FROM_PHASE="$2"

should_run() {
    local target="$1" i from_idx=0 target_idx=0
    for i in "${!PHASES[@]}"; do
        [[ "${PHASES[$i]}" == "$FROM_PHASE" ]] && from_idx=$i
        [[ "${PHASES[$i]}" == "$target" ]]    && target_idx=$i
    done
    (( target_idx >= from_idx ))
}

command -v make >/dev/null || die "make not found"
[[ -f "$SETUP_DIR/Makefile" ]] || die "Makefile not found at $SETUP_DIR"

echo "Fedora KDE immutable-like host setup — Phases 1–6"
echo "Setup dir : $SETUP_DIR"
echo "Starting  : phase $FROM_PHASE"

# ── Phase 1a — DNF tweaks (before upgrade) ──────────────────────────────────
if should_run 1; then
    info "Phase 1a: DNF speed tweaks"
    make -C "$SETUP_DIR" phase1-dnf-tweaks
    pause "Run the system upgrade and reboot:
    sudo make -C $SETUP_DIR phase1-upgrade
    sudo reboot" "1b"
fi

# ── Phase 1b — post-reboot host packages ────────────────────────────────────
if should_run 1b; then
    info "Phase 1b: SSH + debug tools + RPM Fusion + NVIDIA driver + Podman + codecs"
    make -C "$SETUP_DIR" \
        phase1-ssh \
        phase1-debug \
        phase1-rpmfusion \
        phase1-nvidia \
        phase1-nvidia-suspend \
        phase1-nvidia-toolkit \
        phase1-podman \
        phase1-cdi \
        phase1-refresh-cdi-script \
        phase1-codecs \
        phase1-vaapi
    pause "Reboot to activate the NVIDIA 580xx driver." "1c"
fi

# ── Phase 1c — GPU verification ─────────────────────────────────────────────
if should_run 1c; then
    info "Phase 1c: GPU verification (NVIDIA driver must be active)"
    make -C "$SETUP_DIR" phase1-verify-gpu || true
fi

# ── Phase 2 ──────────────────────────────────────────────────────────────────
if should_run 2; then
    info "Phase 2: Btrfs snapshots + grub-btrfs"
    make -C "$SETUP_DIR" phase2-all
fi

# ── Phase 3a — Homebrew build deps (before interactive install) ──────────────
if should_run 3; then
    info "Phase 3a: Homebrew build dependencies"
    make -C "$SETUP_DIR" phase3-brew-deps
    pause "Install Homebrew (interactive):
    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"
  Set the default shell:
    brew install zsh
    echo \"\$(brew --prefix)/bin/zsh\" | sudo tee -a /etc/shells
    chsh -s \"\$(brew --prefix)/bin/zsh\"
  Install oh-my-zsh and configure ~/.zshrc (see Phase 3 in the guide).
  Log out of KDE and back in before continuing." "3b"
fi

# ── Phase 3b — Brew CLI tools ────────────────────────────────────────────────
if should_run 3b; then
    info "Phase 3b: Brew CLI tools + ublue tap + VS Code"
    make -C "$SETUP_DIR" phase3-brew-cli phase3-brew-tap
fi

# ── Phase 4 ──────────────────────────────────────────────────────────────────
if should_run 4; then
    info "Phase 4: Flatpak apps + virtualization + crypto + PDF signing"
    make -C "$SETUP_DIR" \
        phase4-flathub \
        phase4-flatpak-apps \
        phase4-virt \
        phase4-crypto \
        phase4-okular
fi

# ── Phase 5 ──────────────────────────────────────────────────────────────────
if should_run 5; then
    info "Phase 5: Distrobox dev containers"
    make -C "$SETUP_DIR" phase5-distrobox-config phase5-distrobox-dev
fi

# ── Phase 6 ──────────────────────────────────────────────────────────────────
if should_run 6; then
    info "Phase 6: Lock down host"
    make -C "$SETUP_DIR" \
        phase6-dnf-automatic \
        phase6-nvidia-versionlock \
        phase6-dnf-guard
fi

echo ""
echo "Phases 1–6 complete."
echo ""
echo "Next steps (Phase 7 — dotfiles):"
echo "  make -C $SETUP_DIR phase7-brewfile-dump"
echo "  brew install chezmoi && chezmoi init --apply <your-github-username>"
