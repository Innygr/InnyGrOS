# Image package manifests

Package lists define image composition and remain separate from desktop profiles and build-tool configuration.

## Rules

- One package name per line.
- Blank lines and lines beginning with # are comments.
- Keep shared packages separate from edition-specific packages.
- Document non-obvious package choices in the corresponding profile.
- Do not include personal files or machine-specific configuration.
- Avoid meta-packages that pull in a second desktop environment.
- Record package sources and version policy in build metadata.
- Treat every list as a proposal until the image build and clean-VM test pass.

## Current proposal files

- base/common.txt — shared system utilities and services.
- profiles/plasma/packages.txt — initial Plasma Edition package candidates.
- optional/development.txt — opt-in development tools.
- optional/creative.txt — opt-in creative applications.
- optional/gaming.txt — opt-in gaming tools; some packages may require additional repository components.

These lists are deliberately marked as proposals. They have not been resolved against a complete image-builder environment, and they are not yet a frozen package selection.

## Next validation

1. Select the image builder and Ubuntu repository configuration.
2. Resolve every package name and record its candidate version and origin.
3. Inspect dependency closure and identify packages pulled in by recommendations.
4. Build a minimal disposable root filesystem and compare its package inventory with these manifests.
5. Capture the exact resolved package set in the image build metadata.

Optional bundles must never be included in the minimal base image by default.
