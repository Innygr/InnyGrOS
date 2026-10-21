#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo."
  exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "This starter targets Kubuntu/Ubuntu systems using APT."
  exit 1
fi

echo
echo "InnyGrOS 0.1 — Desktop Edition"
echo "This offers optional developer tools and the InnyGrOS color scheme."
echo "It will not repartition disks, change boot settings, or replace system files."
read -r -p "Continue? [y/N] " answer
case "${answer,,}" in y|yes) ;; *) echo "Cancelled."; exit 0 ;; esac

read -r -p "Install optional developer tools? [y/N] " apps
if [[ "${apps,,}" == "y" || "${apps,,}" == "yes" ]]; then
  "${ROOT_DIR}/scripts/install-apps.sh"
fi

read -r -p "Install and apply the InnyGrOS color scheme? [Y/n] " theme
if [[ "${theme,,}" != "n" && "${theme,,}" != "no" ]]; then
  "${ROOT_DIR}/scripts/apply-theme.sh"
fi

echo "Setup steps finished. Some desktop changes may require logging out and back in."
