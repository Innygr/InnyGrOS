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
  status   Show availability and whether secure idle locking is enabled
  enable   Enable KDE's secure lock screen after 5 idle minutes (X11 only)
  disable  Disable automatic locking; leave the manual visual launcher installed
  run      Launch the fullscreen visual now (not a security lock)
USAGE
}

status() {
  echo "InnyGrOS Blacklight Matrix screensaver"
  [[ -f "${APP}" ]] && echo "Visual: available" || echo "Visual: missing"
  command -v python3 >/dev/null 2>&1 && echo "Python 3: available" || echo "Python 3: missing"
  if command -v python3 >/dev/null 2>&1 && python3 -c "import tkinter" >/dev/null 2>&1; then
    echo "Tkinter: available"
  else
    echo "Tkinter: missing (install with: sudo apt install python3-tk)"
  fi
  command -v xautolock >/dev/null 2>&1 && echo "xautolock: available" || echo "xautolock: not installed"
  echo "Session type: ${XDG_SESSION_TYPE:-unknown}"
  [[ -f "${AUTOSTART_FILE}" ]] && echo "Secure idle lock: enabled" || echo "Secure idle lock: disabled"
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
    echo "This xautolock helper is for X11 only; it will not configure Wayland idle locking." >&2
    echo "On Wayland, use System Settings > Security & Privacy > Screen Locking to enable automatic locking." >&2
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
Name=InnyGrOS Blacklight secure idle lock
Comment=Lock the KDE session after five minutes of inactivity (X11)
Exec=xautolock -time 5 -locker "loginctl lock-session" -detectsleep
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
  chmod 0644 "${AUTOSTART_FILE}"
  echo "Secure idle locking enabled for X11 after 5 minutes."
  echo "This invokes KDE's native lock screen; it does not substitute a fake fullscreen window for authentication."
  echo "Log out and back in for the idle watcher to start."
}

disable_idle() {
  rm -f "${AUTOSTART_FILE}"
  echo "Idle activation disabled. The manual application launcher is left in place."
}

check_tkinter() {
  command -v python3 >/dev/null 2>&1 || {
    echo "Python 3 is required. Install it with: sudo apt install python3" >&2
    exit 1
  }
  python3 -c "import tkinter" >/dev/null 2>&1 || {
    echo "Python Tkinter is missing. On Kubuntu/Ubuntu, install it with:" >&2
    echo "  sudo apt update && sudo apt install python3-tk" >&2
    exit 1
  }
}

case "${1:-}" in
  status) status ;;
  enable) enable_idle ;;
  disable) disable_idle ;;
  run) check_tkinter; exec python3 "${APP}" ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
