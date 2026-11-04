#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/integeros/quick-settings"
DESKTOP_DIR="${HOME}/.local/share/applications"

for required in apps/quick-settings/integeros-quick-settings packaging/integeros-quick-settings.desktop; do
  [[ -f "${ROOT_DIR}/${required}" ]] || { echo "Missing required file: ${required}" >&2; exit 1; }
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required. Install it through Discover or APT, then retry." >&2
  exit 1
fi

python3 -c 'import tkinter' 2>/dev/null || {
  echo "Python Tkinter is required. On Kubuntu, install it with: sudo apt install python3-tk" >&2
  exit 1
}

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${DESKTOP_DIR}"
install -m 0755 "${ROOT_DIR}/apps/quick-settings/integeros-quick-settings" "${APP_DIR}/integeros-quick-settings"
install -m 0755 "${APP_DIR}/integeros-quick-settings" "${BIN_DIR}/integeros-quick-settings"
install -m 0644 "${ROOT_DIR}/packaging/integeros-quick-settings.desktop" "${DESKTOP_DIR}/integeros-quick-settings.desktop"
echo "IntegerOS Quick Settings installed. Search for it in the application launcher."
echo "Optional controls use nmcli, bluetoothctl, pactl, and powerprofilesctl when available."
