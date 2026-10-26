# Changelog

All notable changes to InnyGrOS. The current version is in the `VERSION` file; scripts and the Welcome Center read it from there.

Nothing in this project has been tested on real hardware yet unless an entry says so. "CI" means GitHub Actions on an Ubuntu runner with no desktop session.

## Unreleased

### Added
- Read-only image-viewer compatibility report (`scripts/image-viewer-report.sh`) available in the Welcome Center. It inventories Gwenview, relevant installed packages, and Qt image-format plugin directories without claiming that a format has been tested.
- Image-viewer integration smoke test now checks the report and its Welcome Center entry.
- Welcome Center installer now deploys the image-viewer report helper, so the menu action works after installation as well as from a repository checkout.
- CI checks that the report helper is included in the installed helper set.


## 0.7 — 2026-10-25

### Added
- Graphical software updater (`scripts/software-updater-gui.sh`) integrated into the Welcome Center. It checks source updates, displays installed/latest versions and commit count, requires confirmation before a fast-forward-only update, logs results, and keeps APT upgrades separate in a terminal workflow.
- Welcome Center installation now deploys the graphical and CLI updater helpers.
- After a successful source update, the GUI offers to refresh the installed Welcome Center and helper scripts separately; it never reapplies the desktop profile automatically.
- CI smoke coverage for the graphical updater shell syntax and safety checks.

### Safety
- The graphical updater refuses non-official remotes, non-`main` branches, and dirty worktrees; it never runs as root or applies desktop settings automatically.


### Added
- `scripts/software-updater.sh`: interactive update assistant that checks the official InnyGrOS Git checkout and separately offers user-approved APT package upgrades. Source updates refuse dirty worktrees and non-`main` branches; `--check` does not modify files or refresh APT lists.
- `tests/software-updater-fixture.sh`: CLI smoke test included in GitHub Actions validation.
- `scripts/battery-power-report.sh`: read-only battery/power diagnostics, including status, approximate design-capacity remaining when available, active power profile, and optional temperature sensor output. Omits battery serial numbers and makes no configuration changes.
- `scripts/network-health.sh`: standalone read-only connectivity and Tailscale service check for quick troubleshooting; the existing richer Welcome Center network report remains available through `scripts/network-check.sh`.

- Experimental `scripts/boot-manager.sh` for Ubuntu/Kubuntu GRUB: OS-entry preview, violet/cyan theme setup, explicit install/uninstall confirmation, and a shutdown hook that selects a random eligible top-level OS entry for the next normal boot.
- `docs/boot-manager.md` and a CI smoke test for the boot-manager helper. Not validated on real hardware; see documented limitations before installing.

## 0.6 — 2026-10-24

### Added
- Read-only Network & VPN report available from the Welcome Center and as `bash scripts/network-check.sh --text`.
- Reports NetworkManager state, local IP addresses, default route, DNS configuration, nearby Wi-Fi metadata, and available Tailscale/WireGuard/active VPN status.
- Report is local-only, makes no network configuration changes, and warns that local network names and addresses should be reviewed before sharing.
- CI smoke test for the network report and option handling.

### Added
- Hand-authored InnyGrOS logo (`branding/logo/innygros-logo.svg`), installed as the `innygros` icon for the Welcome Center launcher, dialogs, and login autostart entry.
- CI validates every SVG in the repository.
- InnyGrOS startup splash for Plasma 5 and 6 (`branding/splash/org.innygros.splash`): logo, name, and a progress bar driven by the startup stages. Opt-in through the desktop profile (`--splash` or the checklist) and restored like other settings. CI renders it offscreen with Qt 6 and Qt 5.
- `scripts/doctor.sh` and a Welcome Center item: read-only health check of the installation (version, installed files vs. checkout, launcher, menu entry, icon, PATH), required and optional tools, and desktop state, with a suggested fix for each problem.
- Welcome Center first-steps guide on first launch (baseline snapshot and hardware check first, then optional desktop look, terminal theme, and login autostart); reopen it from the menu.

## 0.5 — 2026-10-21

### Added
- `scripts/performance-benchmark.sh`: read-only performance snapshot (system, load, CPU and governor, memory, storage, boot timing, power profile, battery, graphics, Minecraft/Windows tools, rough CPU timing). Can save reports for before/after comparison.
- `scripts/compare-reports.sh`: side-by-side comparison of two saved snapshots.
- `scripts/desktop-profile.sh`: reversible KDE desktop profile (color scheme, wallpaper, animation speed, default Konsole profile) for Plasma 5 and 6, with per-key snapshots, `restore`, and `restore --files`.
- `scripts/hardware-check.sh`: read-only laptop hardware detection, plus `docs/thinkpad-t580-test-plan.md`.
- `scripts/power-mode.sh`: switch power profiles via `powerprofilesctl`.
- `scripts/lib/game-tools.sh`: shared Minecraft launcher, Wine/Bottles/Steam, and Sober/Vinegar detection with Flatpak IDs checked on Flathub.
- Welcome Center: desktop profile apply/restore, performance snapshot, snapshot comparison, hardware check, power mode, and an optional "show at login" toggle.
- `docs/recovery.md`, `CHANGELOG.md`, and a single `VERSION` file.
- CI: ShellCheck, a desktop profile apply/restore round trip using real KDE config tools, an install → recovery round trip, a Welcome Center smoke test, and fixture tests for the hardware, comparison, game-tool, and power-mode scripts.

### Changed
- `install.sh`: distribution and desktop checks, `--check`, no prompts without a terminal, a question per step, and a done/skipped/failed summary.
- `scripts/install-apps.sh`: packages split into required, diagnostics, KDE apps, and developer groups, each confirmed separately; already-installed and unavailable packages are skipped.
- `scripts/restore-defaults.sh`: restores desktop settings, then moves (not deletes) InnyGrOS files into a dated backup.
- Welcome Center: helpers run without a terminal and log to `~/.cache/innygros/welcome-center.log`; failures show readable errors.
- Game readiness: up-to-date Roblox guidance (no official Linux client; Sober is unofficial and closed source; Windows remains the dependable option).

### Fixed
- A guessed GDLauncher Flatpak ID was removed; GDLauncher is found through its command, desktop entry, or AppImage.
- `apply-theme.sh` no longer makes a backup when the installed scheme is unchanged.

## 0.4 and earlier

- Konsole profile and color scheme with a desktop-safe installer.
- Game compatibility readiness report.
- GitHub Actions validation of shell syntax, the wallpaper SVG, and required files.
- Hand-authored SVG wallpaper with InnyGr and Team Blacklight branding.
- Graphical Welcome Center prototype (KDialog).
- Initial desktop starter: installer, KDE color scheme, performance diagnostics, documentation.
