#!/usr/bin/env bash
# Optional X11 idle activation for the Blacklight Matrix visual.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${ROOT_DIR}/apps/blacklight-screensaver/blacklight-matrix.py"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
AUTOSTART_FILE="${AUTOSTART_DIR}/innygros-blacklight-screensaver.desktop"
LAUNCHER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LAUNCHER_FILE="${LAUNCHER_DIR}/innygros-blacklight-screensaver.desktop"
WALLPAPER_SOURCE="${ROOT_DIR}/branding/lockscreen/blacklight-matrix.svg"
WALLPAPER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
WALLPAPER_DEST="${WALLPAPER_DIR}/InnyGrOS-Blacklight-Matrix.svg"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/innygros-lockscreen"
CONFIG_NAME="kscreenlockerrc"

usage() {
  cat <<'USAGE'
Usage: bash scripts/blacklight-screensaver.sh status | enable | disable | lockscreen | restore-wallpaper | run
  status            Show dependencies and secure idle-lock status
  enable            Enable KDE's secure lock screen after 5 idle minutes (X11 only)
  disable           Disable automatic locking; leave the manual visual launcher installed
  lockscreen        Set the Blacklight Matrix wallpaper on KDE's native lock screen
  restore-wallpaper Restore the previous KDE lock-screen wallpaper setting
  run               Launch the fullscreen visual now (not a security lock)
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
  [[ -f "${WALLPAPER_DEST}" ]] && echo "Blacklight lock wallpaper: installed" || echo "Blacklight lock wallpaper: not installed"
  echo "Manual visual launcher: ${LAUNCHER_FILE}"
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
  [[ "${XDG_SESSION_TYPE:-}" == "x11" ]] || {
    echo "This xautolock helper requires an X11 Plasma session (detected: ${XDG_SESSION_TYPE:-unknown})." >&2
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
  echo "Automatic idle locking disabled. The manual application launcher is left in place."
}

find_kwriteconfig() {
  if command -v kwriteconfig6 >/dev/null 2>&1; then
    KWRITE="$(command -v kwriteconfig6)"
    KREAD="$(command -v kreadconfig6 || true)"
  elif command -v kwriteconfig5 >/dev/null 2>&1; then
    KWRITE="$(command -v kwriteconfig5)"
    KREAD="$(command -v kreadconfig5 || true)"
  else
    echo "KDE kwriteconfig tool not found; run this from a Plasma desktop with KDE config tools installed." >&2
    exit 1
  fi
}

read_lock_key() {
  local key="$1"
  if [[ -n "${KREAD}" ]]; then
    "${KREAD}" --file "${CONFIG_NAME}" --group Greeter --group Wallpaper --group org.kde.image --group General --key "${key}" 2>/dev/null || true
  else
    echo ""
  fi
}

write_lock_key() {
  local key="$1" value="$2"
  "${KWRITE}" --file "${CONFIG_NAME}" --group Greeter --group Wallpaper --group org.kde.image --group General --key "${key}" "${value}"
}

restore_lock_key() {
  local key="$1" value="$2"
  if [[ -n "${value}" ]]; then
    write_lock_key "${key}" "${value}"
  else
    "${KWRITE}" --file "${CONFIG_NAME}" --group Greeter --group Wallpaper --group org.kde.image --group General --key "${key}" --delete
  fi
}

lockscreen_wallpaper() {
  [[ -f "${WALLPAPER_SOURCE}" ]] || { echo "Wallpaper source missing: ${WALLPAPER_SOURCE}" >&2; exit 1; }
  find_kwriteconfig
  if [[ -e "${STATE_DIR}/managed" ]]; then
    echo "A Blacklight lock-screen backup already exists at ${STATE_DIR}; refusing to overwrite it." >&2
    echo "Use 'restore-wallpaper' before running this command again." >&2
    exit 1
  fi
  if [[ -e "${WALLPAPER_DEST}" ]]; then
    echo "Wallpaper destination already exists: ${WALLPAPER_DEST}" >&2
    echo "Refusing to overwrite a file that may belong to you." >&2
    exit 1
  fi
  mkdir -p "${STATE_DIR}" "${WALLPAPER_DIR}"
  printf '%s' "$(read_lock_key Image)" > "${STATE_DIR}/previous-image"
  printf '%s' "$(read_lock_key PreviewImage)" > "${STATE_DIR}/previous-preview"
  if [[ -n "${KREAD}" ]]; then
    "${KREAD}" --file "${CONFIG_NAME}" --group Greeter --key WallpaperPlugin > "${STATE_DIR}/previous-plugin" 2>/dev/null || true
  else
    : > "${STATE_DIR}/previous-plugin"
  fi
  : > "${STATE_DIR}/managed"
  install -m 0644 "${WALLPAPER_SOURCE}" "${WALLPAPER_DEST}"
  "${KWRITE}" --file "${CONFIG_NAME}" --group Greeter --key WallpaperPlugin org.kde.image
  write_lock_key Image "file://${WALLPAPER_DEST}"
  write_lock_key PreviewImage "file://${WALLPAPER_DEST}"
  echo "Blacklight Matrix wallpaper selected for KDE's native lock screen."
  echo "Authentication remains handled by KDE; this does not replace the lock screen with an unsecure window."
  echo "Restore the previous wallpaper with: bash scripts/blacklight-screensaver.sh restore-wallpaper"
}

restore_wallpaper() {
  [[ -f "${STATE_DIR}/managed" ]] || { echo "No saved Blacklight wallpaper backup was found." >&2; exit 1; }
  find_kwriteconfig
  restore_lock_key Image "$(cat "${STATE_DIR}/previous-image")"
  restore_lock_key PreviewImage "$(cat "${STATE_DIR}/previous-preview")"
  old_plugin="$(cat "${STATE_DIR}/previous-plugin")"
  if [[ -n "${old_plugin}" ]]; then
    "${KWRITE}" --file "${CONFIG_NAME}" --group Greeter --key WallpaperPlugin "${old_plugin}"
  else
    "${KWRITE}" --file "${CONFIG_NAME}" --group Greeter --key WallpaperPlugin --delete
  fi
  rm -rf -- "${STATE_DIR}"
  rm -f -- "${WALLPAPER_DEST}"
  echo "Previous KDE lock-screen wallpaper setting restored."
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
  lockscreen) lockscreen_wallpaper ;;
  restore-wallpaper) restore_wallpaper ;;
  run) check_tkinter; exec python3 "${APP}" ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
