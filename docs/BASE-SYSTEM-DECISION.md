# InntegerOS Base-System Decision

**Status:** open decision; no permanent base selected.

## Candidates

- Ubuntu 26.04 with project-owned package and image configuration.
- Ubuntu minimal base with InntegerOS-selected desktop components.
- Another Debian-family base only if it offers a measurable maintenance advantage.

Kubuntu 26.04.1 is the current development environment, not a final product decision. A themed respin alone does not satisfy the InntegerOS product goal.

## Evaluation criteria

| Criterion | Priority | Evidence |
| --- | --- | --- |
| Maintenance lifecycle | High | Published support dates and update channels |
| Independent image buildability | High | Repeatable project-controlled build |
| Hardware coverage | High | Kernel, firmware, graphics, Wi-Fi and suspend tests |
| Installer integration | High | Supported backend and VM results |
| Desktop edition flexibility | Medium | Feasible Plasma/GNOME/Xfce profiles |
| Package availability | Medium | Required package availability |
| Redistribution clarity | Medium | Licence notices and trademark review |
| Maintenance burden | High | Maintained patches and release-specific work |

## Required evidence

Record the exact upstream release, architecture, repositories, lifecycle, kernel and desktop versions. Build a minimal live-image prototype, capture its package manifest and logs, test UEFI boot and offline use in a disposable VM, and review attribution requirements.

## Decision

Defer selection. Ubuntu 26.04 remains the first technical candidate for a prototype, not a permanent commitment.
