#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

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

if ! command -v sudo > /dev/null 2>&1; then
  echo "sudo is required but not installed."
  exit 1
fi

require_sudo_session

echo "Installing Mullvad and keyd..."
sudo pacman -S --needed --noconfirm mullvad-vpn keyd

if ! systemctl list-unit-files | grep -q '^mullvad-daemon.service'; then
  echo "mullvad-daemon.service was not found after installation."
  exit 1
fi

echo "Enabling Mullvad daemon..."
sudo systemctl enable mullvad-daemon.service

if ! command -v keyd > /dev/null 2>&1; then
  echo "keyd command not found after installation."
  exit 1
fi

echo "Writing keyd config for UGREEN side buttons..."
sudo mkdir -p /etc/keyd

sudo tee /etc/keyd/ugreen-sidebuttons.conf > /dev/null << 'KEYDEOF'
[ids]
k:2b89:0043:595906dd

[meta]
[ = A-left
] = A-right
KEYDEOF

echo "Checking keyd config..."
sudo keyd check

if ! systemctl is-enabled --quiet keyd.service; then
  echo "Enabling keyd daemon..."
  sudo systemctl enable keyd.service
fi

if ! systemctl is-active --quiet keyd.service; then
  echo "Starting keyd daemon..."
  sudo systemctl start keyd.service
fi

echo "Waiting for keyd socket..."
for _ in {1..20}; do
  if sudo test -S /var/run/keyd.socket; then
    break
  fi
  sleep 0.2
done

if ! sudo test -S /var/run/keyd.socket; then
  echo "keyd.socket did not become available after starting keyd."
  sudo systemctl status --no-pager keyd.service || true
  exit 1
fi

echo "Reloading keyd..."
sudo keyd reload

echo
echo "Done."
echo "Mullvad daemon is enabled."
echo "UGREEN side buttons are configured through keyd."
