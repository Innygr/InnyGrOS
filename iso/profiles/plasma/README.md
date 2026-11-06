# Plasma Edition profile

**Status:** first prototype target; package list not frozen.

## Intent

Plasma is the flagship and first implementation target because it is the current working desktop. The edition should feel like an integrated InntegerOS session while preserving useful KDE capabilities.

## Responsibilities

- Include the supported Plasma session and login integration.
- Apply InntegerOS artwork and carefully scoped defaults.
- Integrate the Control Center and supported first-party applications.
- Keep KDE-specific settings modules and dependencies inside this profile.
- Preserve native KDE tools where they are the best fit.
- Provide a clear fallback and recovery guide.

## Validation

- UEFI live boot and login.
- Keyboard, pointer, display scaling, audio, networking, and suspend/resume in a VM.
- Control Center launches and explains unavailable optional features.
- User settings are not overwritten on every login.
- Offline first boot is usable.
- Package manifest is reviewed and captured in build metadata.

The package list will be added after the base package set and build tool are selected.
