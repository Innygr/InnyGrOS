# InnyGrOS

**InnyGrOS 0.6 — Desktop Edition**  
An Ubuntu-based desktop customization project built on Kubuntu + KDE Plasma.

> Early development: this repository is not yet a standalone operating system or installable ISO.

## Current features
- Guided setup script and optional developer-tool installer
- Dark violet/cyan KDE color scheme
- Original 1920×1080 vector wallpaper with InnyGr and Team Blacklight identity
- Custom Konsole profile with Fira Code, violet/cyan terminal colors, and scrollback
- Welcome Center for desktop settings, wallpaper, terminal setup, and read-only diagnostics
- Reversible KDE desktop profile (colors, wallpaper, animation speed, default Konsole profile, optional InnyGrOS startup splash) with snapshots and one-click restore
- Read-only performance snapshot (boot time, memory, power, battery, graphics, rough CPU timing) with optional saved reports for before/after comparison
- Power mode switcher (power saver / balanced / performance) using the standard power-profiles interface, and an optional "show Welcome Center at login" setting
- Read-only laptop hardware check (Wi-Fi, Bluetooth, audio, backlight, touchpad/TrackPoint, batteries, suspend mode, thermals) plus a ThinkPad T580 test plan
- Read-only network report for NetworkManager, IP addresses, default route, DNS, nearby Wi-Fi metadata, and detected VPN/overlay interfaces (including Tailscale and WireGuard when installed), plus a quick connectivity/Tailscale health check in the Welcome Center
- Read-only battery and power report for battery status, estimated design-capacity remaining when exposed by firmware, power profile, and optional temperature sensor output; available from the Welcome Center
- Game-readiness report for Minecraft Java, Windows compatibility tools, graphics drivers, and Vulkan
- Experimental GRUB Boot Manager with violet/cyan styling, OS-entry preview, and optional Random Boot on normal shutdown/reboot ([docs](docs/boot-manager.md))
- User-scoped configuration installation with timestamped backups for existing same-named Konsole files
- Conservative performance diagnostics and GitHub Actions validation

## Quick start on Kubuntu

From the repository root on Kubuntu:

```bash
chmod +x install.sh scripts/*.sh
./install.sh --check   # optional: see whether this system is supported
./install.sh
```

To undo InnyGrOS changes, run `./scripts/restore-defaults.sh` or see [docs/recovery.md](docs/recovery.md).

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

## InnyGrOS Boot Manager (experimental)

Preview your existing GRUB entries with `bash scripts/boot-manager.sh status`. To install the optional GRUB theme and Random Boot shutdown hook, use `sudo bash scripts/boot-manager.sh install` and type `INSTALL` when prompted. Random Boot is off by default; enable it with `sudo bash scripts/boot-manager.sh random-on` and disable it with `sudo bash scripts/boot-manager.sh random-off`. Read [docs/boot-manager.md](docs/boot-manager.md) first. This changes system boot configuration, has not been validated on the laptop, and should only be enabled after reviewing the detected entries and confirming a recovery path.

## Compatibility and safety
- Experimental Kubuntu + KDE Plasma customization, not a standalone ISO yet.
- Scripts need validation on real Kubuntu and Plasma versions.
- Package installation uses APT and asks for confirmation.
- Minecraft Java can run natively on Linux with a compatible launcher and Java runtime.
- Roblox has no official Linux client. The unofficial Sober client (Flathub) is detected but never installed; keep Windows available for dependable access. See [docs/compatibility.md](docs/compatibility.md).
- Wine/Bottles/Steam detection is only a basic check, not a guarantee that any particular game will run.

## Roadmap
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
MIT. See [LICENSE](LICENSE).
