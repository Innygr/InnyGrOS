# Animated Black Hole Wallpaper

This workflow uses the 1920×1080 MP4 selected by you as the background and overlays your own NegInny (your Celestan) and Team Blacklight logo. The source video and branding assets are **not included in this repository** because redistribution permission for the video has not been established.

## Easiest method: GUI builder on Kubuntu/KDE

After pulling the latest `main`, run this from the repository directory:

```bash
bash scripts/brand-black-hole-wallpaper.sh
```

The script opens file pickers for:
1. The source video (`.mp4`, `.mkv`, `.webm`, `.mov`, or `.avi`).
2. Your NegInny image.
3. Your Team Blacklight logo (`.ico` or a normal image).
4. Where to save the finished MP4.

If FFmpeg or ImageMagick is missing, it asks first and then uses the system's graphical authentication prompt to install them. It does not hard-code or collect your password. Rendering can take a few minutes depending on video length and laptop performance. The output defaults to `~/Videos/InnyGrOS-BlackHole-TeamBlacklight.mp4`.

The source video remains the background; NegInny is overlaid at the lower left and the Team Blacklight logo at the lower right. All selected files are processed locally and are not uploaded by the script.

## Manual builder

If you prefer using a terminal with file paths already known, the older non-GUI script is also available:

```bash
bash scripts/build-black-hole-wallpaper.sh VIDEO.mp4 NegInny.png TeamBlacklightLogo.ico OUTPUT.mp4
```

It requires FFmpeg and ImageMagick to already be installed.

## Use it as a live wallpaper

The output is an MP4, not an animated SVG. MP4 is much better suited to preserving the original video's animation, quality, and audio. KDE Plasma's default image wallpaper plugin may not play video files; you will need a compatible, trusted video/live-wallpaper plugin and then choose the generated MP4 in that plugin's settings. Support and setup vary by Plasma version.

## Why `git pull` didn't visibly change anything

A pull only downloads the script and documentation into the repository folder; it does not run the script, install dependencies, or change your desktop wallpaper automatically. After pulling, run the command in the GUI-builder section above.

## Copyright and attribution

Source page: https://motionbgs.com/space-black-hole

The source video's redistribution terms could not be confirmed, so the MP4 and any rendered derivative are not committed to this public repository. Check the current source terms and obtain permission before redistributing a derivative. The builder uses the original branding files you select; it does not generate replacement logos.
