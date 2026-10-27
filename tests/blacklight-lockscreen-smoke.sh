#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
helper="${ROOT_DIR}/scripts/blacklight-lockscreen.sh"
patcher="${ROOT_DIR}/scripts/lib/blacklight-lockscreen-patch.py"

bash -n "${helper}"
bash -n "${ROOT_DIR}/tests/blacklight-lockscreen-smoke.sh"
python3 -m py_compile "${patcher}" "${ROOT_DIR}/tests/blacklight-lockscreen-patcher.py"
grep -q 'WallpaperFader' "${patcher}"
grep -q 'visible: false' "${patcher}"
grep -q 'NumberAnimation on y' "${patcher}"
grep -q 'INNYGROS BLACKLIGHT AUTH FIELD STYLE' "${patcher}"
grep -q 'authenticator' "${helper}"
grep -q 'MainBlock.qml.original' "${helper}"
grep -q 'restore)' "${helper}"
python3 "${ROOT_DIR}/tests/blacklight-lockscreen-patcher.py"
echo "Blacklight lock-screen smoke checks passed."
