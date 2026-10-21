# Initial manual test checklist

- [ ] Installer rejects root execution.
- [ ] Cancelling the installer makes no changes.
- [ ] Package installer prints the package list and requests confirmation.
- [ ] Theme script installs the scheme in the user's home directory.
- [ ] Existing scheme file is backed up before replacement.
- [ ] Restore helper only removes the InnyGrOS scheme file.
- [ ] Performance helper reports information without changing settings.
- [ ] `performance-benchmark.sh --text` completes when vulkaninfo, glxinfo, lspci, or powerprofilesctl are missing.
- [ ] Performance snapshot from the Welcome Center shows a progress window, then the report, and only saves when confirmed.
- [ ] Saved reports appear in `~/.local/share/innygros/reports` and nothing else is written.
- [ ] Rough CPU timing is consistent (within ~10%) across repeated runs on an idle machine.
- [ ] Desktop profile: apply from the Welcome Center on Plasma 5 and Plasma 6; colors, wallpaper, animation speed, and Konsole default all take effect.
- [ ] Desktop profile: "Restore previous desktop settings" returns the previous color scheme, wallpaper, and animation speed.
- [ ] Desktop profile: `restore --files` brings back the saved config files and keeps a `before-restore-*` copy.
- [ ] Test in a Kubuntu VM before using on physical hardware.
