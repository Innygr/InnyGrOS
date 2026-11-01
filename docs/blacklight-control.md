# Blacklight Control

Blacklight Control is a user-scoped remote-management helper for an IntegerOS / Kubuntu computer, intended to be controlled from the owner's explicitly paired KDE Connect phone.

## Install the user service

From the repository checkout:

```bash
bash scripts/blacklight-control-service.sh install
```

This installs the helper under `~/.local/lib/blacklight-control/`, a command wrapper at `~/.local/bin/blacklight-control`, and a systemd **user** service at `~/.config/systemd/user/blacklight-control.service`. It does not use sudo or install a system-wide daemon.

Check it with:

```bash
~/.local/bin/blacklight-control status
systemctl --user status blacklight-control.service
```

The agent writes a heartbeat to `~/.local/state/blacklight-control/state.json` (or `$XDG_STATE_HOME/blacklight-control/state.json`). The file is private to the user. The service starts with the user's systemd session and restarts if it exits unexpectedly.

To remove the service and installed program files:

```bash
bash scripts/blacklight-control-service.sh uninstall
```

Uninstall retains the local status/history directory. The installer and uninstaller touch only the named Blacklight Control files in the current user's home directory.

## Connect KDE Connect

1. Pair the phone and laptop in KDE Connect and confirm the pairing on both devices.
2. Run `bash scripts/blacklight-control-service.sh commands` to print the commands with the correct installed path.
3. In KDE Connect's Run Commands settings on the laptop, add the printed commands for that paired phone:
   - **Status** — reports whether the user service heartbeat is active.
   - **Lock** — asks `loginctl` to lock the current session.
   - **Message** — displays a visible KDE dialog. Replace the sample text with a fixed message of your choice.
   - **Clear last-action record** — clears the saved last-action text only.
4. Keep Run Commands enabled only for devices you recognize and have explicitly paired.

KDE Connect Run Commands are fixed commands; this integration does not create a text-entry prompt on the phone. The message command is configured as a fixed command. The setup helper prints commands but deliberately does not edit KDE Connect's private configuration or pairing data.

## Commands

The installed wrapper supports:

```bash
blacklight-control status
blacklight-control lock
blacklight-control message "Your message"
blacklight-control clear-state
```

- `status` checks the agent heartbeat and reports the last recorded action.
- `lock` requests the native desktop session lock. Normal account authentication remains required to unlock.
- `message` displays a visible `kdialog` message (maximum 240 characters).
- `clear-state` clears only the last-action record; it does not stop the service or unlock the session.

## Security and platform boundaries

- KDE Connect remains responsible for pairing and authorization. This project does not store or manipulate KDE Connect pairing keys.
- The service is user-scoped and has no network listener.
- The native session lock is real; there is no remote unlock or authentication bypass.
- Shutdown, restart, firmware controls, emergency recovery, virtual terminals, and normal authentication are not disabled or intercepted.
- A fullscreen overlay is not a security boundary. On Plasma Wayland, ordinary applications cannot reliably suppress every system shortcut or alternate session path.
- Screen viewing is not implemented. Any future screen viewing must be explicitly initiated, visibly indicated, and stoppable locally; silent capture or recording is out of scope.
- Keep a local recovery method available if the phone is disconnected.

## Implementation milestones

- [x] **0.1 — Architecture and security boundaries.**
- [x] **0.2a — Command prototype:** status, native session-lock request, visible message dialog, and local state.
- [x] **0.2b — Agent lifecycle:** user-scoped systemd service, install/uninstall helper, heartbeat status, and KDE Connect command setup instructions.
- [ ] **0.3 — KDE Connect integration:** validate the printed Run Commands on supported KDE Connect desktop/mobile versions.
- [ ] **0.4 — Lockdown backend:** evaluate supported kiosk/session-policy mechanisms; document exactly what is and is not enforced.
- [ ] **0.5 — Screen viewing:** consent-based KRdp/PipeWire integration and mobile-client compatibility testing.
- [ ] **0.6 — GUI and packaging:** IntegerOS Welcome Center controls, logs, recovery, and uninstall support.

## Tests

Run the isolated smoke tests from the repository root:

```bash
bash tests/blacklight-control-smoke.sh
bash tests/blacklight-control-service-smoke.sh
```

The tests use temporary directories and mocked system commands; they do not lock the test machine or enable a real service.

## Related features

- [Blacklight Matrix native lock screen](blacklight-lockscreen.md) styles KDE's real lock screen while preserving native authentication.
- [Blacklight Matrix screensaver](blacklight-screensaver.md) is a visual screensaver and is not a security lock.
