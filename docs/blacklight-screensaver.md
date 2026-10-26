# Blacklight Matrix screensaver

This optional fullscreen visual reuses the Blacklight Matrix boot aesthetic: green code rain, INNYGRCORP branding, and an idle message. It is a normal user application, does not need root, makes no network requests, and exits on keyboard or mouse activity.

**Security note:** this is a visual screensaver, not a security lock. Keep KDE's normal screen locking enabled separately.

## Run it manually

From the repository root:

```bash
python3 apps/blacklight-screensaver/blacklight-matrix.py
```

Press any key, move the mouse, or click to exit. It is also added to the application menu by the optional setup command below.

## Optional automatic idle activation

Automatic idle detection in this helper is supported only in an X11 Plasma session and uses `xautolock`. It intentionally refuses to configure automatic idle activation on Wayland rather than pretending the X11 watcher will work there. The visual can still be launched manually on Wayland.

Check status:

```bash
bash scripts/blacklight-screensaver.sh status
```

If `xautolock` is missing and you are using X11, install it explicitly:

```bash
sudo apt install xautolock
```

Enable automatic activation after five minutes of inactivity:

```bash
bash scripts/blacklight-screensaver.sh enable
```

Log out and back in for the watcher to start. Disable automatic activation at any time:

```bash
bash scripts/blacklight-screensaver.sh disable
```

Disabling removes only the dedicated InnyGrOS autostart file. The application-menu launcher is left installed. This feature does not modify the KDE lock-screen configuration or change the system's security timeout.
