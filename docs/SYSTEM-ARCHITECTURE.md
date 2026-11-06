# InntegerOS System Architecture

**Status:** architecture baseline. The current implementation remains a Kubuntu + KDE Plasma desktop customization project.

## Product layers

1. **Base system:** Linux kernel, initramfs, system services, firmware, graphics, package manager, repositories, and hardware support.
2. **InntegerOS platform:** release identity, package policy, update and recovery coordination, diagnostics, first-run setup, and shared services.
3. **Desktop edition:** Plasma, GNOME, or Xfce packages, session defaults, login integration, native settings adapters, and edition tests.
4. **First-party experience:** Control Center, personalization tools, Welcome Center workflows, Blacklight integrations, and default application selection.
5. **Image and installer:** live-session configuration, boot media, installer integration, release metadata, and verification artifacts.

## Ownership boundary

InntegerOS maintains its own product configuration, package manifests, edition profiles, artwork, first-party tools, integration tests, release process, and documentation. Upstream projects remain upstream. A component is not InntegerOS-native merely because it has an InntegerOS theme; native ownership means maintaining its source, tests, compatibility, and support commitments.

## Shared services and desktop adapters

Shared services must not assume Plasma is installed. They should expose documented command-line, D-Bus, or configuration interfaces. Desktop adapters call native settings tools: Plasma uses KConfig and KWin; GNOME uses GNOME settings; Xfce uses Xfconf and its native session tools. Unsupported features must be explained rather than failing silently.

## Configuration precedence

1. System policy.
2. User-selected accessibility and privacy settings.
3. Edition defaults.
4. Optional appearance presets.

Appearance presets must not override system policy or silently reset user preferences.

## Current state versus target

| Area | State |
| --- | --- |
| Plasma customization | Implemented in the existing desktop project |
| Control Center and first-party utilities | Partially implemented; test coverage varies |
| Desktop-independent service APIs | Not yet established |
| GNOME and Xfce profiles | Planned only |
| Repository-controlled live image | Not yet implemented |
| Installer integration | Design stage |
| Complete Edition / InntegerOS-designed shell | Long-term vision only |

## Acceptance gates

- A clean install identifies its release and selected edition.
- Shared services work without Plasma-only dependencies.
- Each edition installs only its own desktop stack by default.
- First-run, update, diagnostics, and recovery have documented interfaces and tests.
- Upstream notices and licensing are retained.
