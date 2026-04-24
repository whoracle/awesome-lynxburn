# Migration Guide

This file tracks only migrations between tagged releases.

Current baseline:

- assume users are already on `v1.7.0`
- document only incremental migrations from that point forward
- do not use this file for one-off machine migration notes anymore

## Migration Policy

- add a new section when a release changes user-facing config or required local
  migration steps
- assume users migrate incrementally and do not skip documented steps
- prefer documenting migrations for breaking or meaningfully user-visible
  config-shape changes

## Documented Migrations

### `v1.7.0` -> `v1.8.0`

Apply these user-facing config migrations:

- if you use `lxmodules.lxbar.order`, you may now include custom widgets in the
  bar flow via `custom:<name>` entries
- define those widgets under `lxmodules.lxbar.custom_widgets`, for example:
  `mail = require("widgets.mail_imap")` or `systray = require("widgets.systray")`
- the tracked `lynxburn` setup now expects the old theme-owned IMAP and `lain`
  metric widgets to live in `lxbar`, not in `themes/lynxburn/widgets.lua`
- if you previously copied older examples using `theme.color_scheme = "default"`,
  switch to `theme.color_scheme = "lynxburn"`
  `default` still works as a compatibility alias, but it is no longer the
  canonical scheme name

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
