#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

main() {
  require_sudo_session

  local packages=(
    firejail
    apparmor
  )

  msg "Installing Firejail and AppArmor from step 0012"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "Enabling AppArmor service"
  sudo systemctl enable --now apparmor.service

  msg "Writing local Firejail ignore list"
  sudo install -d -m 0755 /etc/firejail/firecfg.d
  sudo tee /etc/firejail/firecfg.d/99-local.conf >/dev/null <<'FIREJAIL_EOF'
!emacs
!nvim
!code
!code-oss
!alacritty
!foot
!ssh
FIREJAIL_EOF

  msg "Applying Firejail desktop integration"
  sudo firecfg

  if [[ -f /etc/apparmor.d/firejail-default ]]; then
    msg "Trying to load firejail-default AppArmor profile"
    sudo apparmor_parser -r /etc/apparmor.d/firejail-default || true
  fi

  if command -v aa-status >/dev/null 2>&1; then
    msg "Showing AppArmor status"
    local aa_out=""
    aa_out="$(sudo aa-status 2>&1 || true)"
    printf '%s\n' "$aa_out"

    if grep -q "apparmor filesystem is not mounted" <<<"$aa_out"; then
      warn "AppArmor kernel module is loaded, but the AppArmor filesystem is not mounted."
      warn "This usually means AppArmor is not fully enabled via kernel command line yet."
      warn "Check your bootloader/UKI configuration and then verify again after reboot."
      msg "Current kernel command line:"
      cat /proc/cmdline
    elif grep -q "apparmor module is loaded" <<<"$aa_out"; then
      msg "AppArmor module is loaded."
    else
      warn "Could not confirm that AppArmor is fully active."
      msg "Current kernel command line:"
      cat /proc/cmdline
    fi
  else
    warn "aa-status is not available."
  fi

  msg "0012 Firejail setup completed"
}

main "$@"
