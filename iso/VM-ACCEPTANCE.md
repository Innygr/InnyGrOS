# InntegerOS disposable VM acceptance checklist

**Status:** test plan only. No live image or installer has passed these tests yet.

Use disposable virtual machines and virtual disks. Never use the developer's daily-use dual-boot ThinkPad for destructive installation tests.

## Test record

For every run, record:

- date/time (UTC), tester, source commit, image SHA-256;
- InntegerOS version, edition, architecture, and package metadata reference;
- hypervisor and version, firmware mode, vCPU/RAM, virtual disk size;
- exact test steps, observed result, logs/screenshots, and defects;
- one of: **PASS**, **FAIL**, **BLOCKED**, or **NOT RUN**.

A skipped or unrecorded test is not a pass.

## Gate 1 — boot media and live session

- [ ] ISO checksum matches the published SHA256SUMS.
- [ ] VM boots using UEFI firmware.
- [ ] Boot menu identifies InntegerOS and the selected edition.
- [ ] Live session reaches the desktop without installing to a disk.
- [ ] No internal or virtual disk is modified merely by entering the live session.
- [ ] Display resolution and scaling are usable.
- [ ] Keyboard, pointer, audio, and virtual network work.
- [ ] Network can be disabled and the desktop remains usable offline.
- [ ] InntegerOS Control Center opens and accurately identifies the live environment.
- [ ] No developer home-directory content, account tokens, SSH keys, Wi-Fi credentials, or machine-specific state is present.
- [ ] Shutdown and reboot complete without hanging.

## Gate 2 — first-run and shared system experience

- [ ] First-run onboarding can be skipped and resumed.
- [ ] Defaults are applied only after clear user consent.
- [ ] Optional application bundles are not installed by default.
- [ ] Update UI distinguishes InntegerOS updates from upstream APT updates.
- [ ] Update checks explain offline/unavailable repository states.
- [ ] Diagnostics work without requiring optional tools; missing tools are reported.
- [ ] Recovery documentation is accessible from the live environment.
- [ ] Accessibility basics: keyboard navigation, readable contrast, scalable text, and clear focus indicators.

## Gate 3 — installation in disposable VMs

Do not begin until Gate 1 passes.

- [ ] Installer clearly identifies the target virtual disk by model and size.
- [ ] No disk write occurs before the final destructive-action confirmation.
- [ ] Clean-disk installation completes and boots.
- [ ] Manual partitioning is tested only with disposable virtual disks.
- [ ] Alongside-install is tested only with a disposable VM containing a second OS.
- [ ] Unsupported layouts fail safely with an actionable explanation.
- [ ] User creation, bootloader setup, networking, and first boot succeed.
- [ ] Installed edition and release identity are correct.
- [ ] User settings survive reboot and an ordinary package update.
- [ ] Recovery procedure is tested.

## Gate 4 — upgrade and regression

- [ ] A later prototype upgrades from the previous supported prototype.
- [ ] User data and personal settings remain intact.
- [ ] Failed/interrupted update recovery is documented and tested.
- [ ] Package manifest and installed package inventory are captured.
- [ ] All previously passing tests are rerun against the exact new image.

## Release decision

Publish the test record with the image metadata. Do not describe an edition as supported or an image as installable while any required gate is FAIL, BLOCKED, or NOT RUN.
