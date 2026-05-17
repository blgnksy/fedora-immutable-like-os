#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

dnf_cmd install -y fail2ban fail2ban-firewalld
sudo tee /etc/fail2ban/jail.d/sshd.local > /dev/null << 'EOF'
[sshd]
enabled = true
backend = systemd
port    = ssh
maxretry = 5
findtime = 10m
bantime = 1h
EOF
systemctl enable --now fail2ban
fail2ban-client status
fail2ban-client status sshd
