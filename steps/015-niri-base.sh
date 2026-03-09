#!/usr/bin/env bash
set -euo pipefail

# Install a practical Niri base stack on Arch Linux.

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

PACKAGES=(
  niri
  xwayland-satellite
  xorg-xwayland

  waybar
  swww
  mako
  fuzzel

  wl-clipboard
  wl-clip-persist

  swayidle
  swaylock
  grim
  slurp

  xdg-desktop-portal
  xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk

  polkit-gnome

  brightnessctl
  playerctl
  pavucontrol
  network-manager-applet

  qt5-wayland
  qt6-wayland

  libnotify
)

echo "Installing Niri base packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Creating useful user directories..."
mkdir -p "${HOME}/Pictures/Screenshots"
mkdir -p "${HOME}/.config/niri"
mkdir -p "${HOME}/.config/waybar"
mkdir -p "${HOME}/.config/mako"
mkdir -p "${HOME}/.config/fuzzel"
mkdir -p "${HOME}/.config/swaylock"
mkdir -p "${HOME}/.config/swww"

echo
echo "Installed:"
echo "  - Niri compositor"
echo "  - Xwayland support"
echo "  - Waybar, Fuzzel, Mako, Swww"
echo "  - Clipboard, lock/idle, screenshots"
echo "  - XDG portals, Polkit agent"
echo "  - Common desktop helpers"

echo
echo "Done."
echo "Next sensible step would be a config step for:"
echo "  - ~/.config/niri/config.kdl"
echo "  - ~/.config/waybar/"
echo "  - wallpaper startup"
