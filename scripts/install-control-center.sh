#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this installer as your normal user, not with sudo." >&2
  exit 1
fi
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${HOME}/.local/share/innygros"
INT_DIR="${HOME}/.local/share/integeros"
BIN_DIR="${HOME}/.local/bin"
APPS_DIR="${HOME}/.local/share/applications"
for required in apps/control-center/integeros-control-center scripts/install-welcome-center.sh; do
  [[ -f "${ROOT_DIR}/${required}" ]] || { echo "Missing required file: ${required}" >&2; exit 1; }
done
bash "${ROOT_DIR}/scripts/install-welcome-center.sh"
mkdir -p "${INT_DIR}/control-center" "${INT_DIR}/personalization" "${INT_DIR}/quick-settings" "${INT_DIR}/theme-studio" "${INT_DIR}/blacklight-suite" "${INT_DIR}/blacklight-control" "${BIN_DIR}" "${APPS_DIR}"
install -m 0755 "${ROOT_DIR}/apps/control-center/integeros-control-center" "${INT_DIR}/control-center/integeros-control-center"
install -m 0755 "${INT_DIR}/control-center/integeros-control-center" "${BIN_DIR}/integeros-control-center"
install -m 0644 "${ROOT_DIR}/apps/integeros-wallpaper-studio.py" "${INT_DIR}/personalization/integeros-wallpaper-studio.py"
install -m 0755 "${ROOT_DIR}/apps/theme-studio/integeros-theme-studio" "${INT_DIR}/theme-studio/integeros-theme-studio"
install -m 0755 "${ROOT_DIR}/apps/quick-settings/integeros-quick-settings" "${INT_DIR}/quick-settings/integeros-quick-settings"
install -m 0755 "${ROOT_DIR}/apps/blacklight-suite/blacklight-desktop-suite" "${INT_DIR}/blacklight-suite/blacklight-desktop-suite"
install -m 0755 "${ROOT_DIR}/apps/blacklight-control/blacklight-control" "${INT_DIR}/blacklight-control/blacklight-control"
cat > "${APPS_DIR}/integeros-control-center.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=IntegerOS Control Center
GenericName=System and desktop control center
Comment=Welcome, system maintenance, personalization and Blacklight tools
Exec=${BIN_DIR}/integeros-control-center
Icon=innygros
Terminal=false
Categories=Settings;System;
StartupNotify=true
EOF
chmod 0644 "${APPS_DIR}/integeros-control-center.desktop"
echo "IntegerOS Control Center installed."
echo "Search the application launcher for 'IntegerOS Control Center'."
echo "The former applications remain installed as components; use this hub as the main entry point."
