# InntegerOS image build metadata

**Status:** build contract proposal. No image builder has been selected and no ISO has been produced.

Every prototype image must have a machine-readable metadata record stored beside its build logs. Metadata is part of the release artifact, not an optional note.

## Required fields

- Product name and edition (initial target: InntegerOS Plasma Edition).
- InntegerOS version and source Git commit.
- Build date in UTC and build environment identifier.
- Ubuntu suite/codename, repository snapshot or exact repository configuration, and package architecture.
- Image builder name and exact version.
- Kernel, initramfs, bootloader, live-session, and installer component versions.
- Ordered manifest paths and SHA-256 digest for each manifest.
- Resolved package list with exact versions (including architecture).
- Enabled APT components and any additional repository origins.
- Build command/configuration revision and non-secret build logs.
- Output filename, byte size, and SHA-256 checksum.
- Test report reference and explicit pass/fail/blocked status for each acceptance gate.

## Suggested artifact layout

- artifacts/<version>/<edition>/<architecture>/
- ISO image
- SHA256SUMS
- build-metadata.json
- package-lock.txt
- manifests/
- logs/
- tests/

Generated ISOs, package caches, credentials, and personal files must not be committed to the source repository. Publish release artifacts separately and retain the metadata and checksums.

## Integrity and provenance

1. Build from a clean checkout at a recorded commit.
2. Resolve packages from explicitly recorded repository origins.
3. Capture exact installed package versions after image assembly.
4. Hash the ISO and every manifest.
5. Keep build logs free of tokens, passwords, private keys, and personal home-directory paths where practical.
6. Test the exact hashed artifact; do not test one ISO and publish a different rebuild under the same filename.
7. Rebuild twice in clean environments and compare package sets and metadata. Bit-for-bit reproducibility is a separate goal and must not be claimed unless demonstrated.

## Release rule

An image is a **prototype** until it boots in a disposable UEFI VM, passes the live-session checklist, and has a complete metadata record. It is **installable** only after the installer and post-install acceptance gates pass in disposable VMs. A checksum alone does not establish safety or functionality.
