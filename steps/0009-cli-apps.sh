#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  local packages=(
    7zip
    btop
    chafa
    fastfetch
    fzf
    gnupg
    htop
    jq
    nano
    openbsd-netcat
    openssh
    smartmontools
    tmux
    tree
    vim
    wget
    zip
    zoxide
  )

  msg "Installing CLI applications from step 0009"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "0009 CLI apps setup completed"
}

main "$@"
