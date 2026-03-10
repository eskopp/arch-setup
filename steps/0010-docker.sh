#!/usr/bin/env bash
set -euo pipefail

# Install Docker packages on Arch Linux,
# ensure the docker group exists,
# add the current user to that group,
# and enable the Docker service.

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

echo "Installing Docker packages..."
sudo pacman -S --needed --noconfirm \
  docker \
  docker-compose \
  docker-buildx

echo "Ensuring docker group exists..."
if ! getent group docker >/dev/null 2>&1; then
  sudo groupadd docker
fi

echo "Adding user '${TARGET_USER}' to docker group..."
if id -nG "${TARGET_USER}" | grep -qw docker; then
  echo "User '${TARGET_USER}' is already in the docker group."
else
  sudo usermod -aG docker "${TARGET_USER}"
fi

echo "Enabling Docker service..."
sudo systemctl enable --now docker.service

echo "Verifying installation..."
docker --version || true
docker compose version || true
docker buildx version || true

echo
echo "Done."
echo "You need to log out and back in for the new group membership to apply."
echo "After that, test Docker with:"
echo "  docker run hello-world"
