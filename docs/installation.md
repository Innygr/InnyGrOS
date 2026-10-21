# Installation and test plan

1. Develop and review this repository on Windows.
2. Test in a Kubuntu virtual machine and snapshot it before changes.
3. Record package and Plasma-version differences.
4. Before changing the ThinkPad, back up important files and save the Windows device-encryption/BitLocker recovery key if enabled.
5. Test Kubuntu from a live USB: Wi-Fi, sound, brightness keys, touchpad, suspend/resume, battery, and external displays.
6. Only decide on dual boot after backups and recovery media are ready.

## Applying the starter

```bash
chmod +x install.sh scripts/*.sh
./install.sh
```

Review the package list before accepting. You can decline package installation and apply only the color scheme.

The starter targets Kubuntu/Ubuntu with APT and has not yet been tested on the target ThinkPad. See https://www.kubuntu.org/download/ for official release images and notes.
