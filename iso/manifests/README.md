# Image package manifests

Package lists define image composition and remain separate from desktop profiles and build-tool configuration.

## Rules

- One package name per line.
- Blank lines and lines beginning with `#` are comments.
- Keep shared packages separate from edition-specific packages.
- Document non-obvious package choices in the corresponding profile.
- Do not include personal files or machine-specific configuration.
- Avoid meta-packages that pull in a second desktop environment.
- Record package sources and version policy in build metadata.
- Treat every list as a proposal until the image build and clean-VM test pass.

## Planned structure

- `base/` — boot, networking, system services, firmware policy, shared utilities.
- `profiles/plasma/` — Plasma-only packages.
- `profiles/gnome/` — GNOME-only packages.
- `profiles/xfce/` — Xfce-only packages.
- `optional/` — opt-in applications.
