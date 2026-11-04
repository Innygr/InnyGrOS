#!/usr/bin/env bash
set -Eeuo pipefail
[[ "${EUID}" -ne 0 ]] || { echo "Run as your normal user, not with sudo." >&2; exit 1; }
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${ROOT_DIR}/apps/blacklight-suite/blacklight-desktop-suite"
DESKTOP="${ROOT_DIR}/packaging/blacklight-desktop-suite.desktop"
command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }
python3 -c 'import tkinter' 2>/dev/null || { echo "Tkinter is required. On Kubuntu: sudo apt install python3-tk" >&2; exit 1; }
[[ -s "${APP}" && -s "${DESKTOP}" ]] || { echo "Suite source or launcher is missing." >&2; exit 1; }
mkdir -p "${HOME}/.local/bin" "${HOME}/.local/share/integeros/blacklight-suite" "${HOME}/.local/share/applications"
install -m 0755 "${APP}" "${HOME}/.local/share/integeros/blacklight-suite/blacklight-desktop-suite"
install -m 0755 "${HOME}/.local/share/integeros/blacklight-suite/blacklight-desktop-suite" "${HOME}/.local/bin/blacklight-desktop-suite"
install -m 0644 "${DESKTOP}" "${HOME}/.local/share/applications/blacklight-desktop-suite.desktop"
echo "Installed. Search KDE's application launcher for Blacklight Desktop Suite."
