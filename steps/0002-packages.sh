#!/usr/bin/env bash
set -Eeuo pipefail

echo "[INFO] 0002-packages.sh"

# Install NetworkManager, Firefox and XDG utilities
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
printf '%s\n' \
  '[org/gnome/desktop/interface]' \
  'show-battery-percentage=true' \
  "clock-format='24h'" \
  'clock-show-seconds=true' \
  'clock-show-weekday=true' \
  'clock-show-date=true' \
  "color-scheme='prefer-dark'" \
  | sudo tee /etc/dconf/db/local.d/00-gnome >/dev/null

# Rebuild dconf database so GNOME picks up the defaults
sudo dconf update

# Set Firefox as the default browser for the current user
xdg-settings set default-web-browser firefox.desktop

# Also set common MIME handlers explicitly for robustness
mkdir -p "${HOME}/.config"
cat > "${HOME}/.config/mimeapps.list" <<'EOF2'
[Default Applications]
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
text/html=firefox.desktop
application/xhtml+xml=firefox.desktop
EOF2

echo "[OK] NetworkManager installed, GNOME defaults written, Firefox set as default browser."
