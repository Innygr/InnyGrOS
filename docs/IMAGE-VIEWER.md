# InnyGrOS 0.8 — Image Viewer Compatibility

## Goal

Make InnyGrOS feel like the "VLC of images": one friendly default viewer that opens as many common still-image and animated-image formats as practical, with clear handling when a codec/plugin is missing.

This is an InnyGrOS desktop feature, not a promise that every obscure format can be decoded. Support depends on the base distribution, installed libraries/plugins, and licensing/redistribution constraints.

## User-facing requirements

- Open images from the file manager and from an explicit **Open With** action.
- Still images: JPEG/JPG, PNG, GIF, WebP, AVIF, HEIF/HEIC, BMP, TIFF, SVG, and common camera RAW formats where supported by distro packages.
- Animation: animated GIF, animated WebP, and APNG where the selected viewer/backend supports playback. Preserve timing and looping; provide pause/play and frame stepping if available.
- Image navigation: previous/next in folder, fit-to-window, actual size, zoom, rotate, fullscreen, and basic metadata.
- Handle transparency and color profiles as correctly as the backend allows.
- Large images should not freeze the whole desktop unnecessarily; show useful errors for unsupported or damaged files.
- Avoid silently converting or overwriting source files.
- Use user-visible package choices and document which optional packages add format support.

## Implementation strategy

Prefer integrating a maintained KDE image viewer such as Gwenview with supported Qt/KDE image-format plugins and distro-provided codecs over writing a decoder from scratch. Audit the exact Kubuntu/Ubuntu release's package names and available formats before adding package installation. If the selected viewer cannot play a required animated format, evaluate a second maintained backend or a small InnyGrOS integration layer rather than claiming support that is not tested.

Keep the default install reasonably small. Make bulky camera RAW support and less-common codecs optional where appropriate. Never fetch codecs or plugins from untrusted sources.

## Test matrix

Create small, legally redistributable fixtures for:
- JPEG and progressive JPEG
- PNG with transparency
- static and animated GIF
- APNG
- static and animated WebP
- AVIF and HEIF/HEIC
- SVG
- multi-page TIFF
- at least one supported RAW sample, if licensing permits

For each fixture, test open, correct rendering, navigation, and graceful failure when an optional plugin is absent. For animated formats, verify playback, pause, loop, and reasonable CPU use. Test file-manager association and opening a file path containing spaces and non-ASCII characters.

Record results by format and platform in the documentation. Do not advertise a format as supported merely because a package is installed.

## Release plan

- **0.8:** choose and integrate the default viewer; add safe package detection/installation; verify common still formats plus animated GIF and WebP where supported; publish a compatibility table.
- **0.9:** expand the matrix to optional formats, improve error handling, and run regression tests.
- **1.0:** ship only the support that has actually been tested on the supported Kubuntu base.
- **ISO/live image:** include the tested viewer configuration in the image build; ensure animation works in the live session too.

## Definition of done

1. A default image viewer is accessible from the Welcome Center and file manager.
2. The documented format matrix reflects real test results.
3. Animated formats are explicitly tested rather than inferred.
4. Missing codecs produce actionable messages, not a broken viewer.
5. No source image is modified by viewing it.
