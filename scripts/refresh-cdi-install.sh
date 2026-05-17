#!/usr/bin/env bash
set -euo pipefail
mkdir -p "${HOME}/.local/bin"
tee "${HOME}/.local/bin/refresh-cdi" > /dev/null << 'EOF'
#!/bin/bash
set -euo pipefail
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list
EOF
chmod +x "${HOME}/.local/bin/refresh-cdi"
echo "Installed ~/.local/bin/refresh-cdi"
