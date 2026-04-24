# Migration Guide

This file tracks only migrations between tagged releases.

Current baseline:

- assume users are already on `v1.6.0`
- document only incremental migrations from that point forward
- do not use this file for one-off machine migration notes anymore

## Migration Policy

- add a new section when a release changes user-facing config or required local
  migration steps
- assume users migrate incrementally and do not skip documented steps
- prefer documenting migrations for breaking or meaningfully user-visible
  config-shape changes

## Documented Migrations

### `v1.6.0` -> `v1.7.0`

No user-facing config migration is currently required.

The work since `v1.6.0` has been behavior, interaction, theme, and
documentation refinement rather than a config-shape break.

### `v1.5.0` -> `v1.6.0`

Apply these user-facing config migrations:

- update `lxmodules.lxbar.order` to use full module ids such as `lxmedia`,
  `lxbluetooth`, `lxnetwork`, `lxnotify`, `lxdisplay`, `lxpower`,
  `lxsecrets`, and `lxrunner`
- update `lxmodules.lxbar.modules` to use the same full ids as keys:
  `lxmedia = { ... }`, not `media = { ... }`
- if you want to select a bundled `lynxburn` color scheme explicitly, use
  `theme = { color_scheme = "lynxburn" }`
  Flat `theme.<key>` overrides continue to work as before.
- `lxsecrets` is available as an optional new module
  No migration is required unless you want to enable/configure it.
