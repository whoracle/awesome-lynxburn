# lxpower SPEC

## Planned

- Keep `lxpower` as a compact power-profile switcher rather than expanding it
  into a large system monitor.
- Preserve the current split between:
  - quick top-level toggle behavior
  - explicit popup profile selection
  - optional pinning
- Keep preferred profiles remembered per source (`battery` vs `ac`).
- Keep battery timing and dGPU status as compact status metadata, not as the
  main focus of the popup.
- Continue using the shared popup/session model so cycling and keyboard
  navigation stay consistent with other lx* modules.
- Keep the implementation split into focused files instead of regrowing a large
  `init.lua`.

## Unplanned

- No full battery-history or telemetry panel.
  Reason: the module is a quick power-profile control, not a monitoring suite.
- No arbitrary custom profile definitions.
  Reason: the current module is shaped around `powerprofilesctl`’s known
  profile set.
- No separate popup ordering model.
  Reason: popup participation follows `lxbar` top-level order and semantic role
  ordering.
- No embedded vendor-specific GPU tooling.
  Reason: dGPU reporting should stay lightweight and read-only for now.
