# Blacklight Desktop Suite

A user-scoped KDE utility with four tabs: Blacklight Terminal, Profiles, Animation, and Notifications.

## Install

From the repository root:

```bash
bash scripts/install-blacklight-suite.sh
```

Requires Python 3 and Tkinter. On Kubuntu, install Tkinter with `sudo apt install python3-tk` if needed. Search the KDE application launcher for **Blacklight Desktop Suite**.

## Blacklight Terminal

Launches Konsole using the installed InnyGrOS Konsole profile when present. Shell selection supports Auto (Fish if installed, otherwise Bash), Fish, and Bash. It launches a login shell and does not change the account's default shell or edit shell startup files. Install Fish separately through Discover if desired.

## Profiles

Development, School/Focus, Gaming, and Presentation presets set the Plasma global animation-duration factor and request a matching power profile when `powerprofilesctl` is available. The first preset saves the previous animation value and power profile under `~/.local/share/integeros/blacklight-suite/profile-backup`; Restore saved settings returns those values. The backup is kept until explicitly restored. A preset does not alter running applications or window layouts.

Power-profile names vary by hardware and power-profiles-daemon. Unsupported profiles are skipped. The GUI does not install packages or require root.

## Animation

Smooth/default, Snappy, and Instant adjust KDE's global animation-duration factor using kwriteconfig5/6. Individual KWin effects remain managed by KDE System Settings. This does not alter animated wallpaper playback.

## Notifications

The Notifications tab opens KDE's native Notifications settings and explains where Plasma exposes notification history and Do Not Disturb. KDE remains responsible for notification storage, app-specific rules, history and quiet mode; this utility does not create a parallel notification database or claim to replace the native notification applet.

## Uninstall

```bash
rm -f ~/.local/bin/blacklight-desktop-suite ~/.local/share/applications/blacklight-desktop-suite.desktop
rm -rf ~/.local/share/integeros/blacklight-suite
```

Removing the app does not reset KDE settings. Use the Profiles tab's Restore saved settings before uninstalling if you want to revert a preset.
