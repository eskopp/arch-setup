#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

main() {
  require_sudo_session

  local target_user target_home
  target_user="${SUDO_USER:-$USER}"
  target_home="$(getent passwd "${target_user}" | cut -d: -f6)"
  [[ -n "${target_home}" && -d "${target_home}" ]] || die "Could not determine home directory for ${target_user}."

  msg "Installing notification helper package"
  sudo pacman -S --needed --noconfirm libnotify

  msg "Writing security notification config"
  sudo tee /etc/security-notify.conf >/dev/null <<EOFCONF
TARGET_USER=${target_user}
POLL_SECONDS=20
EOFCONF

  msg "Writing watcher script"
  sudo install -d -m 0755 /usr/local/bin /var/lib/security-notify
  sudo tee /usr/local/bin/security-notify-watch.sh >/dev/null <<'WATCHEREOF'
#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG="/etc/security-notify.conf"
[[ -r "$CONFIG" ]] && . "$CONFIG"

TARGET_USER="${TARGET_USER:-erik}"
POLL_SECONDS="${POLL_SECONDS:-20}"
STATE_DIR="/var/lib/security-notify"
LAST_FILE="${STATE_DIR}/last_ts"

mkdir -p "$STATE_DIR"

target_uid="$(id -u "$TARGET_USER")"

notify_user() {
  local title="$1"
  local body="$2"
  local urgency="${3:-normal}"
  local runtime_dir="/run/user/${target_uid}"
  local bus="${runtime_dir}/bus"

  [[ -d "$runtime_dir" && -S "$bus" ]] || return 0

  runuser -u "$TARGET_USER" -- env \
    XDG_RUNTIME_DIR="$runtime_dir" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=${bus}" \
    /usr/bin/notify-send \
      -a "Security Watch" \
      -u "$urgency" \
      "$title" \
      "$body" || true
}

summarize_ufw_line() {
  local line="$1"
  local tag="EVENT" src="?" dst="?" proto="?" dpt="?"
  [[ "$line" =~ UFW[[:space:]]+([A-Z]+) ]] && tag="${BASH_REMATCH[1]}"
  [[ "$line" =~ SRC=([^[:space:]]+) ]] && src="${BASH_REMATCH[1]}"
  [[ "$line" =~ DST=([^[:space:]]+) ]] && dst="${BASH_REMATCH[1]}"
  [[ "$line" =~ PROTO=([^[:space:]]+) ]] && proto="${BASH_REMATCH[1]}"
  [[ "$line" =~ DPT=([^[:space:]]+) ]] && dpt="${BASH_REMATCH[1]}"
  printf '%s %s -> %s %s/%s' "$tag" "$src" "$dst" "$proto" "$dpt"
}

summarize_apparmor_line() {
  local line="$1"
  local profile="?" operation="?" name="?"
  [[ "$line" =~ profile=\"([^\"]+)\" ]] && profile="${BASH_REMATCH[1]}"
  [[ "$line" =~ operation=\"([^\"]+)\" ]] && operation="${BASH_REMATCH[1]}"
  [[ "$line" =~ name=\"([^\"]+)\" ]] && name="${BASH_REMATCH[1]}"
  printf 'profile=%s op=%s target=%s' "$profile" "$operation" "$name"
}

if [[ ! -f "$LAST_FILE" ]]; then
  date +%s > "$LAST_FILE"
  notify_user "Security Watch aktiv" "Überwache UFW, Fail2ban und AppArmor." low
fi

while true; do
  now="$(date +%s)"
  since="$(cat "$LAST_FILE" 2>/dev/null || echo "$((now - POLL_SECONDS))")"
  printf '%s\n' "$now" > "${LAST_FILE}.tmp"
  mv "${LAST_FILE}.tmp" "$LAST_FILE"

  mapfile -t f2b_lines < <(
    journalctl \
      --since "@${since}" \
      --until "@${now}" \
      -u fail2ban.service \
      -o cat \
      --no-pager 2>/dev/null | grep -E ' Ban | Unban ' || true
  )

  if ((${#f2b_lines[@]} > 0)); then
    local_count=0
    for line in "${f2b_lines[@]}"; do
      if [[ "$line" =~ Ban[[:space:]]+([^[:space:]]+) ]]; then
        notify_user "Fail2ban: Ban" "${BASH_REMATCH[1]}" critical
        local_count=$((local_count + 1))
      elif [[ "$line" =~ Unban[[:space:]]+([^[:space:]]+) ]]; then
        notify_user "Fail2ban: Unban" "${BASH_REMATCH[1]}" normal
        local_count=$((local_count + 1))
      fi
      [[ "$local_count" -ge 3 ]] && break
    done
    if ((${#f2b_lines[@]} > 3)); then
      notify_user "Fail2ban" "+$(( ${#f2b_lines[@]} - 3 )) weitere Ereignisse" low
    fi
  fi

  mapfile -t ufw_lines < <(
    journalctl \
      -k \
      --since "@${since}" \
      --until "@${now}" \
      -o cat \
      --no-pager 2>/dev/null | grep -E 'UFW (BLOCK|DENY|AUDIT)' || true
  )

  if ((${#ufw_lines[@]} > 0)); then
    body=""
    shown=0
    for line in "${ufw_lines[@]}"; do
      body+="$(summarize_ufw_line "$line")"$'\n'
      shown=$((shown + 1))
      [[ "$shown" -ge 3 ]] && break
    done
    if ((${#ufw_lines[@]} > 3)); then
      body+="+$(( ${#ufw_lines[@]} - 3 )) weitere Treffer"
    fi
    notify_user "UFW: ${#ufw_lines[@]} Treffer" "$body" normal
  fi

  mapfile -t aa_lines < <(
    journalctl \
      --since "@${since}" \
      --until "@${now}" \
      -o cat \
      --no-pager 2>/dev/null | grep -E 'apparmor="DENIED"|AppArmor DENIED' || true
  )

  if ((${#aa_lines[@]} > 0)); then
    body=""
    shown=0
    for line in "${aa_lines[@]}"; do
      body+="$(summarize_apparmor_line "$line")"$'\n'
      shown=$((shown + 1))
      [[ "$shown" -ge 3 ]] && break
    done
    if ((${#aa_lines[@]} > 3)); then
      body+="+$(( ${#aa_lines[@]} - 3 )) weitere Treffer"
    fi
    notify_user "AppArmor: Denied" "$body" critical
  fi

  sleep "$POLL_SECONDS"
done
WATCHEREOF
  sudo chmod 0755 /usr/local/bin/security-notify-watch.sh

  msg "Writing systemd service"
  sudo tee /etc/systemd/system/security-notify.service >/dev/null <<'SERVICEEOF'
[Unit]
Description=Desktop security notifications for UFW, Fail2ban and AppArmor
After=network-online.target fail2ban.service apparmor.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/security-notify-watch.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

  msg "Enabling security notification service"
  sudo systemctl daemon-reload
  sudo systemctl enable --now security-notify.service

  msg "0096 security notification setup completed"
  msg "Check service logs with: journalctl -u security-notify.service -f"
}

main "$@"
