# lxpower SPEC

Planned work lives in [`../ROADMAP.md`](../ROADMAP.md).

## Scope

- `lxpower` is a compact power-profile switcher rather than a large system
  monitor
- it preserves the current split between:
  - quick top-level toggle behavior
  - explicit popup profile selection
  - optional pinning
- preferred profiles stay remembered per source (`battery` vs `ac`)
- battery timing and dGPU status stay compact metadata, not the main focus of
  the popup
- popup/session behavior stays aligned with shared `lx*` popup conventions

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
