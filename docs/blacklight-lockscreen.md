# Blacklight Matrix native lock screen (experimental)

This optional helper patches the installed Plasma 6 lock-screen QML to add animated green Matrix rain and hide the wallpaper-fader/blur layer. KDE's original lock-screen UI and authentication object remain in place; this does **not** replace password verification or create a fake fullscreen lock.

**Warning:** this edits a system QML file and is experimental. Keep your current desktop session open, have a recovery path available, and do not install it immediately before you need the laptop. A Plasma update may replace the patched system file. The helper stores an exact backup and refuses to overwrite an existing backup.

## Check compatibility

From the repository root:

```bash
bash scripts/blacklight-lockscreen.sh status
```

The helper currently recognizes these Plasma lock-screen QML locations:

- `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml`
- `/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/LockScreenUi.qml`

If neither exists, the helper stops without changing anything.

## Install the animation and remove the blur/fade

```bash
sudo bash scripts/blacklight-lockscreen.sh install
```

It saves the original file under `/var/lib/innygros/blacklight-lockscreen/LockScreenUi.qml.original`, adds a non-interactive animated overlay, and disables the `WallpaperFader` layer. It does not restart Plasma or the display manager. Press **Meta + L** to test.

This changes the **in-session lock screen**. The SDDM login greeter shown before you sign in is separate; the repository's SDDM theme already draws its own sharp, unblurred background and login panel.

## Restore

If anything looks wrong, restore the exact original file:

```bash
sudo bash scripts/blacklight-lockscreen.sh restore
```

If the helper cannot find its backup or the current file no longer contains the InnyGrOS marker, it refuses to overwrite the current file automatically. Inspect the backup at the path above rather than deleting or replacing system QML blindly.

## Limitations

- Source-level smoke tests do not prove the patch is compatible with every Plasma release or GPU.
- The patch relies on recognizable upstream QML anchors. It stops if the expected structure is absent.
- Plasma package updates can replace the patch; rerun `status` after upgrades.
- This does not customize SDDM and does not change the login password, account, or authentication flow.
