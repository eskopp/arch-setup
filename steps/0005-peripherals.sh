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

  msg "Installing Bluetooth, printer, scanner, and audio packages"
  sudo pacman -S --needed --noconfirm \
    avahi \
    bluez \
    bluez-utils \
    blueman \
    cups \
    cups-filters \
    cups-pk-helper \
    ipp-usb \
    nss-mdns \
    pavucontrol \
    pipewire \
    pipewire-alsa \
    pipewire-audio \
    pipewire-pulse \
    sane \
    sane-airscan \
    simple-scan \
    system-config-printer \
    wireplumber

  msg "Enabling system services"
  sudo systemctl enable --now bluetooth.service
  sudo systemctl enable --now cups.service
  sudo systemctl enable --now avahi-daemon.service

  if systemctl list-unit-files | grep -q '^ipp-usb\.service'; then
    sudo systemctl enable --now ipp-usb.service
  elif systemctl list-unit-files | grep -q '^ipp-usb\.socket'; then
    sudo systemctl enable --now ipp-usb.socket
  else
    msg "No ipp-usb systemd unit found, skipping activation"
  fi

  msg "Enabling PipeWire user services"
  systemctl --user daemon-reload
  systemctl --user enable --now pipewire.socket
  systemctl --user enable --now pipewire-pulse.socket
  systemctl --user enable --now wireplumber.service

  msg "0005 peripherals setup completed"
}

main "$@"
