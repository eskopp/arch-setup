#!/usr/bin/env bash
set -Eeuo pipefail

echo "[INFO] 0001-base.sh"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm bash coreutils curl git
