#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo."
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${HOME}/.local/share/innygros"
BIN_DIR="${HOME}/.local/bin"
APPS_DIR="${HOME}/.local/share/applications"

for required in apps/welcome-center/innygros-welcome scripts/apply-theme.sh scripts/apply-wallpaper.sh scripts/apply-terminal-profile.sh scripts/game-readiness.sh scripts/performance.sh scripts/performance-benchmark.sh scripts/desktop-profile.sh scripts/hardware-check.sh scripts/compare-reports.sh config/themes/InnyGrOS.colors config/konsole/InnyGrOS.profile config/konsole/InnyGrOS.colorscheme branding/wallpaper/innygros-desktop.svg; do
  if [[ ! -f "${ROOT_DIR}/${required}" ]]; then
    echo "Required project file missing: ${required}"
    exit 1
  fi
done

mkdir -p "${DATA_DIR}/apps/welcome-center" "${DATA_DIR}/scripts" "${DATA_DIR}/config/themes" "${DATA_DIR}/config/konsole" "${DATA_DIR}/branding/wallpaper" "${BIN_DIR}" "${APPS_DIR}"
install -m 0755 "${ROOT_DIR}/apps/welcome-center/innygros-welcome" "${DATA_DIR}/apps/welcome-center/innygros-welcome"
install -m 0755 "${ROOT_DIR}/scripts/apply-theme.sh" "${DATA_DIR}/scripts/apply-theme.sh"
install -m 0755 "${ROOT_DIR}/scripts/apply-wallpaper.sh" "${DATA_DIR}/scripts/apply-wallpaper.sh"
install -m 0755 "${ROOT_DIR}/scripts/apply-terminal-profile.sh" "${DATA_DIR}/scripts/apply-terminal-profile.sh"
install -m 0755 "${ROOT_DIR}/scripts/game-readiness.sh" "${DATA_DIR}/scripts/game-readiness.sh"
install -m 0755 "${ROOT_DIR}/scripts/performance.sh" "${DATA_DIR}/scripts/performance.sh"
install -m 0755 "${ROOT_DIR}/scripts/performance-benchmark.sh" "${DATA_DIR}/scripts/performance-benchmark.sh"
install -m 0755 "${ROOT_DIR}/scripts/desktop-profile.sh" "${DATA_DIR}/scripts/desktop-profile.sh"
install -m 0755 "${ROOT_DIR}/scripts/hardware-check.sh" "${DATA_DIR}/scripts/hardware-check.sh"
install -m 0755 "${ROOT_DIR}/scripts/compare-reports.sh" "${DATA_DIR}/scripts/compare-reports.sh"
install -m 0644 "${ROOT_DIR}/config/themes/InnyGrOS.colors" "${DATA_DIR}/config/themes/InnyGrOS.colors"
install -m 0644 "${ROOT_DIR}/config/konsole/InnyGrOS.profile" "${DATA_DIR}/config/konsole/InnyGrOS.profile"
install -m 0644 "${ROOT_DIR}/config/konsole/InnyGrOS.colorscheme" "${DATA_DIR}/config/konsole/InnyGrOS.colorscheme"
install -m 0644 "${ROOT_DIR}/branding/wallpaper/innygros-desktop.svg" "${DATA_DIR}/branding/wallpaper/innygros-desktop.svg"
install -m 0755 "${DATA_DIR}/apps/welcome-center/innygros-welcome" "${BIN_DIR}/innygros-welcome"

cat > "${APPS_DIR}/innygros-welcome.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=InnyGrOS Welcome Center
GenericName=Desktop control center
Comment=Quick access to InnyGrOS settings and diagnostics
Exec=${BIN_DIR}/innygros-welcome
Icon=preferences-desktop-theme
Terminal=false
Categories=Settings;System;
StartupNotify=true
EOF
chmod 0644 "${APPS_DIR}/innygros-welcome.desktop"

echo "Installed InnyGrOS Welcome Center."
echo "Find it in the application launcher by searching for 'InnyGrOS'."
echo "If ~/.local/bin is not on PATH, the desktop launcher still uses the full path."
