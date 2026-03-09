#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

require_arch() {
  [[ -f /etc/arch-release ]] || die "This step only supports Arch Linux."
}

require_not_root() {
  [[ "${EUID}" -ne 0 ]] || die "Run this step as a normal user, not as root."
}

main() {
  require_arch
  require_not_root

  msg "Refreshing package databases and upgrading system"
  sudo pacman -Syu --noconfirm

  msg "Installing required base packages"
  sudo pacman -S --needed --noconfirm \
    base-devel \
    bash \
    ca-certificates \
    curl \
    git \
    rsync \
    tar \
    unzip \
    wget

  msg "Creating common user directories"
  mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/src" \
    "$HOME/.config" \
    "$HOME/git" \
    "$HOME/.cache"

  msg "0001 base setup completed"
}

main "$@"
