#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${HOME}/.local/share/integeros/personalization"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"

for required in apps/personalization-center/integeros-personalization-center apps/integeros-wallpaper-studio.py packaging/integeros-personalization-center.desktop; do
  [[ -f "${ROOT_DIR}/${required}" ]] || { echo "Missing required file: ${required}" >&2; exit 1; }
done

mkdir -p "${APP_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}"
install -m 0755 "${ROOT_DIR}/apps/personalization-center/integeros-personalization-center" "${APP_DIR}/integeros-personalization-center"
install -m 0644 "${ROOT_DIR}/apps/integeros-wallpaper-studio.py" "${APP_DIR}/integeros-wallpaper-studio.py"
install -m 0755 "${APP_DIR}/integeros-personalization-center" "${BIN_DIR}/integeros-personalization-center"
install -m 0644 "${ROOT_DIR}/packaging/integeros-personalization-center.desktop" "${DESKTOP_DIR}/integeros-personalization-center.desktop"

echo "IntegerOS Personalization Center installed."
echo "Search for 'IntegerOS Personalization Center' in the application launcher."
