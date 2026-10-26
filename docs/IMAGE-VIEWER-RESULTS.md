# Image Viewer Compatibility Results

**Status: NOT YET TESTED ON THE TARGET KUBUNTU RELEASE**

This document is a results ledger, not a claim of format support. Fill it in only after opening the fixture in the actual viewer on the recorded system. Package presence alone is not a pass.

## Test environment

| Field | Value |
| --- | --- |
| Test date | Pending |
| InnyGrOS commit | Pending |
| Base distribution and release | Pending |
| KDE Plasma version | Pending |
| Gwenview version | Pending |
| Installed image-format plugin packages | Pending |
| Test environment | Pending (VM or hardware) |

## Format matrix

Use **Pass** only after visually checking the rendered output. For animated formats, verify movement, timing, looping, and pause/play if available. Use **Not tested**, **Fail**, or **Partial** otherwise.

| Format / case | Open | Correct rendering | Animation / pages | Notes |
| --- | --- | --- | --- | --- |
| JPEG baseline | Not tested | Not tested | N/A | |
| Progressive JPEG | Not tested | Not tested | N/A | |
| PNG with transparency | Not tested | Not tested | N/A | |
| Static GIF | Not tested | Not tested | N/A | |
| Animated GIF | Not tested | Not tested | Not tested | |
| APNG | Not tested | Not tested | Not tested | |
| Static WebP | Not tested | Not tested | N/A | |
| Animated WebP | Not tested | Not tested | Not tested | |
| AVIF | Not tested | Not tested | N/A | |
| HEIF / HEIC | Not tested | Not tested | N/A | |
| BMP | Not tested | Not tested | N/A | |
| Multi-page TIFF | Not tested | Not tested | Not tested | |
| SVG | Not tested | Not tested | N/A | |
| Camera RAW sample | Not tested | Not tested | N/A | Optional; record sample/license |
| Damaged or unsupported file | Not tested | N/A | N/A | Should fail gracefully |

## Workflow checks

- [ ] Open from Gwenview's file chooser.
- [ ] Open from Dolphin / file manager.
- [ ] Open a path containing spaces and non-ASCII characters.
- [ ] Previous/next image navigation works.
- [ ] Fit-to-window, actual size, zoom, rotate, and fullscreen work.
- [ ] Viewing does not modify source files.
- [ ] Missing optional plugin is handled gracefully.
- [ ] Record memory/CPU behavior for a large image and an animation.
- [ ] Test wallpaper selection separately; Gwenview support does not guarantee Plasma wallpaper support.
- [ ] If testing in a VM, note virtual graphics limitations.

## Recording a result

For every test session, include the exact OS release, package versions, fixture source/license, and any relevant error message. Do not mark a format supported just because it appears in a file chooser or because a plugin package is installed.

See [the implementation and release plan](IMAGE-VIEWER.md).
