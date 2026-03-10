#!/usr/bin/env bash
set -euo pipefail

# Install Alacritty, remove GNOME Console,
# and add a GNOME launcher alias named "Console"
# so searching for "console" opens Alacritty.

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

sudo -v

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "Could not determine home directory for user '${TARGET_USER}'."
  exit 1
fi

echo "Installing Alacritty..."
sudo pacman -S --needed --noconfirm alacritty

echo "Removing GNOME Console if installed..."
if pacman -Q gnome-console > /dev/null 2>&1; then
  sudo pacman -Rns --noconfirm gnome-console
else
  echo "gnome-console is not installed."
fi

echo "Creating GNOME launcher alias for Alacritty..."
install -d -m 755 "${TARGET_HOME}/.local/share/applications"

cat > "${TARGET_HOME}/.local/share/applications/alacritty-console.desktop" << 'DESKTOPEOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Console
GenericName=Terminal Emulator
Comment=Open Alacritty terminal
Exec=alacritty
TryExec=alacritty
Icon=Alacritty
Terminal=false
Categories=System;TerminalEmulator;
Keywords=console;terminal;shell;command line;cli;prompt;
StartupNotify=true
DESKTOPEOF

chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.local/share/applications/alacritty-console.desktop"

echo "Done."
echo "Alacritty is installed."
echo "GNOME Console is removed if it was present."
echo "Searching for 'Console' in GNOME should now open Alacritty."
echo "If GNOME search does not update immediately, log out and back in once."
