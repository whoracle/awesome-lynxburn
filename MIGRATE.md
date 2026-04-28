# Migration Guide

This file tracks only migrations between tagged releases.

Current baseline:

- check what the latest git tag in the current worktree is and assume that as the baseline to migrate from
- the repo is allowed to be ahead of a given tag, but still assume the last tag as the baseline and check against that
- document only incremental migrations from that point forward
- do not use this file for one-off machine migration notes anymore

## Migration Policy

- add a new section when a release changes user-facing config or required local
  migration steps
- assume users migrate incrementally and do not skip documented steps
- prefer documenting migrations for breaking or meaningfully user-visible
  config-shape changes

## Documented Migrations

### `v1.8.0` -> `v1.9.0`

No required user-facing config migration is currently required.

Optional cleanup and new config surface:

- if you want `lxbar` only on selected screens, set
  `lxmodules.lxbar.screens` to configured monitor names, for example:
  `screens = { "center", "left" }`
- for `lxsecrets` GitLab entries, `secrets[].selectors` is now the canonical
  selector for the managed token; remove `token_selector` from local configs
  unless you intentionally need the backwards-compatibility override
- keep `secrets[].admin_selector` only when the admin PAT lives under different
  keyring attributes than the managed token selector
- if the managed GitLab PAT is missing but the admin PAT exists, `lxsecrets`
  can bootstrap and store the managed selector entry on a successful check or
  rotation

Internal API note for local extensions:

- popup lifecycle is now descriptor-driven through `lxcommon.popup_controller`
  and the shared popup session
- `lxmedia.popup_controller` was removed; custom code should use the public
  `lxmedia` methods such as `show_media_popup`, `show_devices_popup`, and
  `close_popups`, or register named popup descriptors through `lxcommon`

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
