#!/usr/bin/env bash
# Experimental, reversible Plasma 6 lock-screen Matrix overlay.
set -Eeuo pipefail

QML_CANDIDATES=(
  /usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
  /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/LockScreenUi.qml
)
STATE_DIR=/var/lib/innygros/blacklight-lockscreen
BACKUP_NAME=LockScreenUi.qml.original
OVERLAY_MARKER='INNYGROS BLACKLIGHT MATRIX OVERLAY'

usage() {
  cat <<'USAGE'
Usage: sudo bash scripts/blacklight-lockscreen.sh status | install | restore
  status   Show detected Plasma lock-screen file and patch state
  install  Back up and add animated Matrix rain; disable KDE's wallpaper blur/fade
  restore  Restore the exact original QML file from the saved backup

This is experimental and system-wide. Keep a terminal/recovery path available.
It does not replace KDE authentication; the native authenticator remains in use.
USAGE
}

find_qml() {
  local candidate
  for candidate in "${QML_CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then QML_FILE="$candidate"; return 0; fi
  done
  echo "Could not find a supported Plasma lock-screen QML file." >&2
  echo "Expected one of:" >&2
  printf '  %s\n' "${QML_CANDIDATES[@]}" >&2
  exit 1
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Run this action with sudo." >&2
    exit 1
  fi
}

status() {
  local candidate
  for candidate in "${QML_CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "Plasma lock-screen QML: $candidate"
      if grep -qF "$OVERLAY_MARKER" "$candidate"; then
        echo "Blacklight animation: installed"
      else
        echo "Blacklight animation: not installed"
      fi
      [[ -f "$STATE_DIR/$BACKUP_NAME" ]] && echo "Original backup: available" || echo "Original backup: absent"
      return
    fi
  done
  echo "Plasma lock-screen QML: not found"
  [[ -f "$STATE_DIR/$BACKUP_NAME" ]] && echo "Original backup: available" || echo "Original backup: absent"
}

install_overlay() {
  require_root
  find_qml
  if grep -qF "$OVERLAY_MARKER" "$QML_FILE"; then
    echo "Blacklight overlay is already installed in $QML_FILE"
    exit 0
  fi
  if [[ -e "$STATE_DIR/$BACKUP_NAME" ]]; then
    echo "Backup already exists at $STATE_DIR/$BACKUP_NAME; refusing to overwrite it." >&2
    echo "Inspect the existing patch or use restore first." >&2
    exit 1
  fi
  command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }
  mkdir -p "$STATE_DIR"
  cp -a "$QML_FILE" "$STATE_DIR/$BACKUP_NAME"
  chmod 0644 "$STATE_DIR/$BACKUP_NAME"

  if ! python3 - "$QML_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
marker = "INNYGROS BLACKLIGHT MATRIX OVERLAY"
if marker in text:
    raise SystemExit(0)

wallpaper = list(re.finditer(r"(?m)^(\s*)WallpaperFader\s*\{", text))
dropshadow = list(re.finditer(r"(?m)^(\s*)DropShadow\s*\{", text))
if len(wallpaper) != 1 or len(dropshadow) < 1:
    print("Unsupported Plasma QML layout; expected one WallpaperFader and a DropShadow anchor.", file=sys.stderr)
    raise SystemExit(2)
if wallpaper[0].start() > dropshadow[0].start():
    print("Unexpected QML ordering; refusing to patch.", file=sys.stderr)
    raise SystemExit(2)

# Hide only the blur/fade layer. The wallpaper itself and KDE's authentication
# components remain supplied by the original Plasma shell.
start = wallpaper[0].end()
line_end = text.find("\n", start)
if line_end < 0:
    print("Unexpected end of QML file.", file=sys.stderr)
    raise SystemExit(2)
indent = wallpaper[0].group(1) + "    "
text = text[:line_end + 1] + indent + "visible: false // InnyGrOS: keep the lock-screen wallpaper sharp\n" + text[line_end + 1:]

# Place a non-interactive animated overlay between the wallpaper and the
# authentication UI. No password handling or authenticator logic is changed.
overlay = '''
        // INNYGROS BLACKLIGHT MATRIX OVERLAY
        Item {
            id: innygrBlacklightRainOverlay
            anchors.fill: parent
            opacity: 0.24
            enabled: false

            Repeater {
                model: 32
                delegate: Item {
                    property int lane: index
                    width: innygrBlacklightRainOverlay.width / 32
                    height: innygrBlacklightRainOverlay.height
                    x: lane * width

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -height
                        text: "1\\n0\\n1\\n1\\n0\\n0\\n1\\n0\\n1\\n0\\n1\\n0\\n0\\n1\\n0"
                        color: lane % 4 === 0 ? "#aaffc7" : "#39ff83"
                        font.family: "monospace"
                        font.pixelSize: 15
                        lineHeight: 1.15

                        NumberAnimation on y {
                            from: -parent.height * (1 + ((lane * 7) % 3))
                            to: innygrBlacklightRainOverlay.height
                            duration: 4800 + ((lane * 379) % 5200)
                            loops: Animation.Infinite
                        }
                    }
                }
            }
        }

'''
# DropShadow is an established point after WallpaperFader in Plasma 6's
# lock-screen UI. Keep the overlay before the rest of the unlock UI.
updated_dropshadow = list(re.finditer(r"(?m)^\\s*DropShadow\\s*\\{", text))
if not updated_dropshadow:
    print("DropShadow anchor disappeared after wallpaper edit; refusing to patch.", file=sys.stderr)
    raise SystemExit(2)
anchor = updated_dropshadow[0].start()
text = text[:anchor] + overlay + text[anchor:]
path.write_text(text)
PY
  then
    cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
    rm -f "$STATE_DIR/$BACKUP_NAME"
    rmdir "$STATE_DIR" 2>/dev/null || true
    echo "Patch failed; the original lock-screen file was restored." >&2
    exit 1
  fi

  if ! grep -qF "$OVERLAY_MARKER" "$QML_FILE"; then
    cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
    rm -f "$STATE_DIR/$BACKUP_NAME"
    rmdir "$STATE_DIR" 2>/dev/null || true
    echo "Patch verification failed; original file restored." >&2
    exit 1
  fi
  echo "Blacklight Matrix animation installed in the native Plasma lock screen."
  echo "Original saved at $STATE_DIR/$BACKUP_NAME"
  echo "Lock with Meta+L to test. If anything looks wrong, run: sudo bash scripts/blacklight-lockscreen.sh restore"
  echo "The change takes effect when the lock screen is next loaded; no session restart was performed."
}

restore_overlay() {
  require_root
  [[ -f "$STATE_DIR/$BACKUP_NAME" ]] || {
    echo "No original lock-screen backup found at $STATE_DIR/$BACKUP_NAME" >&2
    exit 1
  }
  find_qml
  if grep -qF "$OVERLAY_MARKER" "$QML_FILE"; then
    cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
    echo "Restored original Plasma lock-screen QML."
  else
    echo "Current QML does not contain the InnyGrOS overlay marker; refusing to overwrite it." >&2
    echo "Original backup remains at $STATE_DIR/$BACKUP_NAME" >&2
    exit 1
  fi
  rm -f "$STATE_DIR/$BACKUP_NAME"
  rmdir "$STATE_DIR" 2>/dev/null || true
}

case "${1:-}" in
  status) status ;;
  install) install_overlay ;;
  restore) restore_overlay ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
