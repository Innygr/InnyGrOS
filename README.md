# InnyGrOS

**InnyGrOS 0.4 — Desktop Edition**  
An Ubuntu-based desktop customization project built on Kubuntu + KDE Plasma.

> Early development: this repository is not yet a standalone operating system or installable ISO.

## Current features
- Guided setup script and optional developer-tool installer
- Dark violet/cyan KDE color scheme
- Original 1920×1080 vector wallpaper with InnyGr and Team Blacklight identity
- Custom Konsole profile with Fira Code, violet/cyan terminal colors, and scrollback
- Welcome Center for desktop settings, wallpaper, terminal setup, and read-only diagnostics
- Game-readiness report for Minecraft Java, Windows compatibility tools, graphics drivers, and Vulkan
- User-scoped configuration installation with timestamped backups for existing same-named Konsole files
- Conservative performance diagnostics and GitHub Actions validation

## Quick start on Kubuntu

From the repository root on Kubuntu:

```bash
chmod +x install.sh scripts/*.sh
./install.sh
```

The installer asks before installing packages, applying the color scheme, or installing the Welcome Center. The Welcome Center can install the wallpaper and Konsole profile, and run a read-only game-readiness report. The report checks tools and graphics diagnostics already available on the system; it does not install anything or change settings.

## Compatibility and safety
- Experimental Kubuntu + KDE Plasma customization, not a standalone ISO yet.
- Scripts need validation on real Kubuntu and Plasma versions.
- Package installation uses APT and asks for confirmation.
- Minecraft Java can run natively on Linux with a compatible launcher and Java runtime.
- Roblox is not reliably supported on Linux; keep Windows available for dependable access.
- Wine/Bottles/Steam detection is only a basic check, not a guarantee that any particular game will run.

## Roadmap
- [x] Initial scaffold, KDE color scheme, and performance diagnostics
- [x] Graphical Welcome Center prototype
- [x] Branded wallpaper and application helper
- [x] Konsole profile and color scheme
- [x] Game-readiness diagnostics
- [x] Basic GitHub Actions validation workflow
- [ ] Original logo and richer KDE desktop layout
- [ ] Automated tests and Kubuntu VM validation
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
