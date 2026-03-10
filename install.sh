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

normalize_step_name() {
  local raw="$1"
  local base
  base="$(basename "$raw")"

  if [[ "$base" != *.sh ]]; then
    base="${base}.sh"
  fi

  printf '%s\n' "$base"
}

is_skipped_step() {
  local step_name="$1"
  local skipped normalized

  for skipped in ${SKIP_STEPS:-}; do
    normalized="$(normalize_step_name "$skipped")"
    if [[ "$step_name" == "$normalized" ]]; then
      return 0
    fi
  done

  return 1
}

collect_steps() {
  local requested=("$@")
  local resolved=()
  local name step

  shopt -s nullglob

  if [[ ${#requested[@]} -eq 0 ]]; then
    resolved=("$STEPS_DIR"/*.sh)
  else
    for name in "${requested[@]}"; do
      name="$(normalize_step_name "$name")"
      step="$STEPS_DIR/$name"
      [[ -f "$step" ]] || die "Requested step not found: $name"
      resolved+=("$step")
    done
  fi

  [[ ${#resolved[@]} -gt 0 ]] || die "No step scripts found in $STEPS_DIR"

  printf '%s\n' "${resolved[@]}"
}

run_step() {
  local step="$1"
  msg "Running $(basename "$step")"
  bash "$step"
}

main() {
  local requested_steps=("$@")
  local collected=()
  local step step_name

  require_sudo_session

  while IFS= read -r step; do
    collected+=("$step")
  done < <(collect_steps "${requested_steps[@]}")

  for step in "${collected[@]}"; do
    step_name="$(basename "$step")"

    if is_skipped_step "$step_name"; then
      msg "Skipping $step_name because it is listed in SKIP_STEPS"
      continue
    fi

    run_step "$step"
  done
}

main "$@"
