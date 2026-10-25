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

Type INSTALL when prompted. The script adds a separate file under /etc/default/grub.d, a violet/cyan GRUB theme, and a systemd service. On normal shutdown/reboot the service chooses a random eligible entry and uses grub-reboot to make it the one-time next boot. Existing menu entries are not intentionally removed.

## Test without rebooting

```bash
sudo bash scripts/boot-manager.sh choose-random
sudo grub-editenv /boot/grub/grubenv list
```

This changes the one-time next entry but does not reboot. Review entries first.

## Uninstall

```bash
sudo bash scripts/boot-manager.sh uninstall
```

Type REMOVE. Keep a recovery path available. This experimental feature has not been validated on the user's laptop; test the actual GRUB theme and menu before relying on it.

## Limitations

- For Ubuntu/Kubuntu systems using GRUB; does not install GRUB or change UEFI boot order.
- Random Boot considers only top-level entries present in /boot/grub/grub.cfg. It cannot guarantee an OS entry boots successfully.
- The shutdown hook runs on normal systemd shutdown/reboot, not power loss or a forced reset.
- The theme relies on the installed GRUB build's supported fonts and theme parser.
