# InnyGrOS Boot Manager (experimental)

GRUB, not Bash, is the component that runs before Linux and displays the OS menu. This helper customizes Ubuntu/Kubuntu GRUB and adds an optional shutdown hook for Random Boot.

## Preview

```bash
bash scripts/boot-manager.sh status
```

Review eligible top-level entries. Recovery, advanced-options, memtest, firmware and UEFI entries are excluded by title/ID pattern.

## Install

```bash
sudo bash scripts/boot-manager.sh install
```

Type INSTALL when prompted. The script adds a separate file under /etc/default/grub.d, a high-contrast violet/cyan GRUB theme using a solid dark fallback background and GRUB's default font (no external wallpaper or optional font dependency), and a systemd shutdown hook. Random Boot is OFF by default and remains disabled after installation. Enable the mode with `sudo bash scripts/boot-manager.sh random-on`; disable it with `sudo bash scripts/boot-manager.sh random-off`. When enabled, normal shutdown/reboot selects a random eligible entry and uses grub-reboot to make it the one-time next boot. Existing menu entries are not intentionally removed.

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

Type REMOVE. Keep a recovery path available. This experimental feature has not been validated on the user's laptop; test the actual GRUB theme and menu before relying on it.

## Limitations

- For Ubuntu/Kubuntu systems using GRUB; does not install GRUB or change UEFI boot order.
- Random Boot considers only top-level entries present in /boot/grub/grub.cfg. It cannot guarantee an OS entry boots successfully.
- The shutdown hook runs on normal systemd shutdown/reboot, not power loss or a forced reset.
- The theme intentionally avoids external background images and named font dependencies for compatibility. GRUB's theme parser and graphical mode still vary by firmware and GRUB build; test before relying on it.
