# IntegerOS

**IntegerOS 0.7 — Desktop Edition**  
An Ubuntu-based desktop customization project built on Kubuntu + KDE Plasma.

> Early development: this repository is not yet a standalone operating system or installable ISO.

## Current features
- Guided setup script and optional developer-tool installer
- Graphical software updater in the Welcome Center for IntegerOS source updates, with a separate terminal workflow for user-approved Ubuntu/Kubuntu APT upgrades
- Dark violet/cyan KDE color scheme
- Original 1920×1080 vector wallpaper with InnyGr and Team Blacklight identity
- Custom Konsole profile with Fira Code, violet/cyan terminal colors, and scrollback
- Welcome Center for desktop settings, wallpaper, terminal setup, read-only diagnostics, and Deep Space Boot Studio for installing/removing the optional GRUB theme
- Image-viewer compatibility report available from the Welcome Center, with a local inventory of Gwenview, image-format packages, and Qt plugins (not a substitute for visual format testing)
- Reversible KDE desktop profile (colors, wallpaper, animation speed, default Konsole profile, optional IntegerOS startup splash) with snapshots and one-click restore
- Read-only performance snapshot (boot time, memory, power, battery, graphics, rough CPU timing) with optional saved reports for before/after comparison
- Power mode switcher (power saver / balanced / performance) using the standard power-profiles interface, and an optional "show Welcome Center at login" setting
- Read-only laptop hardware check (Wi-Fi, Bluetooth, audio, backlight, touchpad/TrackPoint, batteries, suspend mode, thermals) plus a ThinkPad T580 test plan
- Read-only network report for NetworkManager, IP addresses, default route, DNS, nearby Wi-Fi metadata, and detected VPN/overlay interfaces (including Tailscale and WireGuard when installed), plus a quick connectivity/Tailscale health check in the Welcome Center
- Read-only battery and power report for battery status, estimated design-capacity remaining when exposed by firmware, power profile, and optional temperature sensor output; available from the Welcome Center
- Game-readiness report for Minecraft Java, Windows compatibility tools, graphics drivers, and Vulkan
- Experimental GRUB Boot Manager with violet/cyan styling, OS-entry preview, and optional Random Boot on normal shutdown/reboot ([docs](docs/boot-manager.md))
- Optional native Plymouth **Blacklight Matrix** boot animation with animated code rain, boot-progress indicator, and a guarded installer/uninstaller ([docs](docs/boot-animation.md))
- Optional **Blacklight Matrix SDDM login theme** with animated code rain, green authentication panel, session selection, and guarded install/uninstall ([docs](docs/login-theme.md))
- Optional fullscreen **Blacklight Matrix screensaver** with animated code rain; manual launcher works independently, and automatic five-minute idle activation is opt-in for X11 sessions only ([docs](docs/blacklight-screensaver.md))
- Experimental, reversible **native Plasma lock-screen Matrix overlay** that adds animated code rain and disables the wallpaper blur/fader while preserving KDE's native authentication ([docs](docs/blacklight-lockscreen.md))
- User-scoped configuration installation with timestamped backups for existing same-named Konsole files
- Conservative performance diagnostics and GitHub Actions validation
- 0.8 planned: broad-format image viewing, including animated formats where the selected viewer/backend supports them ([image viewer plan](docs/IMAGE-VIEWER.md), [compatibility results ledger](docs/IMAGE-VIEWER-RESULTS.md))

## Quick start on Kubuntu

From the repository root on Kubuntu:

```bash
chmod +x install.sh scripts/*.sh
./install.sh --check   # optional: see whether this system is supported
./install.sh
```

Open the Welcome Center and choose **Software updater** for a graphical source-update check and confirmation. The GUI updater is installed with the Welcome Center. For terminal use, run `bash scripts/software-updater.sh --check` to check source updates without changing files, or `bash scripts/software-updater.sh` for the interactive updater. IntegerOS source updates require a clean Git checkout on `main`; APT upgrades are a separate, explicitly approved action. The GUI updater does not silently apply desktop settings after a source update.

To undo IntegerOS changes, run `./scripts/restore-defaults.sh` or see [docs/recovery.md](docs/recovery.md).

The installer checks the distribution first, then asks before each step: package groups (required, diagnostics, KDE apps, developer tools), the Welcome Center, and the reversible desktop profile. It prints a summary of what was done, skipped, or failed. The Welcome Center can install the wallpaper and Konsole profile, and run a read-only game-readiness report. The report checks tools and graphics diagnostics already available on the system; it does not install anything or change settings.

## Desktop profile

```bash
./scripts/desktop-profile.sh status                      # what is set now
./scripts/desktop-profile.sh apply --animations faster   # asks before changing anything
./scripts/desktop-profile.sh restore                     # undo the most recent apply
```

Also available in the Welcome Center. See [config/kde/README.md](config/kde/README.md) for exactly what is changed and how restore works.

## Performance snapshot

```bash
./scripts/performance-benchmark.sh --text          # print the report
./scripts/performance-benchmark.sh --text --save   # also keep a copy in ~/.local/share/innygros/reports
```

`./scripts/compare-reports.sh` compares the two most recent saved snapshots side by side.

It is also available from the Welcome Center. The report only reads system information. The CPU timing is a rough single-thread loop for comparing the same machine before and after a change; it is not a cross-machine score.

## Network & VPN report

Run a local, read-only report from the repository checkout:

```bash
bash scripts/network-check.sh --text
```

It checks NetworkManager, IP addresses, the default route, DNS, nearby Wi-Fi metadata, and available Tailscale/WireGuard/VPN status. The report stays on your machine and does not change settings. Review it before sharing because it can include local addresses and network names.

## Battery & power report

Run a local, read-only battery and power report:

```bash
bash scripts/battery-power-report.sh
```

It reports battery status and capacity where the laptop firmware exposes those values, the current power profile, and temperature data if `lm-sensors` is already installed. It does not change power settings or charging thresholds, and it omits battery serial numbers. Capacity estimates are approximate.

## Blacklight Matrix boot animation (experimental)

Check the current Plymouth theme with `bash scripts/boot-animation.sh status`. To install the optional native splash theme, use `sudo bash scripts/boot-animation.sh install` and type `INSTALL` when prompted. Restore the previously selected theme with `sudo bash scripts/boot-animation.sh uninstall` and type `REMOVE`. The helper backs up the previous theme and rebuilds initramfs; read [docs/boot-animation.md](docs/boot-animation.md) first. Real-hardware visual and boot validation is still required.

## Blacklight Matrix screensaver (optional)

Run the animated visual with `python3 apps/blacklight-screensaver/blacklight-matrix.py`, or use `bash scripts/blacklight-screensaver.sh status`. Set the Blacklight wallpaper on KDE's native lock screen with `bash scripts/blacklight-screensaver.sh lockscreen`; restore the previous wallpaper with `restore-wallpaper`. On X11, install `xautolock` and run `bash scripts/blacklight-screensaver.sh enable` to invoke KDE's secure lock screen after five idle minutes; use `disable` to remove the watcher. On Wayland, set the automatic lock timeout in KDE System Settings. The animated visual itself is not a security lock. See [docs/blacklight-screensaver.md](docs/blacklight-screensaver.md).

## Blacklight Matrix native lock screen (experimental)

For the in-session lock screen, check compatibility with bash scripts/blacklight-lockscreen.sh status. To install animated Matrix rain, remove the wallpaper blur, and style KDE's real password field and unlock button in green-on-black, run sudo bash scripts/blacklight-lockscreen.sh install; restore both original Plasma QML files with sudo bash scripts/blacklight-lockscreen.sh restore. This is a reversible system-level patch, so keep a recovery path and read [docs/blacklight-lockscreen.md](docs/blacklight-lockscreen.md) first. KDE's native authentication is retained.

## Blacklight Matrix login theme (experimental)

Check the SDDM theme helper with `bash scripts/login-theme.sh status`. To install the optional green-on-black login screen, run `sudo bash scripts/login-theme.sh install` and type `INSTALL` when prompted. To remove it, run `sudo bash scripts/login-theme.sh uninstall` and type `REMOVE`. This is for SDDM systems such as Kubuntu; it does not apply to GDM. Read [docs/login-theme.md](docs/login-theme.md) first and keep a recovery path available. The installer does not restart SDDM, so log out only when ready to test.

## IntegerOS Boot Manager (experimental)

Preview your existing GRUB entries with `bash scripts/boot-manager.sh status`. To install the optional GRUB theme and Random Boot shutdown hook, use `sudo bash scripts/boot-manager.sh install` and type `INSTALL` when prompted. Random Boot is off by default; enable it with `sudo bash scripts/boot-manager.sh random-on` and disable it with `sudo bash scripts/boot-manager.sh random-off`. Read [docs/boot-manager.md](docs/boot-manager.md) first. This changes system boot configuration, has not been validated on the laptop, and should only be enabled after reviewing the detected entries and confirming a recovery path.

## Compatibility and safety
- Experimental Kubuntu + KDE Plasma customization, not a standalone ISO yet.
- Scripts need validation on real Kubuntu and Plasma versions.
- Package installation uses APT and asks for confirmation.
- Minecraft Java can run natively on Linux with a compatible launcher and Java runtime.
- Roblox has no official Linux client. The unofficial Sober client (Flathub) is detected but never installed; keep Windows available for dependable access. See [docs/compatibility.md](docs/compatibility.md).
- Wine/Bottles/Steam detection is only a basic check, not a guarantee that any particular game will run.

## Roadmap
- [ ] **0.8:** broad image-format support with animated GIF/WebP/APNG testing; see the [image viewer plan](docs/IMAGE-VIEWER.md) and [compatibility results ledger](docs/IMAGE-VIEWER-RESULTS.md)
- [ ] **December 2026–January 2027:** bootable IntegerOS ISO or equivalent; see [ISO roadmap](docs/ISO-ROADMAP.md)
- [x] Initial scaffold, KDE color scheme, and performance diagnostics
- [x] Graphical Welcome Center prototype
- [x] Branded wallpaper and application helper
- [x] Konsole profile and color scheme
- [x] Game-readiness diagnostics
- [x] Read-only performance snapshot
- [x] Reversible desktop profile with snapshot/restore
- [x] Basic GitHub Actions validation workflow
- [x] Original logo (hand-authored SVG) used as the Welcome Center icon
- [ ] Richer KDE desktop layout
- [ ] Automated tests and Kubuntu VM validation
- [x] Hardware check and ThinkPad T580 test plan
- [x] Network & VPN diagnostics in the Welcome Center ([docs/thinkpad-t580-test-plan.md](docs/thinkpad-t580-test-plan.md))
- [ ] ThinkPad T580 validation on real hardware
- [ ] Reproducible ISO build
- [x] Experimental GRUB Boot Manager prototype; real-hardware boot validation still required

## Development principles
1. Prefer graphical tools for ordinary tasks.
2. Keep scripts readable, rerunnable, and narrowly scoped.
3. Ask before installing packages or changing settings.
4. Back up configuration before modifying it.
5. Measure performance rather than promising arbitrary speed gains.

## Changelog
See [CHANGELOG.md](CHANGELOG.md). The current version is in [VERSION](VERSION).

## License
GNU General Public License v2.0. See [LICENSE](LICENSE).
