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

## Current state
- Guided setup script
- Optional developer-tool installer
- Dark violet/cyan KDE color scheme
- Conservative performance diagnostics
- Restore helper for the project-owned color scheme

Not implemented yet: custom ISO/installer, Welcome Center GUI, custom wallpaper/logo/icons, login/boot branding, automated panel layout, or Windows compatibility layer.

## Development workflow
You can edit this repository on Windows. The `.sh` scripts are for Linux and do not run directly in ordinary PowerShell. Test in a Kubuntu virtual machine before applying to the ThinkPad.

On Kubuntu:
```bash
chmod +x install.sh scripts/*.sh
./install.sh
```

The installer asks before installing packages or applying the color scheme. It does not repartition disks, alter boot settings, or replace system files.

## Base OS
Kubuntu + KDE Plasma. Check the [official Kubuntu download page](https://www.kubuntu.org/download/) for current images and release information.

## Safety and compatibility
- Back up important files before changing operating systems or partitions.
- If Windows device encryption/BitLocker is enabled, save the recovery key before changing boot or partition settings.
- Test Wi-Fi, sound, brightness, touchpad, suspend/resume, and battery reporting from a live USB.
- Minecraft Java can run natively on Linux with a compatible launcher and the correct Java runtime.
- Roblox is not reliably supported on Linux; keep Windows available for dependable access.
- Scripts are early-stage and have not yet been tested on the target ThinkPad.

## Roadmap
- [x] Initial project scaffold
- [x] KDE color scheme and application installer
- [x] Conservative performance diagnostics
- [ ] Original logo and wallpaper
- [ ] Welcome Center GUI
- [ ] Automated tests and CI
- [ ] Kubuntu VM validation
- [ ] ThinkPad T580 validation
- [ ] Reproducible ISO build

## Development principles
1. Prefer graphical tools for ordinary tasks.
2. Keep scripts readable, rerunnable, and narrowly scoped.
3. Ask before installing packages or changing settings.
4. Back up configuration before modifying it.
5. Never disable thermal protections or security services for vague performance claims.

## License
MIT. See [LICENSE](LICENSE).
