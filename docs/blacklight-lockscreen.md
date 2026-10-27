# Blacklight Matrix native lock screen (experimental)

This optional helper patches two installed Plasma 6 lock-screen QML files to add animated green Matrix rain, keep the wallpaper sharp, and style KDE's real password field and unlock button in the InnyGrOS green-on-black palette. KDE's original lock-screen UI, password field, unlock button action, and authentication object remain in place; this does **not** replace password verification or create a fake fullscreen lock.

**Warning:** this edits system QML files and is experimental. Keep your current desktop session open, have a recovery path available, and do not install it immediately before you need the laptop. A Plasma update may replace the patched system files. The helper stores backups of both originals and refuses to overwrite an existing backup.

## Check compatibility

Run from the repository root:

    bash scripts/blacklight-lockscreen.sh status

The helper currently recognizes these Plasma lock-screen QML locations:

- /usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
- /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/lockscreen/LockScreenUi.qml

MainBlock.qml must exist beside the detected LockScreenUi.qml. If the expected files or QML anchors are missing, the patcher stops without intentionally changing either file.

## Install the animation and Blacklight authentication styling

    sudo bash scripts/blacklight-lockscreen.sh install

It backs up the original files under:

- /var/lib/innygros/blacklight-lockscreen/LockScreenUi.qml.original
- /var/lib/innygros/blacklight-lockscreen/MainBlock.qml.original

It adds a non-interactive animated overlay, disables the WallpaperFader layer, and styles the native password field and unlock button. It does not restart Plasma or the display manager. Press Meta + L to test.

This changes the **in-session lock screen**. The SDDM login greeter shown before you sign in is separate; its theme is managed by scripts/login-theme.sh.

## Restore

If anything looks wrong, restore the exact original files:

    sudo bash scripts/blacklight-lockscreen.sh restore

If the helper cannot find its backup or the current files no longer contain the expected InnyGrOS markers, it refuses to overwrite the changed files automatically. Inspect the backups rather than deleting or replacing system QML blindly.

## Validation and limitations

- tests/blacklight-lockscreen-patcher.py checks the QML transformation against small fixtures, including idempotency and refusing unknown layouts without changing either input file.
- These source-level tests do not prove compatibility with every Plasma release or GPU; the result still needs a visual test on the target Kubuntu/Plasma system.
- The patch relies on recognizable upstream QML anchors and stops if the expected structure is absent.
- Plasma package updates can replace the patch; rerun status after upgrades.
- This does not customize SDDM and does not change the login password, account, or authentication flow.
