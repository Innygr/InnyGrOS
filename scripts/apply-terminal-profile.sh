#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_SOURCE="${ROOT_DIR}/config/konsole/InnyGrOS.profile"
SCHEME_SOURCE="${ROOT_DIR}/config/konsole/InnyGrOS.colorscheme"
KONSOLE_DIR="${HOME}/.local/share/konsole"
PROFILE_TARGET="${KONSOLE_DIR}/InnyGrOS.profile"
SCHEME_TARGET="${KONSOLE_DIR}/InnyGrOS.colorscheme"

for source in "${PROFILE_SOURCE}" "${SCHEME_SOURCE}"; do
  if [[ ! -s "${source}" ]]; then
    echo "Required Konsole configuration missing: ${source}" >&2
    exit 1
  fi
done

mkdir -p "${KONSOLE_DIR}"
for target in "${PROFILE_TARGET}" "${SCHEME_TARGET}"; do
  if [[ -f "${target}" ]]; then
    cp -p "${target}" "${target}.backup.$(date +%Y%m%d-%H%M%S)"
  fi
done
install -m 0644 "${PROFILE_SOURCE}" "${PROFILE_TARGET}"
install -m 0644 "${SCHEME_SOURCE}" "${SCHEME_TARGET}"
echo "Installed the InnyGrOS Konsole profile and color scheme in ${KONSOLE_DIR}."

if command -v konsole >/dev/null 2>&1; then
  konsole --profile InnyGrOS >/dev/null 2>&1 &
  echo "Requested a Konsole window using the InnyGrOS profile."
else
  echo "Konsole is not installed. Install it from Discover, then select InnyGrOS in Konsole → Settings → Manage Profiles."
fi
