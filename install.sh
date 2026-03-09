#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="$SCRIPT_DIR/steps"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

require_sudo_session() {
  command -v sudo >/dev/null 2>&1 || die "sudo is required but not installed."

  msg "Requesting sudo access..."
  sudo -v

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" >/dev/null 2>&1 || exit 0
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "${SUDO_KEEPALIVE_PID}" >/dev/null 2>&1 || true' EXIT
}

run_step() {
  local step="$1"
  msg "Running $(basename "$step")"
  bash "$step"
}

main() {
  shopt -s nullglob
  local steps=("$STEPS_DIR"/*.sh)

  [[ ${#steps[@]} -gt 0 ]] || die "No step scripts found in $STEPS_DIR"

  require_sudo_session

  for step in "${steps[@]}"; do
    run_step "$step"
  done
}

main "$@"
