#!/usr/bin/env bash
# Experimental, reversible Plasma 6 lock-screen Matrix overlay.
set -Eeuo pipefail

QML_CANDIDATES=(
  /usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
  /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/LockScreenUi.qml
)
STATE_DIR=/var/lib/innygros/blacklight-lockscreen
BACKUP_NAME=LockScreenUi.qml.original
AUTH_BACKUP_NAME=MainBlock.qml.original
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PATCHER="${SCRIPT_DIR}/lib/blacklight-lockscreen-patch.py"
OVERLAY_MARKER='INNYGROS BLACKLIGHT MATRIX OVERLAY'
AUTH_MARKER='INNYGROS BLACKLIGHT AUTH FIELD STYLE'

usage() {
  cat <<'USAGE'
Usage: sudo bash scripts/blacklight-lockscreen.sh status | install | restore
  status   Show detected Plasma lock-screen file and patch state
  install  Back up both QML files; add Matrix rain and style native authentication controls
  restore  Restore the exact original QML files from the saved backups

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
      if [[ -f "$STATE_DIR/$BACKUP_NAME" ]]; then echo "Lock-screen backup: available"; else echo "Lock-screen backup: absent"; fi
      if [[ -f "$STATE_DIR/$AUTH_BACKUP_NAME" ]]; then echo "Authentication-field backup: available"; else echo "Authentication-field backup: absent"; fi
      local mainblock
      mainblock="$(dirname -- "$candidate")/MainBlock.qml"
      if [[ -f "$mainblock" ]] && grep -qF "$AUTH_MARKER" "$mainblock"; then
        echo "Blacklight authentication styling: installed"
      else
        echo "Blacklight authentication styling: not installed"
      fi
      return
    fi
  done
  echo "Plasma lock-screen QML: not found"
  [[ -f "$STATE_DIR/$BACKUP_NAME" ]] && echo "Original backup: available" || echo "Original backup: absent"
}

install_overlay() {
  require_root
  find_qml
  local mainblock_file
  mainblock_file="$(dirname -- "$QML_FILE")/MainBlock.qml"
  if grep -qF "$OVERLAY_MARKER" "$QML_FILE" && [[ -f "$mainblock_file" ]] && grep -qF "$AUTH_MARKER" "$mainblock_file"; then
    echo "Blacklight Matrix overlay and authentication styling are already installed."
    exit 0
  fi
  if [[ -e "$STATE_DIR/$BACKUP_NAME" || -e "$STATE_DIR/$AUTH_BACKUP_NAME" ]]; then
    echo "A Blacklight backup already exists in $STATE_DIR; refusing to overwrite it." >&2
    echo "Inspect the existing patch or use restore first." >&2
    exit 1
  fi
  [[ -f "$mainblock_file" ]] || { echo "Could not find MainBlock.qml beside $QML_FILE" >&2; exit 1; }
  [[ -f "$PATCHER" ]] || { echo "Missing patcher: $PATCHER" >&2; exit 1; }
  command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }

  mkdir -p "$STATE_DIR"
  cp -a "$QML_FILE" "$STATE_DIR/$BACKUP_NAME"
  cp -a "$mainblock_file" "$STATE_DIR/$AUTH_BACKUP_NAME"
  chmod 0644 "$STATE_DIR/$BACKUP_NAME" "$STATE_DIR/$AUTH_BACKUP_NAME"

  if ! python3 "$PATCHER" "$QML_FILE" "$mainblock_file"; then
    cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
    cp -a "$STATE_DIR/$AUTH_BACKUP_NAME" "$mainblock_file"
    rm -f "$STATE_DIR/$BACKUP_NAME" "$STATE_DIR/$AUTH_BACKUP_NAME"
    rmdir "$STATE_DIR" 2>/dev/null || true
    echo "Patch failed; both original QML files were restored." >&2
    exit 1
  fi

  if ! grep -qF "$OVERLAY_MARKER" "$QML_FILE" || ! grep -qF "$AUTH_MARKER" "$mainblock_file"; then
    cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
    cp -a "$STATE_DIR/$AUTH_BACKUP_NAME" "$mainblock_file"
    rm -f "$STATE_DIR/$BACKUP_NAME" "$STATE_DIR/$AUTH_BACKUP_NAME"
    rmdir "$STATE_DIR" 2>/dev/null || true
    echo "Patch verification failed; both original files were restored." >&2
    exit 1
  fi
  echo "Blacklight Matrix animation and authentication-field styling installed."
  echo "Original files saved in $STATE_DIR"
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
  local mainblock_file
  mainblock_file="$(dirname -- "$QML_FILE")/MainBlock.qml"

  # Validate every file we intend to restore before changing either one.
  if ! grep -qF "$OVERLAY_MARKER" "$QML_FILE"; then
    echo "Current lock-screen QML does not contain the InnyGrOS overlay marker; refusing to overwrite it." >&2
    echo "Original backup remains at $STATE_DIR/$BACKUP_NAME" >&2
    exit 1
  fi
  if [[ -f "$STATE_DIR/$AUTH_BACKUP_NAME" ]] && {
    [[ ! -f "$mainblock_file" ]] || ! grep -qF "$AUTH_MARKER" "$mainblock_file"
  }; then
    echo "Authentication QML is not marked as patched; refusing to restore only part of the install." >&2
    echo "Backups remain in $STATE_DIR" >&2
    exit 1
  fi

  cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"
  echo "Restored original Plasma lock-screen QML."
  if [[ -f "$STATE_DIR/$AUTH_BACKUP_NAME" ]]; then
    cp -a "$STATE_DIR/$AUTH_BACKUP_NAME" "$mainblock_file"
    rm -f "$STATE_DIR/$AUTH_BACKUP_NAME"
    echo "Restored original authentication-field QML."
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
