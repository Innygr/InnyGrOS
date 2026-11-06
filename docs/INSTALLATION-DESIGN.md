# InntegerOS Installation Design

**Status:** architecture proposal / preparation  
**Product goal:** an independently developed Linux distribution with its own identity, system experience, integration, release process, and installation flow.  
**Initial technical strategy:** reuse proven Linux components and Ubuntu package infrastructure where useful; do not present an unchanged Kubuntu respin as the finished product.

## 1. Product identity: InntegerOS is the product

InntegerOS must not be merely Kubuntu with a different wallpaper, logo, or colour scheme. Upstream projects are engineering foundations, not the product identity.

The distribution should own and maintain:
- its system identity, artwork, boot experience, defaults, and release branding;
- its Control Center and first-run onboarding;
- its package selection, integration layer, configuration defaults, and system utilities;
- its update, recovery, diagnostics, and hardware-compatibility experience;
- its live environment, installation experience, release images, documentation, and support policy.

The project can use the Linux kernel, Ubuntu repositories, KDE Plasma, and other upstream components while still building a distinct operating system. The distinction must come from real integration and maintained components—not just rebranding.

## 2. Desktop and system architecture

**Initial desktop direction:** KDE Plasma, customized and integrated as the InntegerOS desktop.

Plasma is a desktop environment component, not the operating system's identity. InntegerOS should progressively own the desktop experience around it:
- a coherent InntegerOS session and default workspace;
- native-feeling settings and Control Center integration;
- consistent boot, login, lock, notifications, application and update experiences;
- first-party tools that work together rather than a collection of unrelated scripts;
- documented configuration and supported hardware behaviour.

Do not fork Plasma immediately just to claim independence. Prefer upstream-compatible extensions and maintained InntegerOS components. A deeper desktop-shell fork or replacement should be considered only if a concrete product requirement justifies its long-term maintenance cost.

## 3. Desktop editions

InntegerOS should offer multiple desktop experiences over one shared operating-system foundation. The flagship is **Plasma Edition**, with **GNOME Edition** as the first alternative and **Xfce Edition** as a lightweight alternative. Each edition needs its own desktop profile, native settings integration, package selection, and VM test coverage.

The installer should select one desktop profile, defaulting to Plasma. Do not install all desktop environments together by default. The shared Control Center core, first-run flow, updater, recovery tools, system identity, and security policy must work consistently across editions; desktop-specific settings and dependencies must remain isolated.

**InntegerOS: Complete Edition** is the long-term vision for the fully integrated product, eventually including an InntegerOS-designed desktop environment. It is not a current edition or a promise to replace Plasma immediately. Build the shared system first, then prototype native desktop components only where clear product requirements justify the maintenance cost.

See [Desktop Editions](DESKTOP-EDITIONS.md) for the full edition architecture, Complete Edition vision, and release gates.

## 4. Base system strategy

For the first installable prototype, use Ubuntu package infrastructure as a possible foundation while creating an InntegerOS-controlled image and integration layer. Kubuntu 26.04.1 is a candidate reference environment because the current desktop project is developed on it; it is not a final product-identity decision and must not be assumed to be the permanent base.

Before selecting and freezing the base, compare supported Ubuntu/Kubuntu routes and image-building methods. Record:
- exact release, ISO filename, architecture, date, and SHA-256;
- package manifest, installer and boot stack versions;
- kernel, Plasma, Qt, graphics and firmware components;
- security-support lifecycle and update policy;
- redistribution, trademark, attribution, and licensing requirements;
- which components InntegerOS will maintain itself and which remain upstream.

Do not ship upstream Kubuntu branding or imply that InntegerOS is an official Kubuntu release. Preserve required notices and attribution.

## 4. Live image and installer strategy

The first deliverable is an **InntegerOS live image** that boots directly into the InntegerOS experience. It should offer:
- **Try InntegerOS:** a usable live desktop that does not alter internal disks;
- **Install InntegerOS:** a clearly identified installation path;
- **First boot:** the installed system starts the InntegerOS first-run experience.

For the first prototype, reusing a proven installer engine is sensible; it does not require accepting the upstream distribution's complete installer branding or workflow as the final InntegerOS experience. Evaluate installer engines and customization options before choosing. Build an InntegerOS installer frontend/branding and safe workflow over a proven backend where practical. Do not write a partitioner, filesystem manager, or bootloader installer from scratch.

The installer must:
- clearly identify the selected target disk and show its size/model;
- require explicit final confirmation immediately before destructive disk changes;
- never silently erase, repartition, format, or overwrite a disk;
- make erase-disk, alongside-existing-OS, and manual partitioning choices clear where supported;
- preserve existing EFI boot entries and other operating systems when an alongside option is selected;
- explain encryption and recovery-key consequences before enabling encryption;
- stop safely and explain the problem if storage layout or boot mode is unsupported;
- avoid writing to internal disks during the live-session preview.

If safe alongside installation cannot be verified, disable or defer that option rather than claiming it works.

## 6. First-boot experience

The installed system should:
1. complete the account creation and system setup selected during installation;
2. start the InntegerOS desktop session with its own branding and defaults;
3. launch InntegerOS first-run onboarding / Control Center;
4. offer optional setup tasks individually, with clear descriptions;
5. allow setup to be skipped and resumed later;
6. avoid requiring an internet connection for the desktop to become usable.

No personal account, home directory, SSH key, Wi-Fi password, Tailscale identity, browser profile, OneDrive token, or machine-specific configuration may be included in the image.

## 7. Image composition and package ownership

Create a declarative package and configuration manifest rather than copying a developer's home directory. Separate the image into:
- **Base system:** kernel, init, core utilities, hardware enablement, and package infrastructure;
- **InntegerOS integration:** system identity, desktop defaults, Control Center, first-run flow, update/recovery helpers, and branding;
- **First-party applications:** tools maintained as part of InntegerOS;
- **Optional bundles:** development, creative, and gaming tools;
- **Hardware enablement:** only justified, documented drivers and firmware.

Over time, establish an InntegerOS package repository and signed release/update metadata if the project can maintain them securely. Until then, clearly document which updates come from upstream repositories and which come from InntegerOS. Do not promise an independent package ecosystem before it exists.

Avoid automatically installing large or proprietary game launchers, personal applications, or optional developer stacks in the base image. Offer them after installation instead.

## 8. Build and test gates

### Gate A — upstream and base evaluation
- Compare supported Ubuntu/Kubuntu bases and image-building tools.
- Download and verify candidate official images and signatures/checksums.
- Inspect package manifests, boot process, installer engine, and licensing.
- Boot the unmodified candidate image in a disposable VM.

### Gate B — InntegerOS live-image proof of concept
- Build from a documented, repeatable configuration controlled by this repository.
- Apply InntegerOS system identity, session defaults, first-party tools, and package manifest.
- Remove upstream distribution branding only where legally and technically appropriate; retain required notices.
- Boot into the InntegerOS live desktop in a VM.
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

## 9. Current blockers

- No ISO build configuration or reproducible image-generation script exists yet.
- The final base distribution and installer engine have not been selected.
- No live-image VM test has been completed.
- No installation, dual-boot, recovery, or post-install test has been completed.
- Package ownership, update policy, and first-boot behaviour still need to be made declarative.

## 10. Image-build tooling

The initial comparison of `livecd-rootfs`, Debian `live-build`, and `mkosi` is recorded in [Image-Build Tool Evaluation](IMAGE-BUILD-TOOLS.md). The Ubuntu image pipeline is the first candidate for a technical spike because Ubuntu 26.04 is the current base candidate, but no tool has been selected. Selection depends on a reproducible project-owned build and successful disposable-VM live boot.

## 11. Immediate next tasks

1. Define the InntegerOS product identity and the components the project will maintain.
2. Compare candidate base systems and image-building tools instead of assuming a Kubuntu respin.
3. Create an `iso/` project area for build configuration, package manifests, and image metadata.
4. Build the smallest reproducible InntegerOS live-image prototype.
5. Design and test the InntegerOS installation experience over a proven installer backend.
6. Keep installation testing separate until the live image is stable.
