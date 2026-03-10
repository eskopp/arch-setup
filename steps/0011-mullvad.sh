#!/usr/bin/env bash
set -euo pipefail

# Enable Mullvad daemon and configure keyd side buttons on Arch Linux.

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "Cannot read /etc/os-release"
  exit 1
fi

if [[ "${ID:-}" != "arch" ]]; then
  echo "This script only supports Arch Linux."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required but not installed."
  exit 1
fi

sudo -v

if ! systemctl list-unit-files | grep -q '^mullvad-daemon.service'; then
  echo "mullvad-daemon.service was not found."
  echo "Please install Mullvad first."
  exit 1
fi

echo "Enabling Mullvad daemon..."
sudo systemctl enable mullvad-daemon.service

if ! command -v keyd >/dev/null 2>&1; then
  echo "keyd is not installed."
  echo "Please install keyd first."
  exit 1
fi

echo "Writing keyd config for UGREEN side buttons..."
sudo mkdir -p /etc/keyd

sudo tee /etc/keyd/ugreen-sidebuttons.conf > /dev/null <<'KEYDEOF'
[ids]
k:2b89:0043:595906dd

[meta]
[ = A-left
] = A-right
KEYDEOF

echo "Checking keyd config..."
sudo keyd check

echo "Reloading keyd..."
sudo keyd reload

echo
echo "Done."
echo "Mullvad daemon is enabled."
echo "UGREEN side buttons are configured through keyd."
