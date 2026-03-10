#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

main() {
  local target_user target_home
  local -a remove_pkgs=()
  local -a group_pkgs=()
  local -a extra_pkgs=()
  local -a installed_pkgs=()

  [[ -f /etc/arch-release ]] || die "This step only supports Arch Linux."
  [[ "${EUID}" -ne 0 ]] || die "Run this step as a normal user, not as root."

  target_user="${SUDO_USER:-$USER}"
  target_home="$(getent passwd "${target_user}" | cut -d: -f6)"

  [[ -n "${target_home}" && -d "${target_home}" ]] || die "Could not determine home directory for ${target_user}."

  msg "Installing generic desktop essentials"
  sudo pacman -S --needed --noconfirm networkmanager firefox xdg-utils

  msg "Enabling NetworkManager"
  sudo systemctl enable NetworkManager.service

  msg "Disabling GNOME display manager for future boots when present"
  sudo systemctl disable gdm.service 2>/dev/null || true
  sudo rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true

  if pacman -Sgq gnome >/dev/null 2>&1; then
    while IFS= read -r pkg; do
      [[ -n "${pkg}" ]] && group_pkgs+=("${pkg}")
    done < <(pacman -Qqg gnome 2>/dev/null || true)
  fi

  if pacman -Sgq gnome-extra >/dev/null 2>&1; then
    while IFS= read -r pkg; do
      [[ -n "${pkg}" ]] && group_pkgs+=("${pkg}")
    done < <(pacman -Qqg gnome-extra 2>/dev/null || true)
  fi

  extra_pkgs=(
    gdm
    gnome-shell
    gnome-session
    gnome-console
    gnome-control-center
    gnome-backgrounds
    gnome-keyring
    gnome-tweaks
    xdg-desktop-portal-gnome
    niri
  )

  for pkg in "${group_pkgs[@]}" "${extra_pkgs[@]}"; do
    if pacman -Q "${pkg}" >/dev/null 2>&1; then
      installed_pkgs+=("${pkg}")
    fi
  done

  if (( ${#installed_pkgs[@]} > 0 )); then
    mapfile -t remove_pkgs < <(printf '%s\n' "${installed_pkgs[@]}" | awk '!seen[$0]++')
    msg "Removing GNOME and Niri packages"
    sudo pacman -Rns --noconfirm "${remove_pkgs[@]}"
  else
    msg "No installed GNOME or Niri packages found to remove"
  fi

  msg "Removing GNOME and Niri user leftovers"
  rm -rf "${target_home}/.config/niri"
  rm -f "${target_home}/.config/autostart/random-nord-wallpaper.desktop"
  rm -f "${target_home}/.local/bin/gnome-random-wallpaper.sh"

  msg "Removing GNOME system configuration leftovers"
  sudo rm -f /etc/dconf/db/local.d/00-gnome
  sudo dconf update 2>/dev/null || true

  msg "Configuring lid close behavior"
  sudo install -d -m 0755 /etc/systemd/logind.conf.d
  printf '%s\n' \
    '[Login]' \
    'HandleLidSwitch=poweroff' \
    'HandleLidSwitchExternalPower=poweroff' \
    'HandleLidSwitchDocked=poweroff' \
    | sudo tee /etc/systemd/logind.conf.d/80-lid-poweroff.conf >/dev/null

  msg "Setting Firefox as default browser for the current user"
  mkdir -p "${target_home}/.config"
  printf '%s\n' \
    '[Default Applications]' \
    'x-scheme-handler/http=firefox.desktop' \
    'x-scheme-handler/https=firefox.desktop' \
    'text/html=firefox.desktop' \
    'application/xhtml+xml=firefox.desktop' \
    > "${target_home}/.config/mimeapps.list"

  if command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser firefox.desktop || true
  fi

  msg "0002 hyprland base completed"
  warn "Running this setup later may remove GNOME packages from the machine."
  warn "Do not do that while you still depend on a live GNOME session."
}

main "$@"
