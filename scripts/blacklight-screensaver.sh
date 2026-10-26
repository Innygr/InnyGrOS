#!/usr/bin/env bash
# Optional X11 idle activation for the Blacklight Matrix visual.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${ROOT_DIR}/apps/blacklight-screensaver/blacklight-matrix.py"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
AUTOSTART_FILE="${AUTOSTART_DIR}/innygros-blacklight-screensaver.desktop"
LAUNCHER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LAUNCHER_FILE="${LAUNCHER_DIR}/innygros-blacklight-screensaver.desktop"

usage() {
  cat <<'USAGE'
Usage: bash scripts/blacklight-screensaver.sh status | enable | disable | run
  status   Show availability and whether idle activation is enabled
  enable   Enable automatic activation after 5 idle minutes (X11 only)
  disable  Disable automatic activation; leave the manual launcher installed
  run      Launch the fullscreen visual now
USAGE
}

status() {
  echo "InnyGrOS Blacklight Matrix screensaver"
  [[ -f "${APP}" ]] && echo "Visual: available" || echo "Visual: missing"
  command -v python3 >/dev/null 2>&1 && echo "Python 3: available" || echo "Python 3: missing"
  command -v xautolock >/dev/null 2>&1 && echo "xautolock: available" || echo "xautolock: not installed"
  echo "Session type: ${XDG_SESSION_TYPE:-unknown}"
  [[ -f "${AUTOSTART_FILE}" ]] && echo "Idle activation: enabled" || echo "Idle activation: disabled"
  echo "Manual launcher: ${LAUNCHER_FILE}"
}

install_manual_launcher() {
  mkdir -p "${LAUNCHER_DIR}"
  cat > "${LAUNCHER_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=InnyGrOS Blacklight Matrix
Comment=Fullscreen Blacklight Matrix visual
Exec=python3 "${APP}"
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF
  chmod 0644 "${LAUNCHER_FILE}"
}

enable_idle() {
  [[ -f "${APP}" ]] || { echo "Screensaver program missing: ${APP}" >&2; exit 1; }
  [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]] || {
    echo "Automatic idle activation is not enabled by this helper on Wayland." >&2
    echo "The visual still works manually from the application menu; this avoids unreliable idle detection." >&2
    exit 1
  }
  command -v xautolock >/dev/null 2>&1 || {
    echo "xautolock is required for X11 idle detection." >&2
    echo "Install it with: sudo apt install xautolock" >&2
    exit 1
  }
  mkdir -p "${AUTOSTART_DIR}"
  install_manual_launcher
  cat > "${AUTOSTART_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=InnyGrOS Blacklight Matrix idle visual
Comment=Show the Blacklight Matrix visual after five minutes of inactivity (X11)
Exec=xautolock -time 5 -locker "python3 \"${APP}\"" -detectsleep
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
  chmod 0644 "${AUTOSTART_FILE}"
  echo "Idle activation enabled for X11 after 5 minutes."
  echo "This is a visual screensaver, not a security lock. Keep KDE screen locking enabled separately."
  echo "Log out and back in for the idle watcher to start."
}

disable_idle() {
  rm -f "${AUTOSTART_FILE}"
  echo "Idle activation disabled. The manual application launcher is left in place."
}

case "${1:-}" in
  status) status ;;
  enable) enable_idle ;;
  disable) disable_idle ;;
  run) exec python3 "${APP}" ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
