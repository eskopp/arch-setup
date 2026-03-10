#!/usr/bin/env bash
set -Eeuo pipefail

echo "[INFO] 0002-packages.sh"

# Install NetworkManager for GNOME networking
sudo pacman -S --needed --noconfirm networkmanager

# Enable NetworkManager at boot
sudo systemctl enable NetworkManager.service

# Create dconf profile and database directories for GNOME defaults
sudo install -d -m 0755 /etc/dconf/profile
sudo install -d -m 0755 /etc/dconf/db/local.d

# Ensure the default dconf profile includes the local system database
sudo tee /etc/dconf/profile/user >/dev/null <<'EOF2'
user-db:user
system-db:local
EOF2

# Set GNOME defaults:
# - battery percentage visible
# - 24h clock with seconds
# - weekday + date visible
# - dark mode preferred
sudo tee /etc/dconf/db/local.d/00-gnome >/dev/null <<'EOF2'
[org/gnome/desktop/interface]
show-battery-percentage=true
clock-format='24h'
clock-show-seconds=true
clock-show-weekday=true
clock-show-date=true
color-scheme='prefer-dark'
EOF2

# Rebuild dconf database so GNOME picks up the defaults
sudo dconf update

echo "[OK] NetworkManager installed and GNOME defaults written."
