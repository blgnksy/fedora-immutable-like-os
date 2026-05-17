#!/usr/bin/env bash
set -euo pipefail

sudo tee /usr/local/bin/dnf > /dev/null << 'EOF'
#!/bin/bash
if [ ! -t 0 ] || [ ! -t 1 ]; then
  exec /usr/bin/dnf "$@"
fi
cat << 'WARNING'

  Hold on. You're about to run dnf on the host.
  Use: brew / flatpak / distrobox / podman first.
  If you really mean host changes: sudo dnf-host <command>

WARNING
exit 1
EOF
sudo chmod +x /usr/local/bin/dnf

sudo tee /usr/local/bin/dnf-host > /dev/null << 'EOF'
#!/bin/bash
echo "Running dnf on the host: $*"
exec /usr/bin/dnf "$@"
EOF
sudo chmod +x /usr/local/bin/dnf-host
echo "dnf guard installed: /usr/local/bin/dnf and dnf-host"
