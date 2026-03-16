#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  require_sudo_session
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
