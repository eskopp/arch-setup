#!/usr/bin/env bash

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
  local sudo_keepalive_pid=$!
  trap 'kill "${sudo_keepalive_pid:-}" >/dev/null 2>&1 || true' EXIT
}
