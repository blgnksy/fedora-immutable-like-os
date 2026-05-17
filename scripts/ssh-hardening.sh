#!/usr/bin/env bash
# WARNING: Disables password auth. Verify SSH key login in a second session first.
set -euo pipefail
source "$(dirname "$0")/common.sh"

rpm -q openssh-server >/dev/null 2>&1 || dnf_cmd install -y openssh-server
systemctl enable --now sshd
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

sudo tee /etc/ssh/sshd_config.d/00-hardening.conf > /dev/null << 'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

sudo sshd -t && sudo systemctl restart sshd
echo "SSH hardened. Verify key login before closing this session."
