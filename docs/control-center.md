# InntegerOS Control Center

The Control Center is the single application-menu entry for InntegerOS. It brings the former Welcome Center together with system maintenance, personalization, quick settings and Blacklight tools.

## Sections

- **Overview:** first-steps guide, desktop profile apply/restore, updater and Discover.
- **System:** boot studio, diagnostics, hardware, performance, game readiness, power, network, battery and image-viewer reports.
- **Desktop:** Wallpaper Studio, wallpaper settings, Theme Studio, dock/panel guidance, Destroy Windows and desktop effects.
- **Quick Settings:** Wi-Fi, Bluetooth, audio, notifications and the existing compact Quick Settings panel.
- **Blacklight:** Desktop Suite, Blacklight Control, screensaver and lockscreen helpers.

The individual scripts and specialist tools remain modular implementation components, but the installer consolidates their application-menu launchers into one Control Center entry.

## Install

From the repository root:

```bash
bash scripts/install-control-center.sh
```

Run as the normal desktop user, without `sudo`. Search the application launcher for **InntegerOS Control Center**.

The installer reuses the existing Welcome Center installer to deploy its mature helper scripts, then installs the unified hub and removes the separate InntegerOS menu entries. It does not remove the underlying tools or their data.
