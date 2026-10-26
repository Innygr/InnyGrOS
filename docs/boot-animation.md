# Blacklight Matrix boot animation

The optional **Blacklight Matrix** Plymouth theme adds a black background, animated green code rain, InnyGrOS/Blacklight branding, and a progress indicator while Linux starts. It is separate from the GRUB Boot Manager and the KDE Plasma desktop splash.

## Preview repository contents

The theme is in `branding/boot/plymouth/`. The script uses Plymouth's native script plugin; it does not run the Python BLACKLIGHT MATRIX terminal app during early boot and does not access the network.

## Check current setup

From the repository root:

```bash
bash scripts/boot-animation.sh status
```

## Install

On Kubuntu/Ubuntu with Plymouth and the script theme plugin already installed:

```bash
sudo bash scripts/boot-animation.sh install
```

Read the prompt and type `INSTALL`. The helper saves the previously selected theme, installs Blacklight Matrix under `/usr/share/plymouth/themes/blacklight`, selects it with `update-alternatives`, and rebuilds the initramfs. The animation is used on the next boot.

This changes system boot files. Do not install it on a machine you cannot recover or before checking that you can reach GRUB/recovery. The script refuses to overwrite an existing backup and does not alter GRUB menu entries, disk partitions, or UEFI boot order.

## Restore the previous theme

```bash
sudo bash scripts/boot-animation.sh uninstall
```

Type `REMOVE` when prompted. The helper restores the saved previous theme and rebuilds initramfs. If the previous theme file has been removed, it stops rather than guessing.

## Limitations

- This is an experimental theme; visual and boot testing on real ThinkPad T580 hardware is still required.
- Plymouth support and the script plugin must be installed by the base Kubuntu system.
- Firmware/ThinkPad logos before Linux starts are controlled by firmware and are not replaced by this theme.
- The progress bar reflects Plymouth's reported boot progress; it is not a precise measure of every service.
- GRUB's menu theme remains separately managed by [the experimental Boot Manager](boot-manager.md).
