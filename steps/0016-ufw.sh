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
    ufw
  )

  msg "Installing UFW from step 0016"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "Resetting UFW to a known state"
  sudo ufw --force reset

  msg "Setting sane UFW defaults"
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw logging low

  msg "Allowing SSH with rate limiting"
  sudo ufw limit 22/tcp comment 'SSH'

  msg "Enabling UFW"
  sudo ufw --force enable

  msg "Showing UFW status"
  sudo ufw status verbose

  msg "0016 UFW setup completed"
  msg "Note: published Docker ports can bypass UFW; handle Docker exposure separately."
}

main "$@"
