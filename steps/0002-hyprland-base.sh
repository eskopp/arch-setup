#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

run_for_target() {
  local target_user="$1"
  shift

  if [[ "$(id -un)" == "$target_user" ]]; then
    "$@"
  else
    sudo -u "$target_user" "$@"
  fi
}

main() {
  require_sudo_session
  local target_user target_home

  [[ -f /etc/arch-release ]] || die "This step only supports Arch Linux."
  [[ "${EUID}" -ne 0 ]] || die "Run this step as a normal user, not as root."

  target_user="${SUDO_USER:-$USER}"
  target_home="$(getent passwd "${target_user}" | cut -d: -f6)"
  [[ -n "${target_home}" && -d "${target_home}" ]] || die "Could not determine home directory for ${target_user}."

  msg "Stopping old iwd service when present"
  sudo systemctl disable --now iwd.service 2> /dev/null || true

  msg "Removing iwd when it is installed"
  if pacman -Q iwd > /dev/null 2>&1; then
    sudo pacman -Rns --noconfirm iwd
  fi

  msg "Installing base desktop packages for a Hyprland system"
  sudo pacman -S --needed --noconfirm networkmanager firefox xdg-utils

  msg "Enabling NetworkManager"
  sudo systemctl enable --now NetworkManager.service

  msg "Configuring lid close behavior"
  sudo install -d -m 0755 /etc/systemd/logind.conf.d
  printf '%s\n' \
    '[Login]' \
    'HandleLidSwitch=poweroff' \
    'HandleLidSwitchExternalPower=poweroff' \
    'HandleLidSwitchDocked=poweroff' |
    sudo tee /etc/systemd/logind.conf.d/80-lid-poweroff.conf > /dev/null

  msg "Setting Firefox as default browser for the current user"
  mkdir -p "${target_home}/.config"

  run_for_target "${target_user}" xdg-mime default firefox.desktop x-scheme-handler/http || true
  run_for_target "${target_user}" xdg-mime default firefox.desktop x-scheme-handler/https || true
  run_for_target "${target_user}" xdg-mime default firefox.desktop text/html || true
  run_for_target "${target_user}" xdg-mime default firefox.desktop application/xhtml+xml || true

  if command -v xdg-settings > /dev/null 2>&1; then
    run_for_target "${target_user}" xdg-settings set default-web-browser firefox.desktop || true
  fi

  msg "0002 hyprland base completed"
}

main "$@"
