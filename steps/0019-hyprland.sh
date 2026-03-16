#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

# Install Hyprland and a broad font stack on Arch Linux.

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

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "Could not determine home directory for user '${TARGET_USER}'."
  exit 1
fi

PACKAGES=(
  # Hyprland core
  hyprland
  hypridle
  hyprlock
  hyprpaper
  hyprland-qt-support
  hyprland-guiutils
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  uwsm

  # Common Wayland / Hyprland helpers
  waybar
  swww
  mako
  fuzzel
  wl-clipboard
  wl-clip-persist
  grim
  slurp
  swayidle
  swaylock
  polkit-gnome
  xorg-xwayland
  xwayland-satellite
  brightnessctl
  playerctl
  pavucontrol
  network-manager-applet
  qt5-wayland
  qt6-wayland

  # Fonts
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd
  otf-font-awesome
  awesome-terminal-fonts
  adobe-source-han-sans-jp-fonts
  adobe-source-han-serif-jp-fonts
)

echo "Installing Hyprland stack and fonts..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Refreshing font cache..."
fc-cache -f

echo "Creating basic user config directories..."
mkdir -p "${TARGET_HOME}/.config/hypr"
mkdir -p "${TARGET_HOME}/.config/waybar"
mkdir -p "${TARGET_HOME}/.config/mako"
mkdir -p "${TARGET_HOME}/.config/fuzzel"
mkdir -p "${TARGET_HOME}/.config/hyprlock"
mkdir -p "${TARGET_HOME}/.config/hypridle"
mkdir -p "${TARGET_HOME}/.config/uwsm"
mkdir -p "${TARGET_HOME}/Pictures/Screenshots"

echo
echo "Verification:"
Hyprland --version | sed -n '1p' || true
hyprlock --version | sed -n '1p' || true
hypridle --version | sed -n '1p' || true
hyprpaper --version | sed -n '1p' || true
fc-list | grep -i "JetBrainsMono Nerd Font" | head -n 1 || true
fc-list | grep -i "Noto Sans CJK" | head -n 1 || true
fc-list | grep -i "Source Han Sans" | head -n 1 || true
fc-list | grep -i "Font Awesome" | head -n 1 || true

echo
echo "Done."
echo "Hyprland and the main font stack are installed."
echo "Next sensible step: add your Hyprland dotfiles or config."
