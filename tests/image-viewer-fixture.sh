#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WELCOME="${ROOT_DIR}/apps/welcome-center/innygros-welcome"
REPORT="${ROOT_DIR}/scripts/image-viewer-report.sh"
INSTALLER="${ROOT_DIR}/scripts/install-apps.sh"
WELCOME_INSTALLER="${ROOT_DIR}/scripts/install-welcome-center.sh"

bash -n "${WELCOME}" "${REPORT}" "${INSTALLER}" "${WELCOME_INSTALLER}"
grep -q '"images" "Open image viewer (Gwenview)"' "${WELCOME}"
grep -q 'images) open_app gwenview "Gwenview image viewer" ;;' "${WELCOME}"
grep -q '"image-report" "Image viewer compatibility report (read-only)"' "${WELCOME}"
grep -q 'image-report) run_helper "Image viewer report" image-viewer-report.sh --gui ;;' "${WELCOME}"
grep -q 'scripts/image-viewer-report.sh' "${WELCOME_INSTALLER}"
grep -q 'install -m 0755 "${ROOT_DIR}/scripts/image-viewer-report.sh" "${DATA_DIR}/scripts/image-viewer-report.sh"' "${WELCOME_INSTALLER}"
grep -q 'This is an inventory, not a format-support certification' "${REPORT}"
grep -q 'docs/IMAGE-VIEWER-RESULTS.md' "${REPORT}"

# Exercise the read-only report itself, not only its source text.
report_output="$(bash "${REPORT}")"
grep -q 'InnyGrOS image viewer compatibility snapshot' <<<"${report_output}"
grep -q 'This is an inventory, not a format-support certification' <<<"${report_output}"
grep -q 'does not open files or change packages/settings' <<<"${report_output}"
help_output="$(bash "${REPORT}" --help)"
grep -q 'Usage: image-viewer-report.sh \[--gui\]' <<<"${help_output}"
if bash "${REPORT}" --not-a-real-option >/dev/null 2>&1; then
  echo "Image viewer report accepted an unknown option." >&2
  exit 1
fi
grep -q 'image-viewer|Image viewer plus available format plugins' "${INSTALLER}"
grep -q 'gwenview kimageformat-plugins qt6-image-formats-plugins' "${INSTALLER}"

# Listing the optional group is read-only and must not require a graphical session.
listing="$(bash "${INSTALLER}" --list --group image-viewer)"
grep -q '\[image-viewer\]' <<<"${listing}"
grep -q 'Image viewer plus available format plugins' <<<"${listing}"

echo "Image viewer integration smoke tests passed."
