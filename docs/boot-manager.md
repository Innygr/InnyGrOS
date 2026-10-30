# IntegerOS Boot Manager (experimental)

GRUB, not Bash, displays the operating-system menu before Linux starts. This helper adds a separate GRUB configuration drop-in and an optional systemd shutdown hook for Random Boot.

## Safe menu styling

The installer deliberately uses GRUB's native menu colors instead of activating a graphical theme. The previous prototype declared a `desktop-color` property without providing a GRUB-supported background image; this could produce a white or otherwise unexpected screen on some systems. The safe configuration sets a visible 8-second menu and high-contrast native colors, and does not set `GRUB_THEME`, change the firmware boot order, or replace the generated Kubuntu/Windows entries.

The graphical Deep Space theme remains deferred until it can be validated against the installed GRUB build and display hardware. No image is generated or downloaded by this feature.

## Preview and status

```bash
bash scripts/boot-manager.sh status
```

Review eligible top-level entries. Recovery, advanced-options, memtest, firmware and UEFI entries are excluded from Random Boot selection only; they remain in the normal GRUB menu.

## Install

```bash
sudo bash scripts/boot-manager.sh install
```

Type INSTALL when prompted. Random Boot is OFF by default and remains disabled after installation. Enable it with `sudo bash scripts/boot-manager.sh random-on`; disable it with `sudo bash scripts/boot-manager.sh random-off`. When enabled, normal shutdown/reboot selects a random eligible entry and uses `grub-reboot` to make it the one-time next boot. Existing menu entries are not intentionally removed.

## Test without rebooting

```bash
sudo bash scripts/boot-manager.sh choose-random
sudo grub-editenv /boot/grub/grubenv list
```

This changes the one-time next entry but does not reboot. Review entries first. The shutdown hook runs only when Random Boot is enabled.

## Uninstall

```bash
sudo bash scripts/boot-manager.sh uninstall
```

Type REMOVE. This removes only the IntegerOS drop-in and helper/service files, then regenerates GRUB. Keep a recovery path available.

## Limitations

- For Ubuntu/Kubuntu systems using GRUB; does not install GRUB or change UEFI boot order.
- Random Boot considers only top-level entries present in `/boot/grub/grub.cfg`. It cannot guarantee an OS entry boots successfully.
- The shutdown hook runs on normal systemd shutdown/reboot, not power loss or a forced reset.
- The native-color configuration is intentionally conservative. A graphical background and spaceship-style selector require a separately validated GRUB theme and compatible image asset; they are not enabled by this installer yet.
