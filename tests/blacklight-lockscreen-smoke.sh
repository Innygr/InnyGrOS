#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
helper="${ROOT_DIR}/scripts/blacklight-lockscreen.sh"

bash -n "${helper}"
bash -n "${ROOT_DIR}/tests/blacklight-lockscreen-smoke.sh"
grep -q 'WallpaperFader' "${helper}"
grep -q 'visible: false' "${helper}"
grep -q 'NumberAnimation on y' "${helper}"
grep -q 'authenticator' "${helper}"
grep -q 'cp -a "$STATE_DIR/$BACKUP_NAME" "$QML_FILE"' "${helper}"
grep -q 'restore)' "${helper}"
grep -q 'INNYGROS BLACKLIGHT MATRIX OVERLAY' "${helper}"
echo "Blacklight lock-screen smoke checks passed."
