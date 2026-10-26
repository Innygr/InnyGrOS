#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WELCOME="${ROOT_DIR}/apps/welcome-center/innygros-welcome"
REPORT="${ROOT_DIR}/scripts/image-viewer-report.sh"
INSTALLER="${ROOT_DIR}/scripts/install-apps.sh"

bash -n "${WELCOME}" "${REPORT}" "${INSTALLER}"
grep -q '"images" "Open image viewer (Gwenview)"' "${WELCOME}"
grep -q 'images) open_app gwenview "Gwenview image viewer" ;;' "${WELCOME}"
grep -q '"image-report" "Image viewer compatibility report (read-only)"' "${WELCOME}"
grep -q 'image-report) run_helper "Image viewer report" image-viewer-report.sh --gui ;;' "${WELCOME}"
grep -q 'This is an inventory, not a format-support certification' "${REPORT}"
grep -q 'docs/IMAGE-VIEWER-RESULTS.md' "${REPORT}"
grep -q 'image-viewer|Image viewer plus available format plugins' "${INSTALLER}"
grep -q 'gwenview kimageformat-plugins qt6-image-formats-plugins' "${INSTALLER}"

# Listing the optional group is read-only and must not require a graphical session.
listing="$(bash "${INSTALLER}" --list --group image-viewer)"
grep -q '\[image-viewer\]' <<<"${listing}"
grep -q 'Image viewer plus available format plugins' <<<"${listing}"

echo "Image viewer integration smoke tests passed."
