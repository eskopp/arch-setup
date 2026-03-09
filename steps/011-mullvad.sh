#!/usr/bin/env bash
set -euo pipefail

# Enable Mullvad daemon on Arch Linux.

if [[ -r /etc/os-release ]]; then
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

if ! systemctl list-unit-files | grep -q '^mullvad-daemon.service'; then
  echo "mullvad-daemon.service was not found."
  echo "Please install Mullvad first."
  exit 1
fi

sudo systemctl enable mullvad-daemon.service

echo "Done."
echo "Mullvad daemon is enabled."
echo "Start it now with:"
echo "  sudo systemctl start mullvad-daemon.service"
