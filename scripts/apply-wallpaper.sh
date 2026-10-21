#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT_DIR}/branding/wallpaper/innygros-desktop.svg"
TARGET_DIR="${HOME}/.local/share/wallpapers"
TARGET="${TARGET_DIR}/InnyGrOS-Desktop.svg"

if [[ ! -f "${SOURCE}" ]]; then
  echo "Wallpaper asset not found: ${SOURCE}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"
install -m 0644 "${SOURCE}" "${TARGET}"
echo "Installed wallpaper to: ${TARGET}"

if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
  if plasma-apply-wallpaperimage "${TARGET}"; then
    echo "InnyGrOS wallpaper applied."
    exit 0
  fi
fi

if command -v kdialog >/dev/null 2>&1; then
  kdialog --title "InnyGrOS Wallpaper" --msgbox "Wallpaper installed, but this Plasma version did not expose the automatic wallpaper command.\n\nOpen System Settings → Wallpaper and select:\n${TARGET}"
else
  echo "Open System Settings → Wallpaper and select: ${TARGET}"
fi
