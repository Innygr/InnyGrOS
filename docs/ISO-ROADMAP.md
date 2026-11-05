# InntegerOS ISO Roadmap

**Target:** a tested bootable InntegerOS image and installation path during December 2026–January 2027.  
**Relationship to 1.0:** the November 14 desktop edition remains a separate milestone. The installable distribution is a larger deliverable and will not be called release-ready until it passes the checks below.

## Product direction

InntegerOS is intended to become an independently developed Linux distribution—not a Kubuntu respin with a new logo and wallpaper.

The project will build its own integrated desktop experience, system identity, Control Center, first-run flow, package/configuration manifest, update and recovery experience, live image, and installation workflow. It may reuse upstream components such as the Linux kernel, Ubuntu package infrastructure, and KDE Plasma. Reusing components is good engineering; outsourcing the entire product identity and experience to another distribution is not the goal.

Kubuntu 26.04.1 is a useful reference environment and possible technical starting point, not a permanently decided product base. The base release, image-building method, and installer engine must be evaluated and documented before the first image is frozen.

## Milestones

- **Nov 15–21 — architecture and image proof of concept:** define which parts InntegerOS owns, compare supported bases and build tooling, document package/licensing requirements, and produce a minimal repeatable live-image build.
- **Nov 22–26 — InntegerOS live session:** boot the image in a VM; test the InntegerOS desktop identity, networking, display scaling, audio, first-run flow, and offline usability.
- **Nov 27–30 — installation gate:** evaluate a proven installer backend and integrate an InntegerOS-branded workflow. Test clean-disk and manual installation in disposable VMs. Test alongside installation only when it can be safely validated. Otherwise, keep the image as a non-installing preview.
- **December–January — hardware and release testing:** test on spare hardware, then assess the ThinkPad T580 without touching its existing Windows/Kubuntu installation. Verify checksums, update/recovery behaviour, documentation, and known limitations before publishing.

## Release gates

1. The build is repeatable from repository-controlled configuration.
2. The image boots in a clean virtual machine and reaches the InntegerOS desktop without requiring internet access for first boot.
3. InntegerOS owns the visible system identity, desktop defaults, first-run experience, and core integration.
4. Upstream notices, licences, and trademarks are handled correctly; the image does not imply official Kubuntu endorsement.
5. No credentials, personal files, machine-specific configuration, or private keys are baked into the image.
6. The installer is tested in disposable VMs and never silently partitions a disk.
7. Updates and basic recovery procedures are documented.
8. The published image has a checksum and clear hardware/support notes.

## Scope boundaries

- The November 14 **1.0 desktop edition** is not dependent on the installable distribution being ready.
- The first prototype should prioritize a reliable live system and safe installation over a custom partitioning engine.
- Do not test installation on the user's daily-use dual-boot laptop until the image has passed VM testing and a separate backup/recovery plan is confirmed.
- If installation testing is not complete by the end of November, December's deliverable can be a live-image preview rather than an unsafe or untested installer.

## Current status — November 5, 2026

**Stage: architecture preparation; no ISO build proof-of-concept yet.** The repository contains the desktop customization project and design documents, but no `iso/` build configuration, image-generation script, live image artifact, or VM boot-test report. The build-system milestone has not started.

The next concrete deliverable is a documented base/tooling decision and a reproducible InntegerOS live-image proof of concept. Only after that image exists can live-session and installer testing begin.

## Installation architecture

The product identity, base-system strategy, installer requirements, and safety gates are documented in [Installation Design](INSTALLATION-DESIGN.md).

## 0.8 image-viewer track

In parallel with ISO planning, 0.8 targets a broad-format image-viewing experience, including animated formats. See [Image Viewer Compatibility](IMAGE-VIEWER.md) for scope and test gates. The image should include the tested viewer setup, but the build is not blocked on supporting every obscure format.
