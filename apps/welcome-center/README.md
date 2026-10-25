# InnyGrOS Welcome Center

The first experimental graphical control center uses KDE's `kdialog`, so it does not need a separate Python GUI framework.

## First launch

The first time it opens, the Welcome Center offers a short **first steps** guide: save a baseline performance snapshot and run the hardware check (both read-only, done first so you have numbers from before any change), then optionally apply the desktop look, install the terminal theme, and show the Welcome Center at login. It is shown once (remembered in `~/.local/state/innygros/first-run-done`) and can be reopened from **First steps guide** in the menu.

## Current actions
- Open System Settings, Discover (software and updates), Dolphin, or Konsole
- Apply the InnyGrOS desktop profile (color scheme, wallpaper, animation speed, default Konsole profile), with a snapshot taken first
- Restore the desktop settings saved by the last profile apply
- Apply the InnyGrOS color scheme, wallpaper, or terminal theme individually
- Check Minecraft / Windows game readiness (read-only)
- View system diagnostics, a performance snapshot, and a laptop hardware check (all read-only)
- Compare the last two saved performance snapshots
- Run a quick connectivity and Tailscale service check (read-only), or a battery/power health report (read-only; serial numbers omitted)\n- Check the InnyGrOS installation (doctor): installed files, required and optional tools, desktop state, with a fix for each problem
- Switch power mode (power saver / balanced / performance), the same setting as the panel battery icon
- Turn "show Welcome Center at login" on or off (creates or removes only `~/.config/autostart/innygros-welcome.desktop`)
- Open the project repository and show project information

## Install
From the repository root on Kubuntu:

```bash
./scripts/install-welcome-center.sh
```

It installs user-scoped files under `~/.local/share/innygros`, a launcher under `~/.local/bin`, and a desktop entry under `~/.local/share/applications`. It does not need root privileges. KDE's `kdialog` and the relevant KDE applications must be installed.

You can also run it straight from a checkout with `apps/welcome-center/innygros-welcome`; it then uses the helper scripts in that checkout instead of the installed copies. **About InnyGrOS** shows which helper folder is in use.

## How actions run
- Helpers run with no terminal attached and their input closed, so nothing can hang waiting for keyboard input when the Welcome Center is started from the application launcher.
- Helper output is appended to `~/.cache/innygros/welcome-center.log`.
- If a helper is missing or fails, an error window explains what happened and shows the last lines of its output under **Details**.
- Missing applications (for example Discover or Konsole) produce a message instead of a silent failure.

## Limitations
This is an early shell-based GUI, not a polished native application. It does not install system updates itself or run privileged operations. Use Discover for software installation and updates.
