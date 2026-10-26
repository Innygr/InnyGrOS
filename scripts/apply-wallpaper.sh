#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_SOURCE="${ROOT_DIR}/branding/wallpaper/innygros-desktop.svg"
TARGET_DIR="${HOME}/.local/share/wallpapers"
TARGET="${TARGET_DIR}/InnyGrOS-Desktop.svg"

usage() {
  cat <<'EOF'
Usage: apply-wallpaper.sh [--choose | --file PATH | --default]

  --choose     Pick an image using a graphical file chooser (default)
  --file PATH  Use a specific image file
  --default    Install and apply the built-in InnyGrOS wallpaper
EOF
}

mode=choose
selected_file=""
while (($#)); do
  case "$1" in
    --choose) mode=choose ;;
    --default) mode=default ;;
    --file) mode="file"; selected_file="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Keep this aligned with the broad image-viewer format goals. Actual wallpaper
# decoding is controlled by the active Plasma wallpaper plugin, not Gwenview.
is_candidate_image() {
  case "${1,,}" in
    *.jpg|*.jpeg|*.jpe|*.png|*.gif|*.webp|*.apng|*.bmp|*.tif|*.tiff|*.svg|*.svgz|*.avif|*.heic|*.heif|*.jxl|*.jp2|*.j2k|*.pbm|*.pgm|*.ppm|*.pnm|*.xbm|*.xpm|*.raw|*.dng|*.cr2|*.cr3|*.nef|*.arw|*.orf|*.rw2|*.raf) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "${mode}" == choose ]]; then
  if ! command -v kdialog >/dev/null 2>&1; then
    echo "The image chooser needs kdialog. Use --file PATH or install kdialog." >&2
    exit 1
  fi
  selected_file="$(kdialog --title "Choose InnyGrOS wallpaper" --getopenfilename "${HOME}" \
    'Images (*.jpg *.jpeg *.png *.gif *.webp *.apng *.bmp *.tif *.tiff *.svg *.svgz *.avif *.heic *.heif *.jxl *.jp2 *.xbm *.xpm *.raw *.dng *.cr2 *.cr3 *.nef *.arw *.orf *.rw2 *.raf)' 2>/dev/null)" || {
      echo "Wallpaper selection cancelled."
      exit 0
    }
  [[ -n "${selected_file}" ]] || { echo "Wallpaper selection cancelled."; exit 0; }
elif [[ "${mode}" == default ]]; then
  selected_file="${DEFAULT_SOURCE}"
fi

if [[ ! -f "${selected_file}" || ! -r "${selected_file}" ]]; then
  echo "Image file does not exist or cannot be read: ${selected_file}" >&2
  exit 1
fi
if ! is_candidate_image "${selected_file}"; then
  echo "That file extension is not in the image viewer's planned compatibility list: ${selected_file}" >&2
  echo "Choose an image file. The viewer and wallpaper plugin may support different formats." >&2
  exit 1
fi

mkdir -p -- "${TARGET_DIR}"
if [[ "${selected_file}" == "${DEFAULT_SOURCE}" ]]; then
  install -m 0644 -- "${DEFAULT_SOURCE}" "${TARGET}"
  selected_file="${TARGET}"
fi

if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
  if plasma-apply-wallpaperimage "${selected_file}"; then
    echo "Wallpaper applied: ${selected_file}"
    case "${selected_file,,}" in
      *.gif|*.webp|*.apng)
        echo "Note: animation may display as a still frame; animated wallpaper depends on the active Plasma wallpaper plugin."
        ;;
    esac
    exit 0
  fi
fi

message="The file was selected, but Plasma could not apply it automatically. Open System Settings → Wallpaper and select:
${selected_file}

The image viewer may support formats that the current wallpaper plugin cannot display."
if command -v kdialog >/dev/null 2>&1; then
  kdialog --title "InnyGrOS Wallpaper" --msgbox "${message}" >/dev/null 2>&1 || true
else
  printf '%s\n' "${message}"
fi
