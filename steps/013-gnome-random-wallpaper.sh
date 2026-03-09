#!/usr/bin/env bash
set -euo pipefail

# Ensure nord-background exists in ~/git and configure GNOME
# to pick a random wallpaper from that folder on every login.

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
else
  echo "Cannot read /etc/os-release"
  exit 1
fi

if [[ "${ID:-}" != "arch" ]]; then
  echo "This script only supports Arch Linux."
  exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "Could not determine home directory for user '${TARGET_USER}'."
  exit 1
fi

run_for_target() {
  if [[ "$(id -un)" == "${TARGET_USER}" ]]; then
    "$@"
  else
    sudo -u "${TARGET_USER}" "$@"
  fi
}

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not installed."
  exit 1
fi

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings is required but not installed."
  exit 1
fi

echo "Ensuring ${TARGET_HOME}/git exists..."
run_for_target mkdir -p "${TARGET_HOME}/git"

WALLPAPER_DIR="${TARGET_HOME}/git/nord-background"
WALLPAPER_REPO="https://github.com/eskopp/nord-background"

if [[ -d "${WALLPAPER_DIR}" ]]; then
  echo "Wallpaper repo already exists: ${WALLPAPER_DIR}"
else
  echo "Cloning wallpaper repo..."
  run_for_target git clone "${WALLPAPER_REPO}" "${WALLPAPER_DIR}"
fi

echo "Creating wallpaper helper script..."
run_for_target mkdir -p "${TARGET_HOME}/.local/bin"
run_for_target mkdir -p "${TARGET_HOME}/.config/autostart"

TMP_SCRIPT="$(mktemp)"
cat > "${TMP_SCRIPT}" <<'SCRIPTEOF'
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${HOME}/git/nord-background"

if [[ ! -d "${WALLPAPER_DIR}" ]]; then
  exit 0
fi

mapfile -d '' IMAGES < <(
  find "${WALLPAPER_DIR}" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -print0
)

if (( ${#IMAGES[@]} == 0 )); then
  exit 0
fi

SELECTED="${IMAGES[RANDOM % ${#IMAGES[@]}]}"
URI="file://${SELECTED}"

gsettings set org.gnome.desktop.background picture-uri "${URI}"
gsettings set org.gnome.desktop.background picture-uri-dark "${URI}"
gsettings set org.gnome.desktop.background picture-options 'zoom'
SCRIPTEOF

install -m 755 "${TMP_SCRIPT}" "${TARGET_HOME}/.local/bin/gnome-random-wallpaper.sh"
rm -f "${TMP_SCRIPT}"

TMP_DESKTOP="$(mktemp)"
cat > "${TMP_DESKTOP}" <<DESKTOPEOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Random Nord Wallpaper
Comment=Set a random wallpaper from nord-background at GNOME login
Exec=${TARGET_HOME}/.local/bin/gnome-random-wallpaper.sh
Terminal=false
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
DESKTOPEOF

install -m 644 "${TMP_DESKTOP}" "${TARGET_HOME}/.config/autostart/random-nord-wallpaper.desktop"
rm -f "${TMP_DESKTOP}"

if [[ "$(id -u)" -eq 0 ]]; then
  chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.local/bin/gnome-random-wallpaper.sh"
  chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/autostart/random-nord-wallpaper.desktop"
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* && -n "${DBUS_SESSION_BUS_ADDRESS:-}" && "$(id -un)" == "${TARGET_USER}" ]]; then
  echo "Applying a random wallpaper now..."
  "${TARGET_HOME}/.local/bin/gnome-random-wallpaper.sh" || true
else
  echo "Wallpaper autostart is configured."
  echo "A random wallpaper will be set on the next GNOME login."
fi

echo "Done."
