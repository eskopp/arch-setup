#!/usr/bin/env bash
set -euo pipefail

# Placeholder for future NixOS support.
# This step intentionally installs nothing.
# It only detects NixOS and prints useful status information.

is_nixos() {
  if [[ -f /etc/NIXOS ]]; then
    return 0
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "nixos" ]] && return 0
  fi

  return 1
}

echo "Checking for NixOS support..."

if ! is_nixos; then
  echo "NixOS was not detected."
  echo "Skipping step 099 without changes."
  exit 0
fi

echo "NixOS detected."

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "System     : ${PRETTY_NAME:-NixOS}"
fi

echo "Marker     : /etc/NIXOS present"
echo

if [[ -f /etc/nixos/configuration.nix ]]; then
  echo "Found      : /etc/nixos/configuration.nix"
else
  echo "Missing    : /etc/nixos/configuration.nix"
fi

if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
  echo "Found      : /etc/nixos/hardware-configuration.nix"
else
  echo "Missing    : /etc/nixos/hardware-configuration.nix"
fi

if command -v nix > /dev/null 2>&1; then
  echo "Tool       : nix available"
else
  echo "Tool       : nix missing"
fi

if command -v nixos-rebuild > /dev/null 2>&1; then
  echo "Tool       : nixos-rebuild available"
else
  echo "Tool       : nixos-rebuild missing"
fi

echo
echo "No packages were installed."
echo "No files were changed."
echo
echo "Future NixOS support could later:"
echo "  - manage /etc/nixos/configuration.nix"
echo "  - add packages declaratively"
echo "  - run nixos-rebuild switch"
