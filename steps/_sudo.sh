#!/usr/bin/env bash

SUDO_KEEPALIVE_PID=""

cleanup_sudo_keepalive() {
  [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] || return 0
  kill "${SUDO_KEEPALIVE_PID}" >/dev/null 2>&1 || true
}

require_sudo_session() {
  command -v sudo > /dev/null 2>&1 || {
    echo "sudo is required but not installed." >&2
    return 1
  }

  sudo -v

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" > /dev/null 2>&1 || exit 0
  done 2> /dev/null &

  SUDO_KEEPALIVE_PID=$!
  trap cleanup_sudo_keepalive EXIT
}
