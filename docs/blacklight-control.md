# Blacklight Control (planned)

Blacklight Control is the proposed remote-management subsystem for IntegerOS / Kubuntu. Its intended controller is the user's explicitly paired KDE Connect phone; its target is the user's own ThinkPad or other enrolled IntegerOS device.

This document records the initial design. **Blacklight Control is not implemented or installable yet.** The existing Blacklight Matrix lock-screen theme is a separate visual customization and is not a remote-management agent.

## Goals

- Provide a small, open-source management agent for a device the owner administers.
- Use KDE Connect's paired-device trust and Run Commands for the first phone-control interface.
- Offer a clear device status and an explicit enable/disable state.
- Provide a lockdown mode that uses supported KDE/OS mechanisms rather than pretending a fullscreen window is a secure lock.
- Explore consent-based live screen viewing on the owner's own device.
- Keep logs local, minimize dependencies, and make every installed component removable.

## Planned architecture

1. **Agent** — a user-session service, with a narrow command interface and local state.
2. **KDE Connect adapter** — documented Run Commands registered by the user on the laptop and exposed by their already-paired phone. Pairing and device authorization remain managed by KDE Connect.
3. **Lockdown backend** — integrate with KDE's native session-locking and supported kiosk/session-policy facilities. A decorative fullscreen notice may be offered separately, but must never be described as secure access control.
4. **Screen-view backend** — investigate KRdp / KDE's supported PipeWire remote-desktop stack. Screen capture must remain visible and consent-based; remote viewing must not be covert.
5. **Status and recovery** — report agent state, connection state, and active features. Provide a local recovery path if the phone is unavailable.

## Planned phone commands

The initial KDE Connect profile is expected to expose commands such as:

- `Blacklight Control: Status`
- `Blacklight Control: Enable Lockdown`
- `Blacklight Control: Disable Lockdown`
- `Blacklight Control: Start Screen View`
- `Blacklight Control: Stop Screen View`

KDE Connect Run Commands execute a command on the laptop; they do not provide a general-purpose text-entry form on the phone. A later controller UI may provide editable message text. Until then, any custom message should be configured locally or passed as a carefully validated argument.

## Security and platform boundaries

- Only devices explicitly paired and authorized in KDE Connect should receive the Run Commands profile. Do not expose an unauthenticated network listener.
- Do not store KDE Connect pairing keys in this project or attempt to bypass KDE Connect's authorization.
- Do not silently capture or stream a screen. Screen viewing must be explicit, visible, and stoppable locally.
- Do not disable or intercept shutdown, restart, firmware controls, emergency recovery, virtual terminals, or the system's normal authentication mechanisms.
- A fullscreen overlay is not a security boundary. On Plasma Wayland, ordinary applications cannot reliably suppress every system shortcut or alternate session path.
- Remote disable should release the app's own lockdown state; it must not silently bypass the account's normal authentication.
- If the phone is disconnected, the user must retain a local recovery method.

## Implementation milestones

- [ ] **0.1 — Architecture and threat model:** this document; identify supported Plasma/Kubuntu versions and test strategy.
- [ ] **0.2 — Agent prototype:** user-scoped service, local status, explicit start/stop, clean uninstall.
- [ ] **0.3 — KDE Connect integration:** setup helper and tested Run Commands profile for paired devices.
- [ ] **0.4 — Lockdown backend:** evaluate supported kiosk/session-policy mechanisms; document exactly what is and is not enforced.
- [ ] **0.5 — Screen viewing:** consent-based KRdp/PipeWire integration and mobile-client compatibility testing.
- [ ] **0.6 — GUI and packaging:** IntegerOS Welcome Center controls, logs, recovery, and uninstall support.

## Existing related features

- [Blacklight Matrix native lock screen](blacklight-lockscreen.md) styles KDE's real lock screen while preserving native authentication.
- [Blacklight Matrix screensaver](blacklight-screensaver.md) is a visual screensaver and is not a security lock.

## Current status

Design only. No agent, remote-control service, screen capture, or lockdown enforcement is included in this commit.