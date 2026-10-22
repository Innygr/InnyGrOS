# Recovery

InnyGrOS only changes files in your home folder, and every change has a way back. Start with the first option that applies.

## 0. Find out what is wrong

```bash
./scripts/doctor.sh
```

It checks the installed files, the tools InnyGrOS needs, and the desktop state, and prints a fix for each problem. Nothing is changed. Also available in the Welcome Center as **Check InnyGrOS installation (doctor)**.

## 1. Undo the desktop profile

- Welcome Center → **Restore previous desktop settings**, or
- `./scripts/desktop-profile.sh restore` (most recent snapshot)
- `./scripts/desktop-profile.sh list`, then `restore --snapshot desktop-YYYYMMDD-HHMMSS` for an older one

This puts back only the settings InnyGrOS changed (color scheme, wallpaper, animation speed, default Konsole profile). Log out and back in if anything still looks changed.

If that is not enough, `./scripts/desktop-profile.sh restore --files` copies the whole saved config files back. Your current files are saved to `~/.local/share/innygros/backups/before-restore-*` first.

## 2. Remove InnyGrOS from your profile

```bash
./scripts/restore-defaults.sh            # asks before each step
./scripts/restore-defaults.sh --dry-run  # show what it would do
```

It restores desktop settings from the latest snapshot, then **moves** (does not delete) InnyGrOS files into `~/.local/share/innygros/backups/removed-*`:

- `~/.local/share/color-schemes/InnyGrOS.colors`
- `~/.local/share/wallpapers/InnyGrOS-Desktop.svg`
- `~/.local/share/konsole/InnyGrOS.profile` and `InnyGrOS.colorscheme`
- `~/.local/share/applications/innygros-welcome.desktop`, `~/.local/bin/innygros-welcome`, and `~/.config/autostart/innygros-welcome.desktop`, and the `innygros` icon in `~/.local/share/icons`
- `~/.local/share/innygros/{apps,scripts,config,branding}`

Snapshots and performance reports stay in `~/.local/share/innygros` so you can still compare or restore later. Delete that folder yourself when you no longer need them.

Packages installed by `install-apps.sh` are not removed. Remove them with Discover or `sudo apt remove <package>` if you want.

## 3. If Plasma will not start properly

1. At the login screen choose a **Plasma (X11)** or **Plasma (Wayland)** session other than the one that fails, or press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd> for a text console and log in.
2. Run `~/path/to/InnyGrOS/scripts/desktop-profile.sh restore --files --yes`, or copy files back by hand from the newest `~/.local/share/innygros/backups/desktop-*/files/` into `~/.config/`.
3. As a last resort, rename (do not delete) `~/.config/plasma-org.kde.plasma.desktop-appletsrc` and `~/.config/plasmashellrc`; Plasma recreates a default desktop at next login.
4. Press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd> (or <kbd>F2</kbd>) to return to the graphical login, or run `sudo reboot`.

## 4. Undoing the Welcome Center's individual actions

| Action | Undo |
| --- | --- |
| Apply InnyGrOS colors | System Settings → Colors & Themes → Colors → pick another scheme |
| Install / apply wallpaper | Right-click desktop → Configure Desktop and Wallpaper |
| Install terminal theme | Konsole → Settings → Manage Profiles → pick another default; previous same-named files were saved as `*.backup.*` in `~/.local/share/konsole` |
| Power mode | Choose another mode in the Welcome Center or from the battery icon in the panel |
| Show Welcome Center at login | Select the same menu item again, or remove it in System Settings → Autostart |
| Performance snapshot, game readiness, diagnostics | Read-only; nothing to undo (saved reports are in `~/.local/share/innygros/reports`) |
