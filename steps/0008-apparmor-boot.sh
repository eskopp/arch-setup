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

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

append_unique_csv() {
  local csv="$1"
  local item="$2"
  local IFS=','
  local part
  for part in $csv; do
    [[ "$part" == "$item" ]] && {
      printf '%s\n' "$csv"
      return 0
    }
  done
  if [[ -n "$csv" ]]; then
    printf '%s,%s\n' "$csv" "$item"
  else
    printf '%s\n' "$item"
  fi
}

normalize_options_line() {
  local line="$1"
  local options="${line#options }"
  local old_lsm="" new_lsm=""

  if [[ "$options" =~ (^|[[:space:]])apparmor= ]]; then
    options="$(sed -E 's/(^|[[:space:]])apparmor=[^[:space:]]+/\1apparmor=1/g' <<<"$options")"
  else
    options="$options apparmor=1"
  fi

  if [[ "$options" =~ (^|[[:space:]])lsm=([^[:space:]]+) ]]; then
    old_lsm="${BASH_REMATCH[2]}"
    new_lsm="$old_lsm"
    new_lsm="$(append_unique_csv "$new_lsm" "lockdown")"
    new_lsm="$(append_unique_csv "$new_lsm" "yama")"
    new_lsm="$(append_unique_csv "$new_lsm" "integrity")"
    new_lsm="$(append_unique_csv "$new_lsm" "apparmor")"
    options="$(sed -E "s@(^|[[:space:]])lsm=[^[:space:]]+@ lsm=${new_lsm}@g" <<<"$options")"
  else
    options="$options lsm=lockdown,yama,integrity,apparmor"
  fi

  options="$(xargs <<<"$options")"
  printf 'options %s\n' "$options"
}

main() {
  require_sudo_session

  [[ -d /boot/loader/entries ]] || die "No /boot/loader/entries found. This step currently supports systemd-boot style entries."
  shopt -s nullglob
  local entries=(/boot/loader/entries/*.conf)
  [[ ${#entries[@]} -gt 0 ]] || die "No loader entries found in /boot/loader/entries."

  msg "Patching systemd-boot loader entries for AppArmor"
  local entry had_options new_line backup
  for entry in "${entries[@]}"; do
    backup="${entry}.bak.$(date +%Y%m%d_%H%M%S)"
    sudo cp -a "$entry" "$backup"

    had_options=0
    if grep -q '^options ' "$entry"; then
      had_options=1
      new_line="$(normalize_options_line "$(grep '^options ' "$entry" | tail -n1)")"
      sudo awk -v new_line="$new_line" '
        BEGIN { done=0 }
        /^options / {
          if (!done) {
            print new_line
            done=1
          }
          next
        }
        { print }
      ' "$entry" | sudo tee "$entry" >/dev/null
    else
      new_line="$(normalize_options_line 'options')"
      sudo tee -a "$entry" >/dev/null <<<"$new_line"
    fi

    msg "Updated $(basename "$entry")"
    if [[ "$had_options" -eq 0 ]]; then
      warn "No existing options line was found; appended a new one."
    fi
  done

  msg "Resulting loader entry options:"
  grep -H '^options ' /boot/loader/entries/*.conf || true

  msg "Current running kernel command line (will only change after reboot):"
  cat /proc/cmdline

  warn "Reboot is required before AppArmor becomes fully active via the new boot parameters."
}

main "$@"
