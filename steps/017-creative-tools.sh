#!/usr/bin/env bash
set -euo pipefail

# Install Yazi with useful extras plus Krita and GIMP on Arch Linux.

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
  yazi

  # Yazi extras
  7zip
  chafa
  fd
  ffmpeg
  fzf
  git
  imagemagick
  jq
  poppler
  resvg
  ripgrep
  wl-clipboard
  zoxide

  # Image tools
  krita
  krita-plugin-gmic
  gimp
  gimp-plugin-gmic
)

echo "Installing Yazi, Krita, GIMP, and Yazi helper packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo
echo "Verification:"
yazi --version || true
krita --version | sed -n '1p' || true
gimp --version || true

echo
echo "Done."
echo "Yazi was installed with helper packages for previews, search, archives, and Wayland clipboard support."
echo "Krita and GIMP were installed together with their G'MIC plugins."
