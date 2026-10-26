#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/apply-wallpaper.sh"
WELCOME="${ROOT_DIR}/apps/welcome-center/innygros-welcome"

bash -n "${SCRIPT}"
grep -q 'apply-wallpaper.sh --choose' "${WELCOME}"
grep -q 'plasma-apply-wallpaperimage' "${SCRIPT}"
# Ensure the graphical filter exposes the same less-common extensions accepted by validation.
for extension in jpe svgz j2k pbm pgm ppm pnm; do
  grep -Fq -- "*.${extension}" "${SCRIPT}" || {
    echo "Wallpaper chooser filter is missing .${extension}." >&2
    exit 1
  }
done

tmp="$(mktemp -d)"
trap 'rm -rf -- "${tmp}"' EXIT
export HOME="${tmp}/home"
mkdir -p "${HOME}" "${tmp}/fixtures"
printf 'not a real image; extension validation only\n' > "${tmp}/fixtures/sample.webp"
printf 'not an image\n' > "${tmp}/fixtures/readme.txt"

# The desktop apply command is absent on CI, so a recognized file should reach
# the graceful manual-application message and exit successfully.
bash "${SCRIPT}" --file "${tmp}/fixtures/sample.webp" > "${tmp}/valid.out"
grep -q 'current wallpaper plugin cannot display' "${tmp}/valid.out"

if bash "${SCRIPT}" --file "${tmp}/fixtures/readme.txt" > "${tmp}/invalid.out" 2>&1; then
  echo "Wallpaper helper accepted a non-image extension." >&2
  exit 1
fi
grep -q "extension is not in the image viewer's planned compatibility list" "${tmp}/invalid.out"

echo "Wallpaper chooser smoke tests passed."
