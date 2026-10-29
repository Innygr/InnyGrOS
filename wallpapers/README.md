# Animated Black Hole Wallpaper

The wallpaper source is the 1920×1080 MP4 supplied by the user from MotionBGs. The source video is **not included in this repository** because redistribution permission has not been established. Use only a copy you are permitted to use.

## Build the branded wallpaper locally

Requirements: FFmpeg and ImageMagick.

1. Download or otherwise obtain the source video under its applicable terms.
2. Extract your original artwork from your own `Logos n stuff.zip` archive.
3. Run the build script, passing the video, your Celestan artwork (`NegInny.png`), and the Team Blacklight logo:

```bash
./scripts/build-black-hole-wallpaper.sh \
  ~/Videos/space-black-hole.1920x1080.mp4 \
  ~/Pictures/NegInny.png \
  ~/Pictures/TeamBlacklightLogo.ico \
  ~/Videos/InnyGrOS-BlackHole-TeamBlacklight.mp4
```

The script preserves the source video as the background and places NegInny in the lower-left corner and the original Team Blacklight icon in the lower-right. It exports H.264 MP4 at the source resolution. The source video and artwork files are read from your local paths; they are not uploaded to GitHub by this script.

## Set it as a KDE Plasma wallpaper

KDE Plasma's default image wallpaper plugin generally treats an MP4 as a still/unsupported image. Install a trusted Plasma-compatible video/live-wallpaper plugin, then select the generated MP4 through that plugin's settings. Availability and setup vary by Plasma version.

## Copyright and attribution

Source page: https://motionbgs.com/space-black-hole

The source video's redistribution terms could not be confirmed. This repository therefore contains only the local build script and instructions, not the video or a rendered derivative. Check the source's current terms and obtain permission if needed before publishing or redistributing a derivative. The uploaded NegInny and Team Blacklight assets are used as supplied; no replacement logos are generated.
