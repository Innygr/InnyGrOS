# InntegerOS Desktop Editions

**Status:** long-term architecture plan  
**Current reality:** the repository's working desktop edition is currently a Kubuntu + KDE Plasma customization project. GNOME/Xfce editions, a standalone ISO, and an InntegerOS desktop shell do not exist yet.

## Product vision

InntegerOS should offer a choice of desktop experiences without becoming three unrelated distributions. The operating-system foundation, first-party tools, security/update policy, installer, and product identity should remain consistent.

### 1. Plasma Edition — flagship

- Primary development and validation target.
- Keep KDE Plasma as the default desktop for the first installable prototype.
- Integrate the InntegerOS Control Center, Theme Studio, Wallpaper Studio, Quick Settings, Blacklight features, and system workflows with Plasma.
- Preserve useful Plasma capabilities instead of replacing them just for branding.
- Keep desktop-specific settings and dependencies inside the Plasma edition profile.

### 2. GNOME Edition — alternative

- Offer GNOME's distinct Activities, overview, dash, and workspace-oriented workflow.
- Use GNOME-native settings and conventions; do not expose Plasma-only modules as if they apply.
- Integrate the shared InntegerOS Control Center and first-party services through supported interfaces.
- Provide an InntegerOS visual identity that feels native to GNOME rather than copying the Plasma layout.
- Validate login, display, audio, networking, updates, suspend/resume, and first-run experience independently.

### 3. Xfce Edition — lightweight alternative

- Aim for a lean desktop profile for modest or older hardware.
- Keep the default package selection small and avoid promising specific performance gains before measurement.
- Integrate the shared InntegerOS utilities while using Xfce-native panel, settings, session, and window-management tools.
- Avoid pulling in a full second desktop stack or unnecessary duplicate applications.
- Validate hardware support and everyday workflows on representative lower-resource virtual machines and physical hardware when available.

## Shared system architecture

Every edition should share:

- the same InntegerOS identity, release versioning, repositories, security policy, and update/recovery model;
- the same supported base-system packages and kernel policy;
- the same installer framework and first-boot account/setup flow;
- the InntegerOS Control Center core, diagnostics, updater, and first-party application suite;
- shared artwork, accessibility expectations, documentation, and support boundaries.

Desktop-specific components must be separated into maintained edition profiles. A profile should declare its desktop packages, display/login manager integration, defaults, settings modules, optional applications, and tests. Installing one edition should not silently install the full settings stack or duplicate default applications from the others.

The installer should let users choose one supported desktop profile. The default selection is Plasma. Additional desktops should not be installed together by default. A later post-install desktop switcher may be considered, but only after dependency conflicts, display-manager transitions, and session recovery are tested.

## InntegerOS: Complete Edition

**Complete Edition is the long-term product vision, not a current download or release.**

It represents the mature, fully integrated InntegerOS experience:
- a complete and polished first-party system experience;
- the full Control Center and application ecosystem;
- consistent boot, login, desktop, update, recovery, and installation workflows;
- a mature choice of supported desktop editions;
- eventually, an InntegerOS-designed desktop environment and shell.

The project should not begin by forking Plasma or attempting to write a full desktop environment. First build and maintain the shared operating-system services and integrations. Then identify concrete gaps that upstream desktops cannot meet. Only those justified gaps should become candidates for InntegerOS-native components.

A future InntegerOS desktop environment should be developed as a separate, testable project with clear interfaces to the shared system services. It should coexist with Plasma during development and earn default status through usability, accessibility, hardware, and upgrade testing—not branding alone.

## Development order and release gates

1. **Plasma foundation:** stabilize the shared system architecture and build the first repeatable live image around Plasma.
2. **GNOME profile:** prototype only after the shared base, installer, and first-run flow are stable. Verify that core InntegerOS functions work without Plasma dependencies.
3. **Xfce profile:** add a deliberately lean profile and measure its resource use; do not infer speed from the desktop's reputation.
4. **Edition parity:** define a shared acceptance checklist and publish the limitations of each supported edition.
5. **Complete Edition research:** document user needs that require InntegerOS-native desktop components. Prototype individual components before considering a full shell.
6. **Native desktop maturity:** only consider making an InntegerOS shell a supported session after it passes accessibility, hardware, stability, upgrade, and recovery gates.

Each desktop edition must pass its own live-session, installation, first-boot, update, suspend/resume, and recovery tests in disposable VMs before being called supported. A desktop listed as experimental must be clearly labelled experimental.

## Decision principles

- One operating system; multiple desktop experiences.
- Plasma first, because it is the current working implementation.
- GNOME and Xfce are alternatives, not competing product identities.
- Share core services; keep desktop-specific UI native to each environment.
- Do not ship multiple desktop environments by default.
- Do not promise a custom InntegerOS shell until there is a maintained, tested implementation.
- Never use the user's daily-use dual-boot ThinkPad as a destructive installer test machine.
