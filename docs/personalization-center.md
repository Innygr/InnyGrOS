# IntegerOS Personalization Center

A user-scoped graphical hub for the existing IntegerOS appearance tools and KDE Plasma settings.

## Install

From the repository root:

```bash
bash scripts/install-personalization-center.sh
```

Search the application launcher for **IntegerOS Personalization Center**.

Requirements: Kubuntu/KDE Plasma, Python 3, and Tkinter (`sudo apt install python3-tk` if Tkinter is missing).

## Included sections

- **Wallpaper:** opens IntegerOS Black Hole Wallpaper Studio when available, otherwise the existing wallpaper chooser or KDE wallpaper settings.
- **Dock:** explains how to open Plasma's native panel edit mode. Panel geometry and visibility remain managed by Plasma.
- **Desktop effects:** opens KDE's native KWin effects module.
- **Appearance:** opens IntegerOS Theme Studio and KDE desktop settings.

The hub does not silently change settings, install themes, or edit Plasma configuration files. It deliberately does not expose fake audio-visualizer controls: the current visualizer's implementation/configuration is not part of this repository yet.

## Uninstall

```bash
rm -f ~/.local/bin/integeros-personalization-center
rm -f ~/.local/share/applications/integeros-personalization-center.desktop
rm -rf ~/.local/share/integeros/personalization
```

This removes the hub and its private copy of Wallpaper Studio. It does not undo desktop settings.
