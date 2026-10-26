# InnyGrOS ISO Roadmap

**Target:** a tested bootable InnyGrOS ISO or equivalent during December 2026–January 2027  
**Relationship to 1.0:** the November 14 desktop edition remains the stable customization project. The ISO is a separate deliverable and will not be called release-ready until it passes the checks below.

## Recommended approach

Build on a supported Kubuntu/Ubuntu base with KDE Plasma and layer InnyGrOS branding, Welcome Center, setup helpers, and safe defaults on top. Do not build a Linux distribution or installer from scratch.

The first image should be a **live USB image** that boots into an InnyGrOS-branded desktop. Installation to disk is a second gate: preserve the user's ability to choose a target disk, clearly warn before partition changes, and test the installer in a virtual machine before trying it on physical hardware.

Prefer a reproducible, documented build process over a one-off manually modified ISO. Choose the exact base release and image-building method after verifying current support status, redistribution requirements, and whether the chosen tooling can produce a reliable live session and installer.

## Milestones

- **Nov 15–21 — image build proof of concept:** select the supported base, document prerequisites, automate branding/package configuration, and produce a bootable test image.
- **Nov 22–26 — live session:** test booting in a VM, desktop branding, networking, display scaling, user session startup, and Welcome Center.
- **Nov 27–30 — installation gate:** if the live image is stable, test installation in a VM, reboot, updates, and recovery. Otherwise, release the live image only as an explicitly non-installing preview.
- **December–January — hardware and release testing:** test on the ThinkPad T580 without touching its existing Windows/Kubuntu installation, verify checksums, publish known limitations and recovery instructions, and only then publish the image. January is the fallback window if live-session, installer, or hardware checks need more time.

## Release gates

1. The build can be repeated from documented steps.
2. The image boots in a clean virtual machine and reaches the desktop without network access being required for first boot.
3. InnyGrOS branding and Welcome Center work in the live session.
4. No credentials, personal files, machine-specific configuration, or private keys are baked into the image.
5. The installer, if included, is tested in a disposable VM and never silently partitions a disk.
6. Updates and basic recovery procedures are documented.
7. The published image has a checksum and clear hardware/support notes.

## Scope boundaries

- The November 14 **1.0 desktop edition** is not dependent on the ISO being ready.
- The initial image should prioritize reliability and a clean live session over an elaborate custom installer.
- Do not test installation on the user's daily-use dual-boot laptop until the image has passed VM testing and a separate backup/recovery plan is confirmed.
- If installation testing is not complete by the end of November, December's deliverable can be a live ISO preview rather than an unsafe or untested installer.

## Current status

Planning only. This document does not claim that an ISO has been built or tested yet.

## 0.8 image-viewer track

In parallel with ISO planning, 0.8 targets a broad-format image-viewing experience, including animated formats. See [Image Viewer Compatibility](IMAGE-VIEWER.md) for scope and test gates. The ISO should include the same tested viewer setup, but the image build is not blocked on supporting every obscure format.
