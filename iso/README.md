# InntegerOS ISO Build Area

**Status:** scaffold only — no build configuration or build script yet.

This directory will hold repository-controlled image configuration for the first InntegerOS live-image prototype.

## First target

- Architecture: x86_64 / amd64
- Desktop profile: Plasma
- Base candidate: Ubuntu 26.04 (Resolute), pending evaluation
- Image type: bootable live image with a safe preview mode
- Installer: not selected; must be evaluated separately and must never silently modify disks

## Planned layout

- `manifests/` — explicit base and edition package lists
- `profiles/` — desktop-specific package and configuration profiles
- `hooks/` — narrowly scoped image customizations
- `config/` — boot, live-session, and image metadata
- `build/` — generated output only; never commit large generated ISOs

## Build safety

- Builds must run in a disposable VM or dedicated build environment, not by modifying the user's daily-use installation.
- The live preview must not write to internal disks.
- No personal home-directory content, account credentials, SSH keys, browser profiles, Wi-Fi credentials, cloud tokens, or machine-specific state may enter the image.
- Package manifests and build logs must be retained for each prototype.
- Publish a checksum for every image artifact.
- Do not advertise installation or dual-boot support until the installer passes disposable-VM tests.

## Current gate

The next task is a minimal reproducible rootfs/live-image experiment. See [Image-Build Tool Evaluation](../docs/IMAGE-BUILD-TOOLS.md) and [ISO Roadmap](../docs/ISO-ROADMAP.md).
