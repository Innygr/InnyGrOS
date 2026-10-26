# Blacklight Matrix screensaver

This optional fullscreen visual reuses the Blacklight Matrix boot aesthetic: green code rain, INNYGRCORP branding, and an idle message. It is a normal user application, does not need root, makes no network requests, and exits on keyboard or mouse activity.

**The animated Python visual is not itself a secure lock screen.** InnyGrOS now has a Blacklight wallpaper for KDE's real lock screen and an X11 idle helper that invokes KDE's native locker. Authentication is still handled by KDE.

## Run it manually

From the repository root:

```bash
python3 apps/blacklight-screensaver/blacklight-matrix.py
```

Press any key, move the mouse, or click to exit. If launch reports that `tkinter` is missing, install it with `sudo apt update && sudo apt install python3-tk`. The helper’s `status` command also reports whether Tkinter is available. The app is also added to the application menu by the optional setup command below.

## Make Blacklight the lock-screen appearance

From the repository root, run:

```bash
bash scripts/blacklight-screensaver.sh lockscreen
```

This installs `branding/lockscreen/blacklight-matrix.svg` into your user wallpaper directory and selects it as the background for KDE's **native** lock screen. It saves the previous wallpaper settings first. To undo the wallpaper change:

```bash
bash scripts/blacklight-screensaver.sh restore-wallpaper
```

This changes the lock-screen background, not KDE's authentication UI layout. The SDDM login screen and the in-session lock screen are separate.

## Optional automatic secure locking

On an X11 Plasma session, install `xautolock` and enable the helper. It will request KDE's native lock screen after five minutes of inactivity; it does not use the Python visual as a fake lock window. On Wayland, configure automatic locking through **System Settings → Security & Privacy → Screen Locking**, because this X11 idle watcher does not work there.

Check status:

```bash
bash scripts/blacklight-screensaver.sh status
```

If `xautolock` is missing and you are using X11, install it explicitly:

```bash
sudo apt install xautolock
```

Enable secure automatic locking after five minutes of inactivity (X11 only):

```bash
bash scripts/blacklight-screensaver.sh enable
```

Log out and back in for the watcher to start. Disable automatic activation at any time:

```bash
bash scripts/blacklight-screensaver.sh disable
```

Disabling removes only the dedicated InnyGrOS autostart file. The application-menu launcher and lock-screen wallpaper setting are managed separately. Keep KDE's password-required lock behavior enabled.
