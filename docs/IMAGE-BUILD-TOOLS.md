# InntegerOS Image-Build Tool Evaluation

**Status:** preliminary research; no build tool selected  
**Target:** first reproducible x86_64 Plasma live-image proof of concept  
**Base:** Ubuntu 26.04 (Resolute) remains a candidate, not a final decision

## Evaluation requirements

The first build system must support:
- repository-controlled, repeatable configuration;
- package installation and removal from Ubuntu-compatible repositories;
- a bootable UEFI live image, with legacy BIOS considered where practical;
- a live desktop that can run without writing to internal disks;
- integration with an installer backend that can be branded and safely configured;
- package manifests, reproducible logs, checksums, and VM testing;
- a maintainable path to later GNOME and Xfce edition profiles.

A tool that only creates a root filesystem or disk image is not automatically a complete live-ISO and installer solution.

## Candidates

### A. Ubuntu image pipeline: `livecd-rootfs` + Ubuntu image tooling

**What it is:** Canonical documents `livecd-rootfs` as the tool used to create Ubuntu installer and preinstalled images. The documented build interface uses its live-build auto scripts and project/suite variables. Ubuntu's wider publication pipeline also uses `ubuntu-cdimage` and Launchpad build infrastructure.

**Strengths**
- Closest alignment with the Ubuntu 26.04 candidate base.
- Uses Ubuntu's own image-generation components and conventions.
- Provides a credible route to understanding Ubuntu live and installer image composition.

**Risks / questions**
- Some workflows are designed around Canonical's own project configuration and infrastructure.
- We must prove that an independent InntegerOS project can maintain its own configuration without relying on inaccessible Canonical build services.
- Installer integration, desktop selection, branding, and package ownership still need separate design and testing.

**Assessment:** first candidate for a small technical spike because Ubuntu is the current base candidate. Do not assume it is independently maintainable until the spike proves that.

### B. Debian `live-build`

**What it is:** a configurable toolkit for assembling live systems from package archives and configuration directories. Ubuntu's documented image pipeline also uses live-build to create root filesystems.

**Strengths**
- Configuration-driven and suitable for keeping package lists and hooks in version control.
- Designed around live-system construction rather than only producing a generic disk image.
- Could provide a more project-owned workflow if the Ubuntu-specific components can be integrated cleanly.

**Risks / questions**
- Ubuntu-specific boot, installer, kernel, initramfs, and desktop integration must be validated rather than assumed.
- A successful Debian live-build configuration is not proof that an Ubuntu 26.04 live image will boot or install correctly.
- We need a minimal prototype before committing to it.

**Assessment:** strong comparison candidate and possible fallback if the Ubuntu pipeline is too coupled to Canonical's release infrastructure.

### C. `mkosi`

**What it is:** a systemd project for building customized OS disk images. Its documentation describes package-manager integration including APT and supports Ubuntu as a distribution target.

**Strengths**
- Declarative configuration and useful image-building/development workflows.
- Ubuntu package support.
- Useful for experimenting with root filesystems, disk images, and later system-image development.

**Risks / questions**
- A disk image is not the same thing as a polished hybrid live ISO with a desktop session and safe graphical installer.
- Live-session persistence, boot-media layout, and installer integration would need additional work.
- It may be better suited to component images or future development/testing than the first desktop installer ISO.

**Assessment:** useful supporting tool, but not the leading candidate for the first live desktop ISO unless a prototype demonstrates the missing live-media workflow.

## Preliminary recommendation

1. Prototype the Ubuntu `livecd-rootfs` route first against the Ubuntu 26.04 candidate.
2. In parallel, document the smallest `live-build` configuration needed to create the same package/rootfs target.
3. Use `mkosi` as a comparison for rootfs and disk-image development, not as an assumed complete live-ISO solution.
4. Choose only after the same acceptance checks are run: repeatability, UEFI boot in a disposable VM, live Plasma session, offline usability, package manifest capture, and a clear path to an InntegerOS-owned installer experience.

No tool has been selected, no packages have been installed on the user's laptop, and no ISO has been built by this evaluation.

## Sources

- [Ubuntu image builds](https://ubuntu.com/project/docs/how-ubuntu-is-made/processes/image-builds/)
- [Ubuntu create installer image](https://ubuntu.com/hardware/docs/image-cookbook/howto/images/create_installer_image/)
- [Ubuntu live CD customization guide](https://wiki.ubuntu.com/Live_CD_customization)
- [mkosi documentation](https://mkosi.systemd.io/)
