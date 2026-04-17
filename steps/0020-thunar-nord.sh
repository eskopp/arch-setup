#!/usr/bin/env bash
set -euo pipefail

sudo pacman -S --needed \
  thunar \
  tumbler \
  ffmpegthumbnailer \
  thunar-volman \
  thunar-archive-plugin \
  papirus-icon-theme \
  bibata-cursor-theme \
  git

mkdir -p "${HOME}/.themes"
if [ ! -d "${HOME}/.themes/Nordic/.git" ]; then
  rm -rf "${HOME}/.themes/Nordic"
  git clone --depth=1 https://github.com/EliverLara/Nordic.git "${HOME}/.themes/Nordic"
else
  git -C "${HOME}/.themes/Nordic" pull --ff-only
fi

mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"

cat > "${HOME}/.config/gtk-3.0/settings.ini" <<'GTK3'
[Settings]
gtk-theme-name=Nordic
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-application-prefer-dark-theme=1
GTK3

cat > "${HOME}/.config/gtk-4.0/settings.ini" <<'GTK4'
[Settings]
gtk-theme-name=Nordic
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-application-prefer-dark-theme=1
GTK4

printf '\nDone.\n'
printf 'You can start Thunar with: thunar\n'
