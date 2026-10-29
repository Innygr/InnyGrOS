#!/usr/bin/env bash
set -Eeuo pipefail

# IntegerOS / InnyGrOS branded video wallpaper builder for KDE Plasma.
# It asks for the video and the two original branding assets using GUI dialogs.
# It never uploads the selected media or assets anywhere.

APP_NAME="IntegerOS Black Hole Wallpaper"
WALLPAPER_DURATION=30
TEMP_DIR=""

cleanup() {
  [[ -z "$TEMP_DIR" ]] || rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

error() {
  if command -v kdialog >/dev/null 2>&1; then
    kdialog --title "$APP_NAME" --error "$1" || true
  else
    printf 'Error: %s\n' "$1" >&2
  fi
  exit 1
}

info() {
  if command -v kdialog >/dev/null 2>&1; then
    kdialog --title "$APP_NAME" --msgbox "$1" || true
  else
    printf '%s\n' "$1"
  fi
}

# KDE installations normally have kdialog. If it's missing, give a useful
# terminal fallback rather than failing with an obscure error.
if ! command -v kdialog >/dev/null 2>&1; then
  printf 'This script is designed for KDE Plasma and needs kdialog for file pickers.\n'
  printf 'Install it with: sudo apt install kdialog\n'
  exit 1
fi

if ! kdialog --title "$APP_NAME" --yesno "This tool creates a locally branded MP4 wallpaper from your video and original artwork. It may ask for administrator approval to install missing tools (FFmpeg and ImageMagick). Continue?"; then
  exit 0
fi

# Install missing tools only after the user explicitly approves. Use the system
# graphical authentication prompt, never a hard-coded password.
missing=()
command -v ffmpeg >/dev/null 2>&1 || missing+=(ffmpeg)
command -v magick >/dev/null 2>&1 || missing+=(imagemagick)
if (("${#missing[@]}" > 0)); then
  if ! command -v pkexec >/dev/null 2>&1; then
    error "Missing tools: ${missing[*]}. pkexec is unavailable, so install them manually with: sudo apt update && sudo apt install ffmpeg imagemagick"
  fi
  kdialog --title "$APP_NAME" --passivepopup "Installing required tools: ${missing[*]}" 5 || true
  if ! pkexec apt-get update; then
    error "Package list update failed or was cancelled. No wallpaper was created."
  fi
  if ! pkexec apt-get install -y "${missing[@]}"; then
    error "Installing dependencies failed or was cancelled. No wallpaper was created."
  fi
fi

video=$(kdialog --title "$APP_NAME" --getopenfilename "$HOME" "Video files (*.mp4 *.mkv *.webm *.mov *.avi)") || exit 0
[[ -n "$video" && -f "$video" ]] || exit 0

neg_inny=$(kdialog --title "$APP_NAME" --getopenfilename "$HOME" "Image files (*.png *.webp *.jpg *.jpeg)") || exit 0
[[ -n "$neg_inny" && -f "$neg_inny" ]] || exit 0

team_logo=$(kdialog --title "$APP_NAME" --getopenfilename "$HOME" "Logo files (*.ico *.png *.webp *.jpg *.jpeg)") || exit 0
[[ -n "$team_logo" && -f "$team_logo" ]] || exit 0

default_name="${HOME}/Videos/InnyGrOS-BlackHole-TeamBlacklight.mp4"
mkdir -p "$HOME/Videos"
output=$(kdialog --title "$APP_NAME" --getsavefilename "$default_name" "MP4 video (*.mp4)") || exit 0
[[ -n "$output" ]] || exit 0
if [[ "$output" != *.mp4 ]]; then output="${output}.mp4"; fi

if [[ -e "$output" ]]; then
  kdialog --title "$APP_NAME" --yesno "This file already exists:\n$output\n\nReplace it?" || exit 0
fi

TEMP_DIR=$(mktemp -d)
logo_png="$team_logo"
if [[ "$team_logo" == *.ico || "$team_logo" == *.ICO ]]; then
  logo_png="$TEMP_DIR/team-blacklight.png"
  if ! magick "$team_logo" -background none -alpha on "$logo_png"; then
    error "Couldn't convert the selected ICO logo. Try exporting it as a PNG and selecting that instead."
  fi
fi

mkdir -p "$(dirname "$output")"
kdialog --title "$APP_NAME" --passivepopup "Rendering wallpaper… This can take a few minutes. The output will be saved to:\n$output" 8 || true

if ! ffmpeg -hide_banner -y \
  -i "$video" \
  -loop 1 -framerate 30 -i "$neg_inny" \
  -loop 1 -framerate 30 -i "$logo_png" \
  -filter_complex \
  "[1:v]scale=150:150:force_original_aspect_ratio=decrease,pad=150:150:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=rgba,colorchannelmixer=aa=0.96[neg];[2:v]scale=96:96:force_original_aspect_ratio=decrease,pad=96:96:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=rgba,colorchannelmixer=aa=0.96[tbl];[0:v][neg]overlay=220:H-h-42:format=auto[tmp];[tmp][tbl]overlay=W-w-228:H-h-42:format=auto[logos];[logos]drawtext=font=Sans:text=Innygr Corp:fontcolor=white:fontsize=28:x=48:y=H-text_h-42,drawtext=font=Sans:text=Team Blacklight:fontcolor=white:fontsize=28:x=W-text_w-48:y=H-text_h-42,format=yuv420p[out]" \
  -map "[out]" -map "0:a?" -t "$WALLPAPER_DURATION" -c:v libx264 -preset medium -crf 20 \
  -c:a aac -b:a 160k -shortest -movflags +faststart "$output"; then
  error "FFmpeg failed to render the wallpaper. Check that the selected video is readable and there is enough disk space."
fi

info "Wallpaper created successfully!\n\n$output\n\nThe original video remains the background. NegInny is in the lower-left corner and the Team Blacklight logo is in the lower-right.\n\nNote: MP4 playback as a live wallpaper requires a compatible KDE Plasma video-wallpaper plugin; the default image wallpaper plugin may not play videos."
