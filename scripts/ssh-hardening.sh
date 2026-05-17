#!/usr/bin/env bash
# WARNING: Disables password auth. Verify SSH key login in a second session first.
set -euo pipefail
source "$(dirname "$0")/common.sh"

rpm -q openssh-server >/dev/null 2>&1 || dnf_cmd install -y openssh-server
systemctl enable --now sshd
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

sudo install -d -m 0755 /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/00-hardening.conf > /dev/null << 'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sudo chmod 0644 /etc/ssh/sshd_config.d/00-hardening.conf

if ! sudo test -f /etc/ssh/sshd_config.d/00-hardening.conf; then
  echo "ERROR: failed to write /etc/ssh/sshd_config.d/00-hardening.conf" >&2
  exit 1
fi

sudo sshd -t && sudo systemctl restart sshd
echo "SSH hardened. Verify key login before closing this session."
