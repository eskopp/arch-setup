#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  local packages=(
    bitwarden
    code
    dbeaver
    foot
    kitty
    nextcloud-client
    xournalpp
  )

  msg "Installing desktop applications from step 0013"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "0013 desktop apps setup completed"
}

main "$@"
