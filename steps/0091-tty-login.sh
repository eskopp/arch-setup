#!/usr/bin/env bash
set -euo pipefail

# Replace graphical login managers with the normal tty login on tty1
# and install a custom /etc/issue header.
#
# This script is intentionally careful:
# - It disables gdm/sddm for future boots
# - It does not stop them live
# - Package removal failures do not abort the whole step

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

echo "Trying to remove gdm if installed..."
if pacman -Q gdm >/dev/null 2>&1; then
  sudo pacman -R --noconfirm gdm || true
else
  echo "gdm is not installed."
fi

echo "Trying to remove sddm if installed..."
if pacman -Q sddm >/dev/null 2>&1; then
  sudo pacman -R --noconfirm sddm || true
else
  echo "sddm is not installed."
fi

echo "Removing stale display-manager alias if present..."
sudo rm -f /etc/systemd/system/display-manager.service || true

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

 Today is \d at \t on \n
 ----------------------------------------
 os       : \S{PRETTY_NAME}
 kernel   : \s \r
 machine  : \m
 tty      : \l
 domain   : \o
 network  : \4 / \6
 ----------------------------------------

ISSUEEOF

echo
echo "Done."
echo "The normal tty login on tty1 is configured."
echo "This change will apply after a reboot."
echo "Reboot when you are ready:"
echo "  systemctl reboot"
