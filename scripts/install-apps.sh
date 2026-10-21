#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${EUID}" -eq 0 ]]; then echo "Run as your normal user; do not use sudo for the whole script."; exit 1; fi
command -v apt-get >/dev/null 2>&1 || { echo "APT not found; this script targets Kubuntu/Ubuntu."; exit 1; }

PACKAGES=(
  git curl wget build-essential cmake ninja-build pkg-config clang gdb
  python3 python3-venv python3-pip pipx nodejs npm sqlitebrowser
  kate dolphin konsole plasma-discover plasma-systemmonitor fonts-firacode
)
echo "Packages requested:"
printf '  - %s\n' "${PACKAGES[@]}"
read -r -p "Install these packages using APT? [y/N] " answer
case "${answer,,}" in y|yes) ;; *) echo "Cancelled."; exit 0 ;; esac
sudo apt-get update
sudo apt-get install --no-install-recommends "${PACKAGES[@]}"
echo "Package installation finished. Availability can vary by Kubuntu release."
