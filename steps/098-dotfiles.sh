#!/usr/bin/env bash
set -euo pipefail

# Run the user's dotfiles installer from ~/git/dotfiles/install.sh.
# This step is intentionally placed near the end of the setup flow.

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

DOTFILES_DIR="${TARGET_HOME}/git/dotfiles"
DOTFILES_INSTALL="${DOTFILES_DIR}/install.sh"

if [[ ! -d "${DOTFILES_DIR}" ]]; then
  echo "Dotfiles directory not found:"
  echo "  ${DOTFILES_DIR}"
  exit 1
fi

if [[ ! -f "${DOTFILES_INSTALL}" ]]; then
  echo "Dotfiles installer not found:"
  echo "  ${DOTFILES_INSTALL}"
  exit 1
fi

echo "Ensuring dotfiles installer is executable..."
chmod +x "${DOTFILES_INSTALL}"

echo "Running dotfiles installer as '${TARGET_USER}'..."
run_for_target env HOME="${TARGET_HOME}" bash -lc "cd '${DOTFILES_DIR}' && './install.sh'"

echo
echo "Done."
echo "Dotfiles installer has been executed from:"
echo "  ${DOTFILES_INSTALL}"
