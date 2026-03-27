#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=steps/_sudo.sh
if [[ -f "$SCRIPT_DIR/_sudo.sh" ]]; then
  source "$SCRIPT_DIR/_sudo.sh"
else
  echo "Missing _sudo.sh in $SCRIPT_DIR"
  exit 1
fi

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

# -------------------------
# OS CHECK
# -------------------------
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "Cannot read /etc/os-release"
  exit 1
fi

if [[ "${ID:-}" != "arch" ]]; then
  echo "This script only supports Arch Linux."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required but not installed."
  exit 1
fi

require_sudo_session

# -------------------------
# INSTALL
# -------------------------
log "Installing Mullvad and keyd..."
sudo pacman -S --needed --noconfirm mullvad-vpn keyd

# -------------------------
# CHECK MULLVAD SERVICE
# -------------------------
if ! systemctl list-unit-files mullvad-daemon.service &>/dev/null; then
  echo "mullvad-daemon.service not found after installation."
  exit 1
fi

log "Enabling and starting Mullvad daemon..."
sudo systemctl enable --now mullvad-daemon.service

log "Verifying Mullvad daemon state..."
if ! systemctl is-active --quiet mullvad-daemon.service; then
  echo "mullvad-daemon.service is not active after startup."
  sudo systemctl status --no-pager mullvad-daemon.service || true
  exit 1
fi

# -------------------------
# CHECK KEYD
# -------------------------
if ! command -v keyd >/dev/null 2>&1; then
  echo "keyd not found after installation."
  exit 1
fi

# -------------------------
# CONFIGURE KEYD
# -------------------------
log "Writing keyd config..."
sudo mkdir -p /etc/keyd

sudo tee /etc/keyd/ugreen-sidebuttons.conf >/dev/null << 'KEYDEOF'
[ids]
k:2b89:0043:595906dd

[meta]
[ = A-left
] = A-right
KEYDEOF

# -------------------------
# VALIDATE CONFIG
# -------------------------
log "Checking keyd config..."
if ! sudo keyd check; then
  echo "keyd config validation failed"
  exit 1
fi

# -------------------------
# ENABLE + START KEYD
# -------------------------
if ! systemctl is-enabled --quiet keyd.service >/dev/null 2>&1; then
  log "Enabling keyd daemon..."
  sudo systemctl enable keyd.service
fi

if ! systemctl is-active --quiet keyd.service >/dev/null 2>&1; then
  log "Starting keyd daemon..."
  sudo systemctl start keyd.service
fi

# -------------------------
# WAIT FOR SOCKET
# -------------------------
log "Waiting for keyd socket..."
for _ in {1..20}; do
  if sudo test -S /var/run/keyd.socket; then
    break
  fi
  sleep 0.2
done

if ! sudo test -S /var/run/keyd.socket; then
  echo "keyd.socket did not become available"
  sudo systemctl status --no-pager keyd.service || true
  exit 1
fi

# -------------------------
# RELOAD
# -------------------------
log "Reloading keyd..."
sudo keyd reload

echo
echo "Done."
echo "Mullvad daemon is enabled."
echo "UGREEN side buttons are configured through keyd."
