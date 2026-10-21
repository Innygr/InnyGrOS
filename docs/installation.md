# Installation and test plan

1. Develop and review this repository on Windows.
2. Test in a Kubuntu virtual machine and snapshot it before changes.
3. Record package and Plasma-version differences.
4. Before changing the ThinkPad, back up important files and save the Windows device-encryption/BitLocker recovery key if enabled.
5. Test Kubuntu from a live USB: Wi-Fi, sound, brightness keys, touchpad, suspend/resume, battery, and external displays.
6. Only decide on dual boot after backups and recovery media are ready.

## Applying the starter

```bash
./install.sh --check   # report whether this system is supported; changes nothing
./install.sh           # guided setup
```

(If the scripts lost their executable bit, for example after copying from Windows, run `bash install.sh`.)

Setup checks the distribution (Ubuntu-based required, Kubuntu with KDE Plasma recommended), then asks before each step:

1. **Packages** (default: no). `scripts/install-apps.sh` offers each group separately and skips packages that are already installed or not available on your release:
   - `required`: kdialog, Fira Code font, KDE config tools; needed by the Welcome Center and desktop profile
   - `diagnostics`: pciutils, mesa-utils, vulkan-tools; used by the readiness and performance reports
   - `kde-apps`: Dolphin, Konsole, Kate, Discover, System Monitor
   - `developer`: optional compilers, Python, Node.js, and similar tools

   Use `./scripts/install-apps.sh --list` to see what would be installed. Steam, Wine, Bottles, and graphics drivers are never installed automatically.
2. **Welcome Center**, installed into your home folder.
3. **Desktop profile**: saves a snapshot, then applies colors, wallpaper, and optional animation and Konsole settings.

If a step fails, setup stops to ask whether to continue, and the summary at the end lists what was done, skipped, and failed. Running setup again is safe: files are reinstalled in place, and each desktop profile apply takes a new snapshot.

To undo anything, see [recovery.md](recovery.md).

The starter targets Kubuntu/Ubuntu with APT and has not yet been tested on the target ThinkPad. See https://www.kubuntu.org/download/ for official release images and notes.
