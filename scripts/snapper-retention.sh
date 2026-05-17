#!/usr/bin/env bash
set -euo pipefail
sudo snapper -c root set-config "NUMBER_LIMIT=50"
sudo snapper -c root set-config "TIMELINE_LIMIT_HOURLY=5"
sudo snapper -c root set-config "TIMELINE_LIMIT_DAILY=7"
sudo snapper -c root set-config "TIMELINE_LIMIT_WEEKLY=4"
sudo snapper -c root set-config "TIMELINE_LIMIT_MONTHLY=3"
echo "Snapper retention limits set."
