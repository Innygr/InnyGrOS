#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="${ROOT_DIR}/config/themes/InnyGrOS.colors"
TARGET_DIR="${HOME}/.local/share/color-schemes"
TARGET_FILE="${TARGET_DIR}/InnyGrOS.colors"
[[ -f "${SOURCE_FILE}" ]] || { echo "Missing color scheme: ${SOURCE_FILE}"; exit 1; }
mkdir -p "${TARGET_DIR}"
if [[ -f "${TARGET_FILE}" ]]; then
  backup="${TARGET_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p "${TARGET_FILE}" "${backup}"
  echo "Existing file backed up to ${backup}"
fi
install -m 0644 "${SOURCE_FILE}" "${TARGET_FILE}"
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
  plasma-apply-colorscheme InnyGrOS || echo "Installed; choose InnyGrOS under System Settings > Colors & Themes > Colors."
else
  echo "Installed; choose InnyGrOS under System Settings > Colors & Themes > Colors."
fi
