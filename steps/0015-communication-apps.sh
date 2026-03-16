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
