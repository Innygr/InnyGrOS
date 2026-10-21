# Compatibility notes

## Minecraft Java
Minecraft Java can run natively on Linux. Use a Linux-compatible launcher and the Java runtime required by the selected Minecraft version or modloader.

## Minecraft launchers

| Launcher | How to install | Detected by InnyGrOS as |
| --- | --- | --- |
| GDLauncher (preferred) | AppImage, `.deb`, or `.rpm` from [gdlauncher.com](https://gdlauncher.com/docs/installation). It is not on Flathub. | `gdlauncher` command, a desktop entry, or `GDLauncher*.AppImage` in `~/Applications`, `~/.local/bin`, `~/Downloads`, or `~` |
| Prism Launcher | Discover / Flathub `org.prismlauncher.PrismLauncher` | command or Flatpak |
| Official Minecraft Launcher | Mojang's `.deb`, or the community-maintained, unverified Flathub package `com.mojang.Minecraft` | command or Flatpak |

## Roblox

Checked October 2026. Re-check before relying on it, because this changes often.

- Roblox has **no official Linux client**. Roblox's Hyperion anti-cheat intentionally stops the Windows Roblox Player from working under Wine/Proton, so Wine, Bottles, and Steam are **not** a route for playing Roblox.
- **Sober** ([Flathub `org.vinegarhq.Sober`](https://flathub.org/apps/org.vinegarhq.Sober)) is the commonly used option. It is an unofficial, closed-source client from VinegarHQ that runs the Android version of Roblox natively on x86_64 Linux. It is not affiliated with Roblox, describes itself as a research project to use at your own risk, and could stop working whenever Roblox changes.
- **Roblox Studio** has no Hyperion and can run through [Vinegar](https://flathub.org/apps/org.vinegarhq.Vinegar) (open source, Flathub `org.vinegarhq.Vinegar`). This is also unofficial.
- InnyGrOS only **detects** Sober and Vinegar in the game-readiness report; it never installs them.
- Keep Windows available for dependable Roblox access.

## Windows applications

Wine, Proton (through Steam), and Bottles work for some Windows applications and games, but compatibility depends on each application and can change with updates. Test each application individually. InnyGrOS detects these tools but does not install them automatically.

## ThinkPad T580
Confirm the exact hardware before tuning it. Test Wi-Fi, audio, suspend/resume, brightness, touchpad, battery reporting, and external displays before considering the setup ready.

Run `scripts/hardware-check.sh` (or **Laptop hardware check** in the Welcome Center) from a live USB first, and follow [thinkpad-t580-test-plan.md](thinkpad-t580-test-plan.md). No ThinkPad results have been recorded yet.
