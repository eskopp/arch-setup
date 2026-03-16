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
