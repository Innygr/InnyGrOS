#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATER="${ROOT_DIR}/scripts/software-updater.sh"
bash -n "${UPDATER}"
bash "${UPDATER}" --help >/dev/null
if bash "${UPDATER}" --definitely-invalid >/dev/null 2>&1; then
  echo "Updater accepted an invalid option." >&2
  exit 1
fi
echo "Software updater smoke tests passed."
