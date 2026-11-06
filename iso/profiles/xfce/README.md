# Xfce Edition profile

**Status:** planned lightweight alternative; not implemented.

## Intent

Xfce is intended as a lean desktop option. Resource use must be measured rather than promised based on reputation.

## Boundaries

- Xfce session, panel, settings, window manager, and login integration belong here.
- Keep the default package selection deliberately small.
- Do not pull in a full Plasma or GNOME settings stack.
- Shared InntegerOS services remain available where dependencies permit.
- Use Xfce-native controls for desktop-specific settings.

## Validation gate

Measure idle memory and boot behaviour under a documented VM configuration. Test display scaling, audio, networking, suspend/resume, first-run, updates, and recovery. Publish test conditions with any performance comparison.

No Xfce package manifest is frozen yet.
