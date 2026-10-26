#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATER="${ROOT_DIR}/scripts/software-updater.sh"
GUI_UPDATER="${ROOT_DIR}/scripts/software-updater-gui.sh"
bash -n "${GUI_UPDATER}"
grep -q "git pull --ff-only origin main" "${GUI_UPDATER}"
grep -q "Local edits or untracked files" "${GUI_UPDATER}"
bash -n "${UPDATER}"
bash "${UPDATER}" --help >/dev/null
if bash "${UPDATER}" --definitely-invalid >/dev/null 2>&1; then
  echo "Updater accepted an invalid option." >&2
  exit 1
fi
echo "Software updater smoke tests passed."
