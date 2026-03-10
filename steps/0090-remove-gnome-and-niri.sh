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

  msg "Disabling graphical display managers for future boots when present"
  sudo systemctl disable gdm.service 2> /dev/null || true
  sudo systemctl disable sddm.service 2> /dev/null || true
  sudo rm -f /etc/systemd/system/display-manager.service 2> /dev/null || true

  if pacman -Sgq gnome > /dev/null 2>&1; then
    while IFS= read -r pkg; do
      [[ -n "${pkg}" ]] && group_pkgs+=("${pkg}")
    done < <(pacman -Qqg gnome 2> /dev/null || true)
  fi

  if pacman -Sgq gnome-extra > /dev/null 2>&1; then
    while IFS= read -r pkg; do
      [[ -n "${pkg}" ]] && group_pkgs+=("${pkg}")
    done < <(pacman -Qqg gnome-extra 2> /dev/null || true)
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
    if pacman -Q "${pkg}" > /dev/null 2>&1; then
      installed_pkgs+=("${pkg}")
    fi
  done

  if ((${#installed_pkgs[@]} > 0)); then
    mapfile -t remove_pkgs < <(printf '%s\n' "${installed_pkgs[@]}" | awk '!seen[$0]++')
    msg "Removing GNOME and Niri packages"
    sudo pacman -Rns --noconfirm "${remove_pkgs[@]}"
  else
    msg "No installed GNOME or Niri packages found to remove"
  fi

  msg "Removing leftover GNOME and Niri user files"
  rm -rf "${target_home}/.config/niri"
  rm -f "${target_home}/.config/autostart/"*wallpaper*.desktop 2> /dev/null || true
  rm -f "${target_home}/.local/bin/gnome-random-wallpaper.sh" 2> /dev/null || true

  msg "Removing leftover GNOME system configuration"
  sudo rm -f /etc/dconf/db/local.d/00-gnome
  sudo dconf update 2> /dev/null || true

  msg "0090 GNOME and Niri cleanup completed"
  warn "Run this step only when you are ready to remove GNOME and Niri from the machine."
}

main "$@"
