# InntegerOS Installation Design

**Status:** preparation / architecture proposal  
**Target base:** Kubuntu 26.04.1 LTS (AMD64), subject to a fresh support and image verification before each build  
**Goal:** turn the existing InntegerOS desktop project into a reproducible live image that can also perform a normal, user-confirmed installation.

## 1. Product model

InntegerOS should be a branded, installable Kubuntu-based operating system—not a custom Linux kernel or a replacement package ecosystem.

The first release should reuse the supported Kubuntu base, KDE Plasma, Ubuntu package repositories, and the installer already shipped by the chosen Kubuntu image. Avoid writing a partitioner or bootloader installer from scratch.

The live environment and installed system must both be useful:
- **Try InntegerOS:** boot to a working Plasma desktop without changing internal disks.
- **Install InntegerOS:** launch the existing distribution installer from the live desktop.
- **First boot:** finish normal account/session setup, then open the InntegerOS Control Center or first-run Welcome Center.

## 2. Base-image decision

Kubuntu 26.04.1 LTS is the leading candidate because it matches the project's current Kubuntu 26.04.1 / Plasma 6 development environment and has an AMD64 desktop live image. Kubuntu currently lists security and maintenance support through April 2029.

Before freezing the base, record:
- exact ISO filename, release date, architecture, and SHA-256;
- package manifest and installer package/version;
- kernel, Plasma, Qt, and graphics stack versions;
- redistribution and trademark/attribution requirements;
- current support status and known installer regressions.

Do not silently switch to a different Ubuntu flavour or release during an image build.

## 3. Installer strategy

**Initial preference: retain Kubuntu's own graphical installer.** The Kubuntu 26.04.1 image is reported to include Calamares packages; verify the actual downloaded ISO manifest and boot behaviour before depending on that. Keep the upstream installer and its partitioning modules as intact as possible for the first proof of concept.

InntegerOS-specific work should initially be limited to:
- product name, logo, artwork, and live-session defaults;
- installing the InntegerOS package/application set into the live image;
- ensuring the same package set and defaults are present after installation;
- a first-boot welcome flow that does not require network access.

Do not create a custom partitioning module until the standard installer has been tested thoroughly and a concrete limitation requires it.

## 4. Required installation behaviour

The installer must:
- clearly identify the selected target disk and show its size/model;
- require an explicit final confirmation immediately before destructive disk changes;
- never silently erase, repartition, format, or overwrite a disk;
- make erase-disk, alongside-existing-OS, and manual partitioning choices clear where supported;
- preserve existing EFI boot entries and other operating systems when an alongside option is selected;
- explain encryption and recovery-key consequences before enabling encryption;
- stop safely and explain the problem if storage layout or boot mode is unsupported;
- avoid writing to internal disks during the live-session preview.

If safe alongside installation cannot be verified, disable or defer that option rather than claiming it works.

## 5. First-boot experience

The installed system should:
1. complete the installer-created user's first login;
2. start Plasma with InntegerOS branding and sane defaults;
3. launch the InntegerOS Control Center / first-run welcome flow;
4. offer optional setup tasks individually, with clear descriptions;
5. allow setup to be skipped and resumed later;
6. avoid requiring an internet connection for the desktop to become usable.

No personal account, home directory, SSH key, Wi-Fi password, Tailscale identity, browser profile, OneDrive token, or machine-specific configuration may be included in the image.

## 6. Image composition

Create a declarative package and configuration manifest rather than copying a developer's home directory. Separate the image into:
- **Base:** Kubuntu packages and dependencies;
- **InntegerOS core:** Control Center, branding, first-run flow, update/recovery helpers;
- **Optional bundles:** development tools, creative tools, and gaming support;
- **Hardware-specific additions:** only when justified and documented.

Avoid automatically installing large or proprietary game launchers, personal applications, or optional developer stacks in the base image. Offer them after installation instead.

## 7. Build and test gates

### Gate A — inspect the upstream image
- Download the official Kubuntu 26.04.1 AMD64 desktop ISO.
- Verify its published checksum and signature where available.
- Inspect its package manifest and installer version.
- Boot the unmodified image in a disposable VM.

### Gate B — InntegerOS live-image proof of concept
- Build from a documented, repeatable configuration.
- Add InntegerOS branding and required applications.
- Boot to the live desktop in a VM.
- Verify networking, display scaling, audio, session startup, Control Center, and offline first use.
- Confirm no personal data or secrets are present.

### Gate C — installation in a disposable VM
- Test a clean-disk installation.
- Test manual partitioning using only disposable virtual disks.
- Test alongside-install behaviour only with a disposable VM containing a second operating system.
- Reboot into the installed system; verify users, bootloader, updates, networking, and recovery.
- Record screenshots, logs, package versions, and test results.

### Gate D — physical hardware
Only after all VM gates pass, test on spare hardware. The ThinkPad T580 is a later compatibility target, not the first installer test machine. Its existing Windows/Kubuntu layout must not be used for destructive installer experiments.

## 8. Current blockers

- No ISO build configuration or reproducible image-generation script exists yet.
- The exact Kubuntu installer package/version must be confirmed from the downloaded image.
- No live-image VM test has been completed.
- No installation, dual-boot, recovery, or post-install test has been completed.
- Package selection and first-boot behaviour still need to be made declarative.

## 9. Immediate next tasks

1. Add an `iso/` project area for build configuration, package manifests, and image metadata.
2. Obtain and verify the official Kubuntu 26.04.1 AMD64 image.
3. Inspect the live image and installer before modifying it.
4. Create the smallest reproducible InntegerOS live-image build.
5. Keep installation testing separate until the live image is stable.
