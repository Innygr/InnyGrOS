# InnyGrOS

**InnyGrOS 0.1 — Desktop Edition**  
An Ubuntu-based desktop customization project built on Kubuntu + KDE Plasma.

> Early development: this repository is not yet a standalone operating system or installable ISO.

## Goals
- Futuristic, customizable desktop identity
- Developer-friendly setup
- Graphical controls for everyday tasks
- Sensible, measurable performance improvements
- A future Welcome Center and eventually a reproducible ISO

## Current features
- Guided setup script
- Optional developer-tool installer
- Dark violet/cyan KDE color scheme
- Conservative, read-only performance diagnostics
- Graphical Welcome Center prototype using KDE dialogs
- User-scoped desktop launcher for the Welcome Center
- Restore helper for the project-owned color scheme

## Quick start on Kubuntu

You can edit the repository on Windows. The `.sh` scripts target Linux and do not run directly in ordinary PowerShell. On Kubuntu, from the repository root:

```bash
chmod +x install.sh scripts/*.sh
./install.sh
```

The installer asks before installing packages, applying the color scheme, or installing the Welcome Center. The Welcome Center offers shortcuts to System Settings, Discover, Dolphin, a theme action, and read-only diagnostics. It uses `kdialog` and KDE applications.

## Base OS
Kubuntu + KDE Plasma. Check the [official Kubuntu download page](https://www.kubuntu.org/download/) for current images and release information.

## Safety and compatibility
- This is an experimental machine/project; expect to test, iterate, and occasionally reinstall.
- Scripts are still early-stage and need testing on a real Kubuntu system.
- Package installation uses APT and asks for confirmation.
- The Welcome Center is user-scoped and does not change privileged system settings itself.
- Minecraft Java can run natively on Linux with a compatible launcher and the correct Java runtime.
- Roblox is not reliably supported on Linux; keep Windows available for dependable access.

## Roadmap
- [x] Initial project scaffold
- [x] KDE color scheme and application installer
- [x] Conservative performance diagnostics
- [x] First graphical Welcome Center prototype
- [ ] Original logo and wallpaper
- [ ] Richer KDE desktop layout and visual customization
- [ ] Welcome Center native application
- [ ] Automated tests and CI
- [ ] Kubuntu VM validation
- [ ] ThinkPad T580 validation
- [ ] Reproducible ISO build

## Development principles
1. Prefer graphical tools for ordinary tasks.
2. Keep scripts readable, rerunnable, and narrowly scoped.
3. Ask before installing packages or changing settings.
4. Back up configuration before modifying it.
5. Measure performance rather than promising arbitrary speed gains.

## License
MIT. See [LICENSE](LICENSE).
