# KDE configuration

InnyGrOS never replaces your whole `~/.config` directory or whole Plasma config files. Desktop settings are applied by `scripts/desktop-profile.sh` (also in the Welcome Center as **Apply InnyGrOS desktop profile**), one key at a time, using `kwriteconfig6` on Plasma 6 or `kwriteconfig5` on Plasma 5.

## What the desktop profile can change

Each item is optional and you choose which to apply.

| Setting | Where | Notes |
| --- | --- | --- |
| Color scheme → InnyGrOS | `kdeglobals` `[General] ColorScheme` | Applied with `plasma-apply-colorscheme` when available, which also rewrites the color groups in `kdeglobals`. |
| Wallpaper → InnyGrOS | `plasma-org.kde.plasma.desktop-appletsrc` | Applied with `plasma-apply-wallpaperimage`. |
| Animation speed | `kdeglobals` `[KDE] AnimationDurationFactor` | `keep` (default), `faster` = 0.5, `off` = 0. Can make an older laptop feel more responsive; any CPU or battery effect is unmeasured. |
| Default Konsole profile | `konsolerc` `[Desktop Entry] DefaultProfile` | Only if the InnyGrOS terminal theme is installed. |

## Snapshots and restore

Before changing anything, `apply` creates `~/.local/share/innygros/backups/desktop-YYYYMMDD-HHMMSS/` containing:

- `settings.tsv`: the previous value of every key it is about to change (or a marker meaning "was not set")
- `wallpaper`: the previous wallpaper path, if Plasma recorded one
- `files/`: full copies of `kdeglobals`, `kwinrc`, `konsolerc`, and the Plasma desktop applets file as they were

`restore` (or **Restore previous desktop settings** in the Welcome Center) puts back only those keys and re-applies the previous color scheme and wallpaper, so other changes you made later are kept. `restore --files` copies the saved files back whole as a last resort; your current files are saved to `backups/before-restore-*` first.

## When to log out

Colors and wallpaper normally update immediately. Animation speed is picked up by KWin after a reconfigure; applications that are already open may need restarting, and if KWin could not be reached the tool tells you to log out and back in. After `restore --files`, always log out and back in.
