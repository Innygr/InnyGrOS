# IntegerOS Quick Settings

A compact, user-scoped GUI for common KDE desktop controls. It complements the existing system-monitor side panel: it changes settings rather than duplicating monitoring.

## Features

- Toggle the NetworkManager Wi-Fi radio with `nmcli`.
- Power the Bluetooth adapter on or off with `bluetoothctl`.
- Mute or unmute the current default audio output with `pactl` (works with PipeWire's PulseAudio compatibility layer too).
- Select an available power profile with `powerprofilesctl`.
- Open KDE System Settings directly to Network, Bluetooth, and Audio modules.
- Refresh displayed states on demand.

Controls are shown as unavailable when their command-line service is missing. The application does not install packages, use administrator privileges, disconnect individual Wi-Fi networks, pair Bluetooth devices, change volume levels, or edit system configuration files.

## Install

From the repository root on Kubuntu:

```bash
bash scripts/install-quick-settings.sh
```

Requires Python 3 and Tkinter. On Kubuntu, install Tkinter if needed with `sudo apt install python3-tk`. The optional controls use the corresponding desktop services already present on the system.

Search the KDE application launcher for **IntegerOS Quick Settings**. To add a keyboard shortcut, open System Settings → Keyboard → Shortcuts and assign a shortcut to the application.

## Uninstall

```bash
rm -f ~/.local/bin/integeros-quick-settings ~/.local/share/applications/integeros-quick-settings.desktop
rm -rf ~/.local/share/integeros/quick-settings
```

Uninstalling the GUI does not revert the Wi-Fi, Bluetooth, audio, or power choices already made.
