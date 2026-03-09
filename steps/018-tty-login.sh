#!/usr/bin/env bash
set -euo pipefail

# Replace graphical login managers with the normal tty login on tty1
# and install a custom /etc/issue header.

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

sudo -v

echo "Disabling graphical display managers for future boots..."
sudo systemctl disable gdm.service 2>/dev/null || true
sudo systemctl disable sddm.service 2>/dev/null || true

REMOVE_PKGS=()

if pacman -Q gdm >/dev/null 2>&1; then
  REMOVE_PKGS+=("gdm")
fi

if pacman -Q sddm >/dev/null 2>&1; then
  REMOVE_PKGS+=("sddm")
fi

if (( ${#REMOVE_PKGS[@]} > 0 )); then
  echo "Removing packages: ${REMOVE_PKGS[*]}"
  sudo pacman -Rns --noconfirm "${REMOVE_PKGS[@]}"
else
  echo "Neither gdm nor sddm is installed."
fi

echo "Removing stale display-manager alias if present..."
sudo rm -f /etc/systemd/system/display-manager.service

echo "Ensuring normal tty login on tty1 is enabled..."
sudo systemctl unmask getty@tty1.service 2>/dev/null || true
sudo systemctl enable getty@tty1.service

echo "Writing custom /etc/issue..."
sudo tee /etc/issue > /dev/null <<'ISSUEEOF'
  _                _       
 | |    ___   __ _(_)_ __  
 | |   / _ \ / _` | | '_ \ 
 | |__| (_) | (_| | | | | |
 |_____\___/ \__, |_|_| |_|
             |___/         

 Today is \d \t @ \n
 ----------------------------------------
 \r (\l)

ISSUEEOF

echo
echo "Done."
echo "Normal tty login on tty1 is configured."
echo "Reboot to use it:"
echo "  systemctl reboot"
