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

# Spaces, non-ASCII paths, and uppercase extensions should be handled safely.
mkdir -p "${tmp}/fixtures/Wallpapers été"
printf 'placeholder\n' > "${tmp}/fixtures/Wallpapers été/TEST.WEBP"
bash "${SCRIPT}" --file "${tmp}/fixtures/Wallpapers été/TEST.WEBP" > "${tmp}/unicode.out"
grep -q 'current wallpaper plugin cannot display' "${tmp}/unicode.out"

# Stub Plasma's apply command to verify the default wallpaper is copied into
# the user's home and the exact resulting path is passed without splitting.
mkdir -p "${tmp}/bin"
cat > "${tmp}/bin/plasma-apply-wallpaperimage" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$1" > "${WALLPAPER_CAPTURE}"
STUB
chmod +x "${tmp}/bin/plasma-apply-wallpaperimage"
export WALLPAPER_CAPTURE="${tmp}/applied-path.txt"
export PATH="${tmp}/bin:${PATH}"
bash "${SCRIPT}" --default > "${tmp}/default.out"
expected="${HOME}/.local/share/wallpapers/InnyGrOS-Desktop.svg"
[[ -r "${expected}" ]] || { echo "Default wallpaper was not installed." >&2; exit 1; }
[[ "$(cat "${WALLPAPER_CAPTURE}")" == "${expected}" ]] || {
  echo "Default wallpaper path was not passed intact to Plasma." >&2
  exit 1
}

echo "Wallpaper chooser smoke tests passed."
