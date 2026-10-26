#!/usr/bin/env bash
# Read-only report about image-viewer availability and installed format plugins.
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this report as your normal user, not root." >&2
  exit 1
fi

gui=0
for arg in "$@"; do
  case "$arg" in
    --gui) gui=1 ;;
    -h|--help) echo "Usage: image-viewer-report.sh [--gui]"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

report="$(mktemp)"
trap 'rm -f -- "${report}"' EXIT
{
  echo "InnyGrOS image viewer compatibility snapshot"
  echo "Generated: $(date '+%F %T %Z')"
  echo
  echo "This is an inventory, not a format-support certification. A package or plugin being present does not prove that a particular image opens or animates correctly."
  echo
  echo "=== Operating system ==="
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    printf 'Distribution: %s\nRelease: %s\n' "${PRETTY_NAME:-unknown}" "${VERSION_ID:-unknown}"
  else
    echo "OS release details unavailable"
  fi
  echo
  echo "=== Viewer ==="
  if command -v gwenview >/dev/null 2>&1; then
    command -v gwenview
    gwenview --version 2>&1 | head -n 3 || true
  else
    echo "Gwenview: not found"
  fi
  echo
  echo "=== Relevant installed packages ==="
  if command -v dpkg-query >/dev/null 2>&1; then
    for package in gwenview kimageformat-plugins qt6-image-formats-plugins qt5-image-formats-plugins libheif1 libwebp7 libavif-bin; do
      if dpkg-query -W -f='${Status} ${Version}\n' "${package}" 2>/dev/null | grep -q '^install ok installed'; then
        dpkg-query -W -f='${binary:Package} ${Version}\n' "${package}" 2>/dev/null || true
      else
        printf '%s: not installed (or package name differs on this release)\n' "${package}"
      fi
    done
  else
    echo "dpkg-query unavailable"
  fi
  echo
  echo "=== Qt image plugin directories ==="
  found=0
  for directory in /usr/lib/*/qt6/plugins/imageformats /usr/lib/*/qt5/plugins/imageformats /usr/lib/qt6/plugins/imageformats /usr/lib/qt5/plugins/imageformats; do
    [[ -d "${directory}" ]] || continue
    found=1
    echo "${directory}"
    find "${directory}" -maxdepth 1 -type f -printf '  %f\n' 2>/dev/null | sort || true
  done
  ((found)) || echo "No common Qt imageformats plugin directory found."
  echo
  echo "=== Suggested manual verification ==="
  echo "Open one fixture per format in Gwenview; verify rendering and, for GIF/WebP/APNG, actual animation playback."
  echo "Check docs/IMAGE-VIEWER-RESULTS.md to record results. This report does not open files or change packages/settings."
} > "${report}" 2>&1

if ((gui)); then
  if ! command -v kdialog >/dev/null 2>&1 || [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    cat "${report}"
    exit 0
  fi
  kdialog --title "InnyGrOS Image Viewer Report" --textbox "${report}" 820 600 >/dev/null 2>&1 || cat "${report}"
else
  cat "${report}"
fi
