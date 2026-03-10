#!/usr/bin/env bash
set -Eeuo pipefail

echo "[INFO] 0002-packages.sh"

# Install required packages for GNOME base behavior
sudo pacman -S --needed --noconfirm networkmanager firefox xdg-utils

# Enable NetworkManager at boot
sudo systemctl enable NetworkManager.service

# Create dconf profile and database directories for GNOME defaults
sudo install -d -m 0755 /etc/dconf/profile
sudo install -d -m 0755 /etc/dconf/db/local.d

# Ensure the default dconf profile includes the local system database
printf '%s\n' \
  'user-db:user' \
  'system-db:local' \
  | sudo tee /etc/dconf/profile/user >/dev/null

# Set GNOME defaults:
# - battery percentage visible
# - 24h clock with seconds
# - weekday + date visible
# - dark mode preferred
# - no idle blanking
# - no automatic lock
# - no screen dimming
# - no suspend on AC or battery
printf '%s\n' \
  '[org/gnome/desktop/interface]' \
  'show-battery-percentage=true' \
  "clock-format='24h'" \
  'clock-show-seconds=true' \
  'clock-show-weekday=true' \
  'clock-show-date=true' \
  "color-scheme='prefer-dark'" \
  '' \
  '[org/gnome/desktop/session]' \
  'idle-delay=uint32 0' \
  '' \
  '[org/gnome/desktop/screensaver]' \
  'lock-enabled=false' \
  'lock-delay=uint32 0' \
  '' \
  '[org/gnome/settings-daemon/plugins/power]' \
  'idle-dim=false' \
  "sleep-inactive-ac-type='nothing'" \
  'sleep-inactive-ac-timeout=0' \
  "sleep-inactive-battery-type='nothing'" \
  'sleep-inactive-battery-timeout=0' \
  | sudo tee /etc/dconf/db/local.d/00-gnome >/dev/null

# Rebuild dconf database so GNOME picks up the defaults
sudo dconf update

# Configure lid close behavior: always power off
sudo install -d -m 0755 /etc/systemd/logind.conf.d
printf '%s\n' \
  '[Login]' \
  'HandleLidSwitch=poweroff' \
  'HandleLidSwitchExternalPower=poweroff' \
  'HandleLidSwitchDocked=poweroff' \
  | sudo tee /etc/systemd/logind.conf.d/80-lid-poweroff.conf >/dev/null

# Set Firefox as default browser for the current user
mkdir -p "${HOME}/.config"
printf '%s\n' \
  '[Default Applications]' \
  'x-scheme-handler/http=firefox.desktop' \
  'x-scheme-handler/https=firefox.desktop' \
  'text/html=firefox.desktop' \
  'application/xhtml+xml=firefox.desktop' \
  > "${HOME}/.config/mimeapps.list"

if command -v xdg-settings >/dev/null 2>&1; then
  xdg-settings set default-web-browser firefox.desktop || true
fi

echo "[OK] NetworkManager installed and enabled."
echo "[OK] GNOME defaults written."
echo "[OK] Firefox set as default browser."
echo "[OK] Lid close configured to power off after reboot."
echo "[INFO] Log out and back in for GNOME defaults. Reboot for lid-close behavior."
