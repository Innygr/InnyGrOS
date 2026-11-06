# InntegerOS Test Strategy

**Status:** initial test plan for the distribution prototype.

## Test layers

1. **Static checks:** shell syntax, Python compilation, XML/SVG parsing, and package-list formatting.
2. **Component tests:** fixtures for scripts and applications, with mocked system commands where appropriate.
3. **Integration tests:** Control Center workflows and desktop adapters in a clean VM.
4. **Image tests:** build completion, UEFI boot, offline first login, and edition identity.
5. **Upgrade tests:** move from one prototype build to the next and confirm user settings remain intact.
6. **Hardware tests:** validate supported devices only after VM checks pass.

## Test data

Use temporary home directories and disposable virtual machines. Test fixtures must not depend on personal files, real account tokens, or the developer's daily-use installation.

## Reporting

Every test report records the source commit, base release, desktop edition, VM or hardware configuration, exact test steps, result, and known limitations. A skipped test is not a pass.

## Current status

The repository already has component-level smoke tests and GitHub Actions validation. A bootable image and its VM test suite do not exist yet.
