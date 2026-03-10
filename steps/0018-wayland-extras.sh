#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  local packages=(
    cliphist
    grim
    playerctl
    rofi
    slurp
    swappy
    swayosd
    wev
    wofi
    wl-clipboard
  )

  msg "Installing Wayland helper applications from step 0018"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "0018 Wayland extras setup completed"
}

main "$@"
