# IntegerOS Theme Studio

A small, user-scoped GUI for common KDE appearance tasks. The first release deliberately reuses KDE's own settings modules and IntegerOS's existing wallpaper helper rather than writing directly to Plasma configuration files.

## Install

From the repository root:

```bash
bash scripts/install-theme-studio.sh
```

Then search the KDE application launcher for **IntegerOS Theme Studio**. It requires Python 3 with Tkinter and KDE System Settings. On Kubuntu, install Tkinter if needed with `sudo apt install python3-tk`.

## Included actions

- Apply the existing InnyGrOS violet/cyan colour scheme using `plasma-apply-colorscheme`.
- Open the existing wallpaper chooser helper; if it is unavailable, open KDE Wallpaper settings.
- Open KDE's icon, cursor, global theme, and font settings modules.

The app does not install themes, download assets, edit system-wide files, or change settings until an action is selected. Icon, cursor, global theme, and font choices are managed by KDE System Settings.

## Uninstall

Remove the user-scoped launcher and app:

```bash
rm -f ~/.local/bin/integeros-theme-studio ~/.local/share/applications/integeros-theme-studio.desktop
rm -rf ~/.local/share/integeros/theme-studio
```

This does not undo appearance choices already made in KDE.
