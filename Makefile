# Fedora KDE immutable-like workstation — setup & maintenance
# Docs: ~/fedora-kde-immutable-like-setup.md
# Usage:  cd ~/setup && make help
#         make -C ~/setup phase1-all
#         make -C ~/setup update

SHELL := /bin/bash
MAKEFLAGS += --no-print-directory
SETUP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(SETUP_DIR)/scripts
export NVIDIA_CONTAINER_TOOLKIT_VERSION ?= 1.19.0-1

DNF := $(shell command -v dnf-host >/dev/null 2>&1 && echo 'sudo dnf-host' || echo 'sudo dnf')
BREW := $(shell test -x /home/linuxbrew/.linuxbrew/bin/brew && echo /home/linuxbrew/.linuxbrew/bin/brew || echo brew)

.PHONY: help help-setup help-maint \
	phase0-verify phase1-verify phase1-verify-gpu \
	phase2-verify phase3-verify phase4-verify phase5-verify phase6-verify verify-all \
	phase1-all phase1-dnf-tweaks phase1-upgrade phase1-ssh phase1-fail2ban \
	phase1-debug phase1-perf phase1-rpmfusion phase1-nvidia phase1-nvidia-suspend \
	phase1-nvidia-toolkit phase1-podman phase1-cdi phase1-refresh-cdi-script \
	phase1-codecs phase1-vaapi phase1-flatpak-ffmpeg \
	phase2-all phase2-snapper phase2-snapper-timers phase2-snapper-retention \
	phase2-grub-btrfs phase2-grub-test \
	phase3-brew-deps phase3-brew-cli phase3-brew-tap phase3-brew-casks \
	phase4-flathub phase4-flatpak-apps phase4-flatpak-xdg phase4-virt \
	phase4-crypto phase4-okular phase4-smartcard \
	phase5-distrobox-config phase5-distrobox-dev phase5-distrobox-deepstream \
	phase6-dnf-automatic phase6-nvidia-versionlock phase6-dnf-guard \
	phase7-brewfile-dump phase7-all phase7-host-setup phase7-verify \
	update update-host health status clean mounts \
	snapper-list snapper-cleanup snapper-undo snapper-timers \
	refresh-gpu gpu-test flatpak-update brew-update distrobox-update podman-prune

.DEFAULT_GOAL := help

help: ## Show maintenance targets (day-2)
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | grep -v help-setup | \
		sed 's|.*/Makefile://; s/:.*## /  /' | sort
	@echo ""
	@echo "Setup targets: make -C ~/setup help-setup"
	@echo "DNF wrapper:   $(DNF)"

help-setup: ## Show one-time setup targets (phases 0–7)
	@echo "Run from: make -C ~/setup <target>"
	@echo ""
	@echo "=== Phase 0 ==="
	@echo "  phase0-verify          Btrfs layout check"
	@echo ""
	@echo "=== Verification (after each phase) ==="
	@echo "  phaseN-verify          Run checks for phase N (phase1-verify-gpu after reboot)"
	@echo "  verify-all             All phases (includes GPU checks)"
	@echo ""
	@echo "=== Phase 1 (host) ==="
	@echo "  phase1-all             dnf tweaks + ssh + debug + rpmfusion + nvidia + podman + codecs"
	@echo "  phase1-podman          podman (dnf); distrobox via brew if present, else dnf"
	@echo "  phase1-dnf-tweaks      DNF speed + sslcacert"
	@echo "  phase1-upgrade         dnf upgrade (then reboot manually)"
	@echo "  phase1-ssh             openssh + hardening (needs SSH key first!)"
	@echo "  phase1-fail2ban        optional"
	@echo "  phase1-debug           gdb perf strace valgrind"
	@echo "  phase1-rpmfusion       enable RPM Fusion"
	@echo "  phase1-nvidia          580xx driver + blacklist nouveau"
	@echo "  phase1-nvidia-toolkit  nvidia-container-toolkit + CDI"
	@echo "  phase1-codecs          ffmpeg gstreamer"
	@echo ""
	@echo "=== Phase 2 (snapper) ==="
	@echo "  phase2-all             snapper + retention + timers + grub-btrfs"
	@echo "  phase2-snapper         install + ALLOW_USERS"
	@echo "  phase2-grub-btrfs      build from Antynea git"
	@echo ""
	@echo "=== Phase 3 (brew) — partial ==="
	@echo "  phase3-brew-deps       git gcc make (for Homebrew installer)"
	@echo "  phase3-brew-cli        daily CLI formulas + distrobox (needs brew installed)"
	@echo "  phase3-brew-tap        ublue-os/tap + VS Code cask"
	@echo "  (manual: Homebrew install, oh-my-zsh, chsh — interactive)"
	@echo ""
	@echo "=== Phase 4 ==="
	@echo "  phase4-flathub         enable Flathub"
	@echo "  phase4-flatpak-apps    install recommended flatpaks"
	@echo "  phase4-virt            qemu/libvirt"
	@echo "  phase4-crypto          gnupg kgpg kleopatra"
	@echo ""
	@echo "=== Phase 5 ==="
	@echo "  phase5-distrobox-config   ~/.config/distrobox/distrobox.conf"
	@echo "  phase5-distrobox-dev      create dev container (no packages inside)"
	@echo ""
	@echo "=== Phase 6 ==="
	@echo "  phase6-dnf-automatic   security updates timer"
	@echo "  phase6-dnf-guard       /usr/local/bin/dnf wrapper"
	@echo "  phase6-nvidia-versionlock"
	@echo ""
	@echo "=== Phase 7 (dotfiles) ==="
	@echo "  phase7-all             brewfile-dump + validate host-setup.sh"
	@echo "  phase7-brewfile-dump   save ~/Brewfile"
	@echo "  phase7-host-setup      make scripts/host-setup.sh executable"
	@echo "  (manual: chezmoi init — interactive)"
	@echo ""
	@echo "=== Orchestration ==="
	@echo "  scripts/host-setup.sh  run all phases 1–6 in one shot (supports --from <phase>)"
	@echo ""
	@echo "Skipped (manual only): ISO install, reboot, ssh-copy-id, chsh,"
	@echo "  Homebrew install, oh-my-zsh, GPG keygen, VS Code sync, PDF sign in Okular"

# --- Phase 0 ---

phase0-verify: ## Verify Btrfs after Anaconda install
	bash $(SCRIPTS)/verify.sh phase0

# --- Verification ---

phase1-verify: ## Verify phase 1 host packages (no GPU smoke test; do not use sudo)
	bash $(SCRIPTS)/verify.sh phase1

phase1-verify-gpu: ## Verify NVIDIA + VA-API + podman GPU (after reboot)
	bash $(SCRIPTS)/verify.sh phase1-gpu

phase2-verify: ## Verify snapper + grub-btrfs
	bash $(SCRIPTS)/verify.sh phase2

phase3-verify: ## Verify Homebrew / shell (mostly warnings)
	bash $(SCRIPTS)/verify.sh phase3

phase4-verify: ## Verify Flatpak + virt + crypto
	bash $(SCRIPTS)/verify.sh phase4

phase5-verify: ## Verify Distrobox config + containers
	bash $(SCRIPTS)/verify.sh phase5

phase6-verify: ## Verify dnf guard + automatic updates
	bash $(SCRIPTS)/verify.sh phase6

verify-all: ## Run all phase verifications
	bash $(SCRIPTS)/verify.sh all

# --- Phase 1 ---

phase1-all: phase1-dnf-tweaks phase1-ssh phase1-debug phase1-rpmfusion \
	phase1-nvidia phase1-nvidia-suspend phase1-nvidia-toolkit phase1-podman \
	phase1-cdi phase1-refresh-cdi-script phase1-codecs phase1-vaapi
	@echo "Phase 1 automated steps done. Manual: phase1-upgrade + reboot, optional fail2ban."
	@$(MAKE) phase1-verify
	@echo "After reboot: make -C ~/setup phase1-verify-gpu"

phase1-dnf-tweaks: ## DNF speed + sslcacert
	bash $(SCRIPTS)/dnf-speed-tweaks.sh

phase1-upgrade: ## Full system upgrade (reboot yourself after)
	$(DNF) upgrade --refresh -y

phase1-ssh: ## SSH server + hardening drop-in
	bash $(SCRIPTS)/ssh-hardening.sh

phase1-fail2ban: ## fail2ban sshd jail
	bash $(SCRIPTS)/fail2ban-sshd.sh

phase1-debug: ## Host debugging tools
	$(DNF) install -y gdb gdbserver strace ltrace perf valgrind binutils elfutils

phase1-perf: ## perf_event_paranoid sysctl
	echo "kernel.perf_event_paranoid = 1" | sudo tee /etc/sysctl.d/99-perf.conf
	sudo sysctl --system

phase1-rpmfusion: ## Enable RPM Fusion free + nonfree
	$(DNF) install -y \
		https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm

phase1-nvidia: ## NVIDIA 580xx + blacklist nouveau
	$(DNF) install -y \
		akmod-nvidia-580xx \
		xorg-x11-drv-nvidia-580xx \
		xorg-x11-drv-nvidia-580xx-cuda \
		xorg-x11-drv-nvidia-580xx-cuda-libs \
		xorg-x11-drv-nvidia-580xx-libs
	echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
	sudo dracut --force
	@echo "Reboot, then: nvidia-smi"

phase1-nvidia-suspend: ## NVIDIA suspend/resume services
	sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
	sudo tee /etc/modprobe.d/nvidia-power-management.conf > /dev/null << 'EOF'
	options nvidia NVreg_PreserveVideoMemoryAllocations=1
	options nvidia NVreg_TemporaryFilePath=/var/tmp
	EOF
	sudo dracut --force

phase1-nvidia-toolkit: ## nvidia-container-toolkit repo + packages
	curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
		sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
	$(DNF) install -y \
		nvidia-container-toolkit-$(NVIDIA_CONTAINER_TOOLKIT_VERSION) \
		nvidia-container-toolkit-base-$(NVIDIA_CONTAINER_TOOLKIT_VERSION) \
		libnvidia-container-tools-$(NVIDIA_CONTAINER_TOOLKIT_VERSION) \
		libnvidia-container1-$(NVIDIA_CONTAINER_TOOLKIT_VERSION)

phase1-podman: ## podman on host; distrobox via brew or dnf
	rpm -q podman >/dev/null 2>&1 || $(DNF) install -y podman podman-compose
	DNF='$(DNF)' BREW='$(BREW)' bash $(SCRIPTS)/distrobox-ensure.sh

phase1-cdi: ## Generate /etc/cdi/nvidia.yaml
	sudo mkdir -p /etc/cdi
	sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
	nvidia-ctk cdi list

phase1-refresh-cdi-script: ## Install ~/.local/bin/refresh-cdi
	bash $(SCRIPTS)/refresh-cdi-install.sh

phase1-codecs: ## ffmpeg swap + gstreamer plugins
	$(DNF) swap ffmpeg-free ffmpeg --allowerasing || true
	$(DNF) install -y \
		gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras \
		gstreamer1-plugins-good gstreamer1-plugins-base gstreamer1-plugins-ugly \
		gstreamer1-plugin-openh264 gstreamer1-libav gstreamer1-plugins-bad-freeworld

phase1-vaapi: ## NVIDIA VA-API
	$(DNF) install -y libva-nvidia-driver libva-utils

phase1-flatpak-ffmpeg: ## Flatpak ffmpeg runtime
	flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full//24.08 || true

# --- Phase 2 ---

phase2-all: phase2-snapper phase2-snapper-retention phase2-snapper-timers phase2-grub-btrfs phase2-grub-test
	@$(MAKE) phase2-verify

phase2-snapper: ## Snapper + ALLOW_USERS
	bash $(SCRIPTS)/snapper-init.sh

phase2-snapper-retention: ## Timeline/number limits
	bash $(SCRIPTS)/snapper-retention.sh

phase2-snapper-timers: ## snapper-timeline + snapper-cleanup timers
	sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
	systemctl list-timers 'snapper-*' --no-pager

phase2-grub-btrfs: ## Build + install grub-btrfsd from git
	bash $(SCRIPTS)/grub-btrfs-install.sh

phase2-grub-test: ## Test snapshot + refresh GRUB menu
	snapper create --description "grub-btrfs test" || true
	sudo grub-btrfs 2>/dev/null || true
	sudo grub2-mkconfig -o /boot/grub2/grub.cfg
	sudo grep -i snapshot /boot/grub2/grub.cfg | head -3

# --- Phase 3 (partial — Homebrew installer is interactive) ---

phase3-brew-deps: ## git gcc make for Homebrew
	$(DNF) install -y git gcc gcc-c++ make

phase3-brew-cli: ## Daily CLI via brew (requires brew in PATH)
	@command -v brew >/dev/null || { echo "Install Homebrew first"; exit 1; }
	brew install neovim tmux ripgrep fd fzf bat eza jq yq htop btop tree wget curl lazygit lazydocker starship direnv gh zsh distrobox

phase3-brew-tap: ## ublue tap + VS Code cask
	brew tap ublue-os/tap
	brew install --cask visual-studio-code-linux

phase3-brew-casks-optional: ## Optional ublue casks
	brew install --cask jetbrains-toolbox-linux 1password-gui-linux lm-studio-linux vscodium-linux || true

# --- Phase 4 ---

phase4-flathub: ## Enable Flathub remote
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

phase4-flatpak-apps: phase4-flathub ## Recommended flatpak set
	flatpak install -y flathub io.github.kolunmi.Bazaar io.github.flattool.Warehouse com.github.tchx84.Flatseal || true
	flatpak install -y flathub com.vivaldi.Vivaldi org.mozilla.firefox || true
	flatpak install -y flathub net.cozic.joplindesktop org.collabora.Office com.nextcloud.desktopclient.nextcloud || true
	flatpak install -y flathub org.videolan.VLC io.dbeaver.DBeaverCommunity org.localsend.localsend_app || true

phase4-flatpak-xdg: ## KDE menu fix for flatpaks (set USER=yourname if needed)
	@test -n "$(USER)" || { echo "Set USER in environment"; exit 1; }
	sudo tee /etc/environment.d/flatpak.conf > /dev/null << EOF
	XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/home/$(USER)/.local/share/flatpak/exports/share:/usr/local/share:/usr/share
	EOF
	@echo "Log out of KDE to apply."

phase4-virt: ## QEMU/KVM + libvirt
	$(DNF) install -y qemu-kvm qemu-img libvirt libvirt-daemon-config-network virt-manager edk2-ovmf swtpm
	sudo systemctl enable --now libvirtd
	sudo usermod -aG libvirt "$(USER)"
	@echo "Log out/in for libvirt group."

phase4-crypto: ## GPG + KDE crypto GUIs
	$(DNF) install -y gnupg2 kgpg kleopatra pinentry-qt kwalletmanager5 qgpgme
	mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
	grep -q pinentry-qt ~/.gnupg/gpg-agent.conf 2>/dev/null || \
		echo "pinentry-program /usr/bin/pinentry-qt" >> ~/.gnupg/gpg-agent.conf
	gpgconf --kill gpg-agent

phase4-okular: ## PDF signing packages
	$(DNF) install -y okular nss-tools poppler-utils
	mkdir -p ~/.pki/nssdb
	certutil -d sql:$(HOME)/.pki/nssdb -N --empty-password 2>/dev/null || true

phase4-smartcard: ## pcscd + opensc
	$(DNF) install -y pcsc-lite pcsc-tools opensc
	sudo systemctl enable --now pcscd

# --- Phase 5 ---

phase5-distrobox-config: ## /var/mount bind in distrobox.conf
	bash $(SCRIPTS)/distrobox-config.sh

phase5-distrobox-dev: ## Create dev container (install packages inside manually)
	distrobox create --name dev --image registry.fedoraproject.org/fedora-toolbox:44 -Y || true

phase5-distrobox-deepstream: ## Create ubuntu deepstream container
	distrobox create --name deepstream --image ubuntu:22.04 \
		--additional-packages "build-essential cmake python3 python3-pip" -Y || true

# --- Phase 6 ---

phase6-dnf-automatic: ## dnf5-automatic security timer
	bash $(SCRIPTS)/dnf-automatic.sh

phase6-nvidia-versionlock: ## Pin 580xx driver
	$(DNF) install -y python3-dnf-plugin-versionlock || true
	sudo dnf versionlock add akmod-nvidia-580xx 'xorg-x11-drv-nvidia-580xx*' || \
		$(DNF) versionlock add akmod-nvidia-580xx xorg-x11-drv-nvidia-580xx\*

phase6-dnf-guard: ## /usr/local/bin/dnf guard + dnf-host
	bash $(SCRIPTS)/dnf-guard.sh

# --- Phase 7 ---

phase7-all: phase7-brewfile-dump phase7-host-setup ## Brewfile dump + validate host-setup.sh

phase7-brewfile-dump: ## Dump ~/Brewfile
	@command -v brew >/dev/null
	brew bundle dump --file=$(HOME)/Brewfile --force

phase7-host-setup: ## Make scripts/host-setup.sh executable
	chmod +x $(SCRIPTS)/host-setup.sh
	@echo "host-setup.sh: $(SCRIPTS)/host-setup.sh"
	@echo "Fresh install  : bash $(SCRIPTS)/host-setup.sh"
	@echo "Resume at phase: bash $(SCRIPTS)/host-setup.sh --from <phase>"

phase7-verify: ## Verify Phase 7 artifacts (Brewfile, host-setup.sh)
	bash $(SCRIPTS)/verify.sh phase7

# --- Day-2 maintenance ---

update: flatpak-update brew-update distrobox-update ## User-space updates only

flatpak-update: ## flatpak update -y
	flatpak update -y

brew-update: ## brew update && upgrade
	@eval "$$($(BREW) shellenv 2>/dev/null || true)" && brew update && brew upgrade

distrobox-update: ## distrobox upgrade --all
	@command -v distrobox >/dev/null && distrobox upgrade --all --yes || true

update-host: ## Host dnf upgrade + refresh-gpu
	$(DNF) upgrade --refresh -y
	$(MAKE) -C $(SETUP_DIR) refresh-gpu

snapper-list: ## snapper list
	snapper list

snapper-cleanup: ## snapper-cleanup.service
	sudo systemctl start snapper-cleanup.service
	$(MAKE) -C $(SETUP_DIR) snapper-list

snapper-timers: ## Show snapper timer status
	systemctl list-timers 'snapper-*' --no-pager

snapper-undo: ## snapper undochange (PRE=1 POST=2)
	@test -n "$(PRE)" -a -n "$(POST)" || { echo "Usage: make snapper-undo PRE=1 POST=2"; exit 1; }
	snapper undochange $(PRE)..$(POST)

refresh-gpu: ## Regenerate CDI spec
	@command -v refresh-cdi >/dev/null || { echo "Run: make -C ~/setup phase1-refresh-cdi-script"; exit 1; }
	~/.local/bin/refresh-cdi

gpu-test: ## Rootless podman GPU smoke test
	podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable \
		nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

clean: snapper-cleanup podman-prune ## Cleanup brew/podman/snapper
	@eval "$$($(BREW) shellenv 2>/dev/null || true)" && brew cleanup -s || true

podman-prune: ## podman system prune -f
	@command -v podman >/dev/null && podman system prune -f || true

health: ## grub-btrfsd + snapper + grub.cfg
	@echo "grub-btrfsd: $$(systemctl is-active grub-btrfsd.service 2>/dev/null || echo n/a)"
	@snapper list 2>/dev/null | head -12
	@sudo grep -i snapshot /boot/grub2/grub.cfg 2>/dev/null | head -3 || true

status: mounts snapper-list snapper-timers ## Status overview

mounts: ## /var/mount + noexec check
	@findmnt -R /var/mount -o TARGET,FSTYPE,OPTIONS 2>/dev/null || true
	@if findmnt /var/mount/Projects -o OPTIONS 2>/dev/null | grep -q noexec; then \
		echo "WARNING: Projects has noexec"; exit 1; else echo "OK: Projects allows exec"; fi
