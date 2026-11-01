# Blacklight Control (prototype)

Blacklight Control is the proposed remote-management subsystem for IntegerOS / Kubuntu. Its intended controller is the user's explicitly paired KDE Connect phone; its target is the user's own device.

The first command prototype is now present. **It is not a complete remote-management app and is not yet installed by IntegerOS.** The existing Blacklight Matrix lock-screen theme is a separate visual customization.

## Prototype commands

Run the helper from a checkout:

```bash
python3 apps/blacklight-control/blacklight-control status
python3 apps/blacklight-control/blacklight-control lock
python3 apps/blacklight-control/blacklight-control message "Your configured message"
python3 apps/blacklight-control/blacklight-control clear-state
```

- `status` prints the locally recorded state.
- `lock` asks `loginctl` to lock the current desktop session using the native session manager. Normal account authentication is still required to unlock.
- `message` displays a visible KDE dialog using `kdialog`; text is limited to 240 characters.
- `clear-state` clears only the helper's local status record. It does not unlock the session.

The status record is stored under `$XDG_STATE_HOME/blacklight-control/state.json`, or `~/.local/state/blacklight-control/state.json` when XDG_STATE_HOME is unset. The file is user-owned and written with mode 0600.

## KDE Connect setup (manual, prototype)

1. Pair the phone with the laptop in KDE Connect and verify the pairing on both devices.
2. On the laptop, open KDE Connect's Run Commands configuration for that paired phone.
3. Add commands that invoke the helper by its full local path. For example, replace `/path/to/InnyGrOS` with the actual checkout path:
   - Status: `python3 /path/to/InnyGrOS/apps/blacklight-control/blacklight-control status`
   - Lock: `python3 /path/to/InnyGrOS/apps/blacklight-control/blacklight-control lock`
   - Message: `python3 /path/to/InnyGrOS/apps/blacklight-control/blacklight-control message "Please check in with the laptop owner"`
4. Keep Run Commands enabled only for devices you recognize and have explicitly paired.

KDE Connect Run Commands send fixed commands; they do not provide a text-entry prompt on the phone. The message example above is static. Do not expose this helper through a public network listener or copy KDE Connect pairing credentials into this project.

## Security and platform boundaries

- Only devices explicitly paired and authorized in KDE Connect should receive the Run Commands profile. Pairing and authorization remain managed by KDE Connect.
- Do not store KDE Connect pairing keys in this project or attempt to bypass KDE Connect's authorization.
- The native session lock is real; the helper does not implement remote unlock and does not bypass the user's password or other login method.
- Do not disable or intercept shutdown, restart, firmware controls, emergency recovery, virtual terminals, or normal authentication.
- A fullscreen overlay is not a security boundary. On Plasma Wayland, ordinary applications cannot reliably suppress every system shortcut or alternate session path.
- Do not silently capture or stream a screen. Any future screen viewing must be explicit, visible, and stoppable locally.
- If the phone is disconnected, the user must retain a local recovery method.

## Planned architecture

1. **Agent** — evolve the helper into a user-session service with a narrow command interface and local state.
2. **KDE Connect adapter** — setup helper and tested Run Commands profile for paired devices.
3. **Lockdown backend** — evaluate supported KDE kiosk/session-policy facilities; document exactly what is and is not enforced.
4. **Screen-view backend** — investigate KRdp / KDE's supported PipeWire remote-desktop stack. Screen capture must remain visible and consent-based.
5. **GUI and recovery** — IntegerOS Welcome Center controls, local logs, recovery, and uninstall support.

## Implementation milestones

- [x] **0.1 — Initial architecture and security boundaries.**
- [x] **0.2a — Command prototype:** local status, native session-lock request, visible message dialog, and local state clearing.
- [ ] **0.2b — Agent lifecycle:** user-scoped service, explicit start/stop, and clean uninstall.
- [ ] **0.3 — KDE Connect integration:** setup helper and tested Run Commands profile for paired devices.
- [ ] **0.4 — Lockdown backend:** evaluate supported kiosk/session-policy mechanisms; document exactly what is and is not enforced.
- [ ] **0.5 — Screen viewing:** consent-based KRdp/PipeWire integration and mobile-client compatibility testing.
- [ ] **0.6 — GUI and packaging:** IntegerOS Welcome Center controls, logs, recovery, and uninstall support.

## Tests

Run the smoke test from the repository root:

```bash
bash tests/blacklight-control-smoke.sh
```

The test uses a temporary state directory and a mock `loginctl`; it does not lock the test machine.

## Related features

- [Blacklight Matrix native lock screen](blacklight-lockscreen.md) styles KDE's real lock screen while preserving native authentication.
- [Blacklight Matrix screensaver](blacklight-screensaver.md) is a visual screensaver and is not a security lock.
