#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GITHUB_USER="${GITHUB_USER:-eskopp}"
GIT_ROOT="${GIT_ROOT:-$HOME/git}"
CLOUD_ROOT="${CLOUD_ROOT:-$HOME/cloud}"

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

ensure_directories() {
  msg "Creating base directories"
  mkdir -p \
    "$GIT_ROOT" \
    "$CLOUD_ROOT/erik" \
    "$CLOUD_ROOT/silke" \
    "$CLOUD_ROOT/ilmenauersv" \
    "$CLOUD_ROOT/rias"
}

ensure_link() {
  local target="$1"
  local link_path="$2"

  if [[ -L "$link_path" ]]; then
    local current_target expected_target
    current_target="$(readlink -f "$link_path" 2> /dev/null || true)"
    expected_target="$(readlink -f "$target" 2> /dev/null || true)"

    if [[ "$current_target" == "$expected_target" ]]; then
      msg "Symlink already correct: $link_path -> $target"
      return 0
    fi

    rm -f "$link_path"
  elif [[ -e "$link_path" ]]; then
    warn "Path exists and is not a symlink, skipping: $link_path"
    return 0
  fi

  ln -s "$target" "$link_path"
  msg "Created symlink: $link_path -> $target"
}

setup_shortcuts() {
  msg "Creating cloud shortcuts in home directory"
  ensure_link "$CLOUD_ROOT/erik" "$HOME/erik"
  ensure_link "$CLOUD_ROOT/silke" "$HOME/silke"
  ensure_link "$CLOUD_ROOT/ilmenauersv" "$HOME/ilmenauersv"
  ensure_link "$CLOUD_ROOT/rias" "$HOME/rias"
}

ensure_repo_dependencies() {
  msg "Installing dependencies for GitHub repository sync"
  sudo pacman -S --needed --noconfirm curl git jq
}

clone_or_update_repo() {
  local repo_name="$1"
  local clone_url="$2"
  local target_dir="$GIT_ROOT/$repo_name"

  if [[ "$(realpath "$target_dir" 2> /dev/null || true)" == "$(realpath "$REPO_ROOT")" ]]; then
    msg "Skipping current repository: $repo_name"
    return 0
  fi

  if [[ -d "$target_dir/.git" ]]; then
    msg "Updating existing repository: $repo_name"
    git -C "$target_dir" fetch --all --prune

    if ! git -C "$target_dir" pull --ff-only; then
      warn "Could not fast-forward repository: $repo_name"
    fi

    return 0
  fi

  if [[ -e "$target_dir" ]]; then
    warn "Target exists and is not a git repository, skipping: $target_dir"
    return 0
  fi

  msg "Cloning repository: $repo_name"
  git clone "$clone_url" "$target_dir"
}

sync_public_repos() {
  local page=1
  local api_url repos_json repo_count

  msg "Syncing public repositories for GitHub user: $GITHUB_USER"

  while true; do
    api_url="https://api.github.com/users/${GITHUB_USER}/repos?type=owner&sort=full_name&per_page=100&page=${page}"

    repos_json="$(curl -fsSL \
      -H 'Accept: application/vnd.github+json' \
      -H 'X-GitHub-Api-Version: 2022-11-28' \
      "$api_url")"

    repo_count="$(printf '%s' "$repos_json" | jq 'length')"

    if [[ "$repo_count" -eq 0 ]]; then
      break
    fi

    while IFS=$'\t' read -r repo_name clone_url; do
      [[ -n "$repo_name" ]] || continue
      [[ -n "$clone_url" ]] || continue
      clone_or_update_repo "$repo_name" "$clone_url"
    done < <(printf '%s' "$repos_json" | jq -r '.[] | [.name, .clone_url] | @tsv')

    ((page++))
  done
}

main() {
  require_sudo_session
  ensure_directories
  setup_shortcuts
  ensure_repo_dependencies
  sync_public_repos
  msg "0006 cloud and repository setup completed"
}

main "$@"
