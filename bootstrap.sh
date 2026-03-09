#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/eskopp/arch-setup.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_NAME="${REPO_NAME:-arch-setup}"
TARGET_DIR="${TARGET_DIR:-$HOME/git/$REPO_NAME}"
INSTALL_SCRIPT="${INSTALL_SCRIPT:-install.sh}"

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

require_arch() {
  [[ -f /etc/arch-release ]] || die "This bootstrap script only supports Arch Linux."
}

require_not_root() {
  [[ "${EUID}" -ne 0 ]] || die "Please run this script as a normal user, not as root."
}

require_sudo() {
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

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  msg "git is missing. Installing git..."
  sudo pacman -S --needed --noconfirm git
}

clone_or_update_repo() {
  local parent_dir
  parent_dir="$(dirname "$TARGET_DIR")"
  mkdir -p "$parent_dir"

  if [[ -d "$TARGET_DIR/.git" ]]; then
    msg "Existing repository found in $TARGET_DIR"

    if ! git -C "$TARGET_DIR" diff --quiet || ! git -C "$TARGET_DIR" diff --cached --quiet; then
      die "Repository in $TARGET_DIR has uncommitted changes. Please commit or stash them first."
    fi

    msg "Updating repository..."
    git -C "$TARGET_DIR" fetch origin "$REPO_BRANCH" --prune
    git -C "$TARGET_DIR" checkout "$REPO_BRANCH"
    git -C "$TARGET_DIR" pull --ff-only origin "$REPO_BRANCH"
    return 0
  fi

  if [[ -e "$TARGET_DIR" ]] && [[ -n "$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    die "Target directory $TARGET_DIR already exists and is not an empty git repository."
  fi

  msg "Cloning repository..."
  git clone --branch "$REPO_BRANCH" "$REPO_URL" "$TARGET_DIR"
}

run_install() {
  local full_install_script="$TARGET_DIR/$INSTALL_SCRIPT"

  if [[ ! -f "$full_install_script" ]]; then
    warn "Install script not found: $full_install_script"
    warn "Repository was cloned successfully, but no installer is present yet."
    return 0
  fi

  msg "Starting installer..."
  cd "$TARGET_DIR"
  chmod +x "$full_install_script"
  bash "$full_install_script"
}

main() {
  require_arch
  require_not_root
  require_sudo
  ensure_git
  clone_or_update_repo
  run_install
}

main "$@"
