#!/usr/bin/env bash
set -euo pipefail

# Build a locally branded IntegerOS live wallpaper from a video you have
# permission to use. The source video and artwork are intentionally not
# included in this repository.
#
# Usage:
#   ./scripts/build-black-hole-wallpaper.sh VIDEO.mp4 NegInny.png TeamBlacklightLogo.ico [OUTPUT.mp4]

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 VIDEO.mp4 NegInny.png TeamBlacklightLogo.ico [OUTPUT.mp4]" >&2
  exit 2
fi

video=$(realpath "$1")
neg_inny=$(realpath "$2")
team_logo=$(realpath "$3")
output="${4:-InnyGrOS-BlackHole-TeamBlacklight.mp4}"

for file in "$video" "$neg_inny" "$team_logo"; do
  [[ -f "$file" ]] || { echo "File not found: $file" >&2; exit 1; }
done
command -v ffmpeg >/dev/null || { echo "ffmpeg is required." >&2; exit 1; }
command -v magick >/dev/null || { echo "ImageMagick is required to convert the ICO logo to PNG." >&2; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
magick "$team_logo" -background none -alpha on "$tmpdir/team-blacklight.png"

mkdir -p "$(dirname "$output")"

# The original video remains the background. The two supplied assets are small
# and sit in opposite bottom corners, away from the central black hole.
ffmpeg -hide_banner -y \
  -i "$video" \
  -loop 1 -framerate 30 -i "$neg_inny" \
  -loop 1 -framerate 30 -i "$tmpdir/team-blacklight.png" \
  -filter_complex \
  "[1:v]scale=128:130,format=rgba,colorchannelmixer=aa=0.90[neg];[2:v]scale=88:88,format=rgba,colorchannelmixer=aa=0.88[tbl];[0:v][neg]overlay=48:H-h-42:shortest=1[tmp];[tmp][tbl]overlay=W-w-48:H-h-42:shortest=1,format=yuv420p[out]" \
  -map "[out]" -map 0:a? -c:v libx264 -preset veryfast -crf 20 \
  -c:a aac -b:a 128k -shortest -movflags +faststart "$output"

echo "Created: $output"
