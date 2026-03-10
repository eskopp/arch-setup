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
  local target_user target_home root_fstype root_opts home_opts
  local root_subvol="" home_subvol=""

  [[ -f /etc/arch-release ]] || die "This setup only supports Arch Linux."
  [[ "${EUID}" -ne 0 ]] || die "Run this setup as a normal user, not as root."
  command -v sudo > /dev/null 2>&1 || die "sudo is required but not installed."

  target_user="${SUDO_USER:-$USER}"
  target_home="$(getent passwd "${target_user}" | cut -d: -f6)"
  [[ -n "${target_home}" && -d "${target_home}" ]] || die "Could not determine home directory for ${target_user}."

  msg "Running preflight checks"

  root_fstype="$(findmnt -no FSTYPE / 2> /dev/null || printf 'unknown')"
  root_opts="$(findmnt -no OPTIONS / 2> /dev/null || true)"
  home_opts="$(findmnt -no OPTIONS /home 2> /dev/null || true)"

  if [[ -n "$root_opts" ]]; then
    root_subvol="$(tr ',' '\n' <<< "$root_opts" | sed -n 's/^subvol=//p' | head -n1)"
  fi

  if [[ -n "$home_opts" ]]; then
    home_subvol="$(tr ',' '\n' <<< "$home_opts" | sed -n 's/^subvol=//p' | head -n1)"
  fi

  msg "Root filesystem type: ${root_fstype}"

  if [[ "$root_fstype" != "btrfs" ]]; then
    warn "Root filesystem is not Btrfs. The Timeshift step may fail later."
  fi

  if [[ -n "$root_subvol" && "$root_subvol" != "@" && "$root_subvol" != "/@" ]]; then
    warn "Root subvolume is '${root_subvol}', not '@'. The Timeshift step may fail later."
  fi

  if [[ -n "$home_subvol" && "$home_subvol" != "@home" && "$home_subvol" != "/@home" ]]; then
    warn "Home subvolume is '${home_subvol}', not '@home'. The Timeshift step may fail later."
  fi

  if getent hosts github.com > /dev/null 2>&1; then
    msg "DNS lookup for github.com succeeded"
  else
    warn "DNS lookup for github.com failed. Network access may not be ready."
  fi

  if systemctl is-enabled gdm.service > /dev/null 2>&1; then
    warn "gdm.service is enabled. Plan the cleanup step carefully."
  fi

  if systemctl is-enabled sddm.service > /dev/null 2>&1; then
    warn "sddm.service is enabled. Plan the cleanup step carefully."
  fi

  if [[ -d "${target_home}/.config/hypr" ]]; then
    msg "Hyprland config directory already exists: ${target_home}/.config/hypr"
  else
    warn "Hyprland config directory does not exist yet: ${target_home}/.config/hypr"
  fi

  msg "Disk usage for /"
  df -h / | sed -n '1,2p'

  msg "0000 preflight completed"
}

main "$@"
