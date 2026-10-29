# IntegerOS Wallpaper Studio

A graphical application for creating branded MP4 wallpapers for IntegerOS / KDE Plasma. It uses the original user-selected background video, NegInny artwork, and Team Blacklight logo locally; it does not upload media.

## Features

- File pickers for background video, NegInny image, Team Blacklight logo, and output MP4
- Editable text labels and color pickers
- Font family and text-size controls
- Independent X/Y positioning for each text label and logo, adjustable from 0% to 100% of the available travel range
- Configurable bottom margin, artwork sizes, output duration, H.264 preset, and CPU thread limit
- Low-priority FFmpeg rendering to help keep the desktop responsive
- Supports PNG, WebP, JPEG, and ICO logos (ICO conversion needs ImageMagick)

## Requirements

On Kubuntu / Ubuntu with KDE Plasma:

```bash
sudo apt install python3-tk ffmpeg imagemagick
```

ImageMagick is only needed if you select an ICO logo. The application itself uses Python's standard library and Tkinter.

## Run from the repository

```bash
python3 apps/integeros-wallpaper-studio.py
```

## Install a launcher for the current user

From the repository root:

```bash
mkdir -p "$HOME/.local/share/applications"
sed "s|/path/to/InnyGrOS|$PWD|g" packaging/integeros-wallpaper-studio.desktop > "$HOME/.local/share/applications/integeros-wallpaper-studio.desktop"
chmod +x "$HOME/.local/share/applications/integeros-wallpaper-studio.desktop"
```

Then search the application launcher for **IntegerOS Wallpaper Studio**. The launcher points to this checkout, so keep the repository folder in place. A future IntegerOS package can install the application under `/usr/lib/integeros/` and ship a launcher with the final absolute path.

## Layout

- Bottom-left: Team Blacklight text, then Team Blacklight logo
- Bottom-right: NegInny image, then Innygr Corp text

The default text colors are neon cyan and violet. The bottom margin is adjustable to keep branding clear of the Plasma panel. MP4 live playback requires a compatible video-wallpaper plugin.
