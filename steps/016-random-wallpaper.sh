#!/usr/bin/env bash
set -euo pipefail

# Ensure nord-background exists, create an swww random wallpaper helper,
# and hook it into Niri and Hyprland startup when their configs exist.

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

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required but not installed."
  exit 1
fi

sudo -v

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

WALLPAPER_REPO="https://github.com/eskopp/nord-background"
WALLPAPER_DIR="${TARGET_HOME}/git/nord-background"
RANDOMIZER_SCRIPT="${TARGET_HOME}/.local/bin/polarway-wallpaper-random"
NIRI_CONFIG="${TARGET_HOME}/.config/niri/config.kdl"
HYPR_CONFIG="${TARGET_HOME}/.config/hypr/hyprland.conf"

echo "Installing required packages..."
sudo pacman -S --needed --noconfirm git swww

echo "Ensuring git directory exists..."
run_for_target mkdir -p "${TARGET_HOME}/git"

if [[ -d "${WALLPAPER_DIR}/.git" ]]; then
  echo "Wallpaper repo already exists: ${WALLPAPER_DIR}"
else
  if [[ -d "${WALLPAPER_DIR}" ]]; then
    echo "Wallpaper directory exists but is not a git repo: ${WALLPAPER_DIR}"
    echo "Leaving it untouched."
  else
    echo "Cloning wallpaper repo..."
    run_for_target git clone "${WALLPAPER_REPO}" "${WALLPAPER_DIR}"
  fi
fi

echo "Creating wallpaper randomizer script..."
run_for_target mkdir -p "${TARGET_HOME}/.local/bin"

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

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  swww-daemon >/dev/null 2>&1 &
  for _ in $(seq 1 20); do
    if swww query >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done
fi

swww img "${SELECTED}" \
  --transition-type any \
  --transition-duration 1
SCRIPTEOF

install -m 755 "${TMP_SCRIPT}" "${RANDOMIZER_SCRIPT}"
rm -f "${TMP_SCRIPT}"

if [[ "$(id -u)" -eq 0 ]]; then
  chown "${TARGET_USER}:${TARGET_USER}" "${RANDOMIZER_SCRIPT}"
fi

echo "Hooking wallpaper script into compositor configs when present..."

if [[ -f "${NIRI_CONFIG}" ]]; then
  if ! grep -Fq "${RANDOMIZER_SCRIPT}" "${NIRI_CONFIG}"; then
    printf '\nspawn-at-startup "%s"\n' "${RANDOMIZER_SCRIPT}" >> "${NIRI_CONFIG}"
    echo "Added startup hook to Niri config."
  else
    echo "Niri config already contains the wallpaper script."
  fi
else
  echo "Niri config not found, skipping Niri hook."
fi

if [[ -f "${HYPR_CONFIG}" ]]; then
  if ! grep -Fq "${RANDOMIZER_SCRIPT}" "${HYPR_CONFIG}"; then
    printf '\nexec-once = %s\n' "${RANDOMIZER_SCRIPT}" >> "${HYPR_CONFIG}"
    echo "Added startup hook to Hyprland config."
  else
    echo "Hyprland config already contains the wallpaper script."
  fi
else
  echo "Hyprland config not found, skipping Hyprland hook."
fi

echo
echo "Done."
echo "Wallpaper repo: ${WALLPAPER_DIR}"
echo "Randomizer script: ${RANDOMIZER_SCRIPT}"
echo "A random wallpaper will be applied on startup in Niri/Hyprland when configured above."
