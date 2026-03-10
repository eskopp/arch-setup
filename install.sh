#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEPS_DIR="$SCRIPT_DIR/steps"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/arch-setup"
LOG_DIR="$STATE_DIR/logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/install_${RUN_ID}.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

declare -a RAN_STEPS=()
declare -a SKIPPED_STEPS=()
declare -a FAILED_STEPS=()

CURRENT_STEP=""
SUMMARY_PRINTED=0

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

print_step_list() {
  local title="$1"
  shift || true

  if [[ $# -eq 0 ]]; then
    printf '  %s: none\n' "$title"
    return 0
  fi

  printf '  %s:\n' "$title"
  printf '    - %s\n' "$@"
}

print_summary() {
  local status="$1"

  if [[ "$SUMMARY_PRINTED" -eq 1 ]]; then
    return 0
  fi

  SUMMARY_PRINTED=1

  echo
  msg "Install summary"
  printf '  Status: %s\n' "$( [[ "$status" -eq 0 ]] && printf 'success' || printf 'failed' )"
  printf '  Log file: %s\n' "$LOG_FILE"
  print_step_list "Ran steps" "${RAN_STEPS[@]}"
  print_step_list "Skipped steps" "${SKIPPED_STEPS[@]}"
  print_step_list "Failed steps" "${FAILED_STEPS[@]}"
}

on_exit() {
  local status="$1"
  local current_name=""

  if [[ -n "$CURRENT_STEP" ]]; then
    current_name="$(basename "$CURRENT_STEP")"
  fi

  if [[ "$status" -ne 0 && -n "$current_name" ]]; then
    if [[ ! " ${FAILED_STEPS[*]} " =~ [[:space:]]${current_name}[[:space:]] ]]; then
      FAILED_STEPS+=("$current_name")
    fi
  fi

  print_summary "$status"
}

trap 'on_exit "$?"' EXIT

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

warn_for_step() {
  local step_name="$1"

  case "$step_name" in
    0090-remove-gnome-and-niri.sh)
      warn "About to run ${step_name}."
      warn "This step removes GNOME and Niri packages and disables graphical display managers for future boots."
      warn "Do not run this lightly from a system where you still depend on the current graphical session."
      ;;
    0091-tty-login.sh)
      warn "About to run ${step_name}."
      warn "This step disables graphical login managers for future boots and switches the machine to tty login."
      warn "After later execution on the machine, a reboot is normally required."
      ;;
  esac
}

run_step() {
  local step="$1"
  local step_name
  step_name="$(basename "$step")"

  CURRENT_STEP="$step"

  warn_for_step "$step_name"
  msg "Running ${step_name}"

  if bash "$step"; then
    RAN_STEPS+=("$step_name")
    CURRENT_STEP=""
    return 0
  fi

  FAILED_STEPS+=("$step_name")
  die "Step failed: ${step_name}"
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
      msg "Skipping ${step_name} because it is listed in SKIP_STEPS"
      SKIPPED_STEPS+=("$step_name")
      continue
    fi

    run_step "$step"
  done
}

main "$@"
