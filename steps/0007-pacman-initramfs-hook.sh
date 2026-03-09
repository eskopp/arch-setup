#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  msg "Creating custom pacman hook for initramfs rebuilds"
  sudo install -d -m 755 /etc/pacman.d/hooks

  sudo tee /etc/pacman.d/hooks/95-mkinitcpio-extra.hook >/dev/null <<'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Rebuilding initramfs after pacman transaction
When = PostTransaction
Exec = /usr/bin/mkinitcpio -P
Depends = mkinitcpio
HOOK

  msg "Custom pacman hook installed at /etc/pacman.d/hooks/95-mkinitcpio-extra.hook"
}

main "$@"
