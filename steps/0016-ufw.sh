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

  msg "Disabling SSH server on client laptop"
  sudo systemctl disable --now sshd.service 2>/dev/null || true
  sudo systemctl mask sshd.service 2>/dev/null || true

  msg "Resetting UFW to a known state"
  sudo ufw --force reset

  msg "Setting sane UFW defaults"
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw logging low

  msg "Ensuring no SSH allow/limit rules remain"
  sudo ufw delete limit 22/tcp 2>/dev/null || true
  sudo ufw delete allow 22/tcp 2>/dev/null || true

  msg "Enabling UFW"
  sudo ufw --force enable

  msg "Showing UFW status"
  sudo ufw status verbose

  msg "0016 UFW setup completed"
  msg "This client profile blocks all incoming connections by default and does not expose SSH."
  msg "Note: published Docker ports can bypass UFW; handle Docker exposure separately."
}

main "$@"
