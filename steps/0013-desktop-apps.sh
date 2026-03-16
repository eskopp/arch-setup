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
