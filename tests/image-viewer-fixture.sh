#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WELCOME="${ROOT_DIR}/apps/welcome-center/innygros-welcome"
INSTALLER="${ROOT_DIR}/scripts/install-apps.sh"

bash -n "${WELCOME}" "${INSTALLER}"
grep -q '"images" "Open image viewer (Gwenview)"' "${WELCOME}"
grep -q 'images) open_app gwenview "Gwenview image viewer" ;;' "${WELCOME}"
grep -q 'image-viewer|Image viewer plus available format plugins' "${INSTALLER}"
grep -q 'gwenview kimageformat-plugins qt6-image-formats-plugins' "${INSTALLER}"

# Listing the optional group is read-only and must not require a graphical session.
listing="$(bash "${INSTALLER}" --list --group image-viewer)"
grep -q '\[image-viewer\]' <<<"${listing}"
grep -q 'Image viewer plus available format plugins' <<<"${listing}"

echo "Image viewer integration smoke tests passed."
