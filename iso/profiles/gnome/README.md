# GNOME Edition profile

**Status:** planned alternative; not implemented.

## Intent

GNOME is an alternative workflow, not a second product identity. It should use GNOME conventions rather than imitate the Plasma panel layout.

## Boundaries

- GNOME Shell, session, settings, and login integration belong here.
- Do not install Plasma/KWin/KConfig dependencies unless a shared component requires them.
- Shared InntegerOS services remain desktop-independent.
- The Control Center must adapt its modules and explain unavailable features.
- Prefer stable GNOME settings interfaces.

## Validation gate

This edition cannot be advertised as supported until it passes clean live boot, first-run, networking, audio, display scaling, suspend/resume, update, recovery, and application-integration tests in a disposable VM.

No GNOME package manifest is frozen yet.
