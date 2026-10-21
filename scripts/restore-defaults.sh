#!/usr/bin/env bash
set -Eeuo pipefail
TARGET_FILE="${HOME}/.local/share/color-schemes/InnyGrOS.colors"
echo "This removes only the InnyGrOS color-scheme file from your user profile."
[[ -f "${TARGET_FILE}" ]] || { echo "No file found; nothing to do."; exit 0; }
read -r -p "Remove ${TARGET_FILE}? [y/N] " answer
case "${answer,,}" in
  y|yes) rm -- "${TARGET_FILE}"; echo "Removed. Choose another scheme in System Settings if it was active." ;;
  *) echo "Cancelled." ;;
esac
