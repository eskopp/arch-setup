#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  local packages=(
    discord
    mattermost-desktop
    mullvad-vpn
    spotify-launcher
    thunderbird
  )

  msg "Installing communication applications from step 0015"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "0015 communication apps setup completed"
}

main "$@"
