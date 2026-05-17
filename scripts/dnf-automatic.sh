#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

dnf_cmd install -y dnf5-plugin-automatic
sudo tee /etc/dnf/automatic.conf > /dev/null << 'EOF'
[commands]
upgrade_type = security
random_sleep = 0
network_online_timeout = 60
download_updates = yes
apply_updates = yes
reboot = never

[emitters]
emit_via = stdio

[base]
debuglevel = 1
EOF
sudo systemctl enable --now dnf5-automatic.timer
systemctl list-timers '*dnf*' --no-pager | head -10
echo "dnf5-automatic configured."
