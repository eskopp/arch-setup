#!/usr/bin/env bash
set -Eeuo pipefail

AUR_BUILD_ROOT="${AUR_BUILD_ROOT:-$HOME/.cache/arch-setup/aur}"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

require_not_root() {
  [[ "${EUID}" -ne 0 ]] || die "Run this step as a normal user, not as root."
}

ensure_dependencies() {
  msg "Installing AUR build dependencies"
  sudo pacman -S --needed --noconfirm base-devel git
}

build_and_install_aur_pkg() {
  local pkgbase="$1"
  local repo_url="https://aur.archlinux.org/${pkgbase}.git"
  local workdir="$AUR_BUILD_ROOT/$pkgbase"

  mkdir -p "$AUR_BUILD_ROOT"

  if [[ -d "$workdir/.git" ]]; then
    msg "Updating existing AUR checkout: $pkgbase"
    git -C "$workdir" fetch --all --prune
    git -C "$workdir" reset --hard origin/master
    git -C "$workdir" clean -fdx
  else
    msg "Cloning AUR package: $pkgbase"
    git clone "$repo_url" "$workdir"
  fi

  msg "Building and installing $pkgbase"
  (
    cd "$workdir"
    makepkg -si --noconfirm --needed
  )
}

main() {
  require_not_root
  ensure_dependencies

  build_and_install_aur_pkg "paru-bin"

  msg "0008 AUR helper setup completed"
}

main "$@"
