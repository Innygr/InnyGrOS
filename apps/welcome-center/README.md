# InnyGrOS Welcome Center

The first experimental graphical control center uses KDE's `kdialog`, so it does not need a separate Python GUI framework.

## Current actions
- Open System Settings
- Open Discover for software and graphical update management
- Open Dolphin File Manager
- Apply the InnyGrOS color scheme (backs up an existing project-owned scheme first)
- View read-only system diagnostics
- Open the project repository
- Optionally open Konsole for advanced tasks
- Show project information

## Install
From the repository root on Kubuntu:

```bash
./scripts/install-welcome-center.sh
```

It installs user-scoped files under `~/.local/share/innygros`, a launcher under `~/.local/bin`, and a desktop entry under `~/.local/share/applications`. It does not need root privileges. KDE's `kdialog` and the relevant KDE applications must be installed.

## Limitations
This is an early shell-based GUI, not a polished native application. It does not yet install system updates itself, change performance settings, or run privileged operations. Use Discover for software installation and updates.
