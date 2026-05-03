# Migration Guide

This file tracks only migrations between tagged releases.

Use the section matching the version you are upgrading from. If you upgrade
across multiple releases, apply each section in order.

When the repository is ahead of the latest release tag, the topmost section may
use `` `latest-tag` -> `next` `` until the next release exists.

## Migration Policy

- add a new section when a release changes user-facing config or required local
  migration steps
- assume users migrate incrementally and do not skip documented steps
- prefer documenting migrations for breaking or meaningfully user-visible
  config-shape changes

## Documented Migrations

### `v1.10.0` -> `v1.11.0`

Apply these user-facing migrations when moving from `v1.10.0` to `v1.11.0`:

- if you want to run the same checkout under SomeWM, set the top-level
  platform in that checkout's `config.lua`:
  - `platform = "somewm"` for SomeWM/Wayland
  - `platform = "awesome"` for AwesomeWM/X11 when you want to be explicit
- keyboard layout setup now has a shared config surface:
  `settings.keyboard.layout`, `settings.keyboard.variant`, and
  `settings.keyboard.options`
  - AwesomeWM/X11 applies this through `setxkbmap`
  - SomeWM/Wayland applies this through `awful.input.xkb_*`
  - remove any duplicate local autostart keyboard command if you move it into
    `settings.keyboard`
- SomeWM/Wayland defaults use different external tools from the X11 defaults:
  `foot`, `grim`, `slurp`, `brightnessctl`, `wlopm`, `wlr-randr`, and optional
  `wl-paste`
  - install these if you enable the SomeWM path and keep the shipped defaults
  - override the relevant `commands` / `lxmodules.lxdisplay` values if you use
    different Wayland tooling
- `config.minimal.example.lua`, `config.awesome.example.lua`, and
  `config.somewm.example.lua` are now tracked starter/reference files
  - existing `config.lua` files do not need to be replaced
  - use the new examples only as references for local cleanup or a new checkout

Internal API note for local extensions:

- popup keyboard input ownership is now centralized in `lxcommon`; local code
  that reached into module-specific popup keygrabber state should move to the
  shared popup-controller/session APIs
- `lxdisplay` profile application now goes through backend files for X11 and
  SomeWM; local code should not assume direct `xrandr` command construction
  outside the backend boundary

### `v1.9.0` -> `v1.10.0`

Apply these user-facing migrations when moving from `v1.9.0` to `v1.10.0`:

- `lxrunner` launch history moved from the previous escaped TSV file to a
  versioned JSON object; no backwards-compatible TSV reader is kept
  - keep the default file path as `~/.lxrunner_history`
  - migrate or delete the live `~/.lxrunner_history` before relying on old
    launch history after upgrading
  - expected JSON shape:
    `{ "format": "lxrunner-history", "version": 1, "entries": [ ... ] }`
  - non-alias entries should contain at least `last_used`, `launch_source`,
    `count`, `name`, and `command`
  - alias entries should contain `last_used`, `launch_source = "alias"`,
    `count`, `name`, `alias_name`, and optional `alias_args`
  - local aliases from `lxmodules.lxrunner.aliases` resolve from `config.lua`;
    the history file stores alias identity instead of resolved shell commands
- `lain` has been removed as a dependency; if your local config still uses
  `commands.lain` for the bundled IMAP custom widget, rename that table to
  `commands.imap`
- third-party layouts can now be registered through top-level `layouts.custom`
  and configured through `layouts.setup`; this is the intended way to opt into
  external layouts such as `lain` without editing repo-owned files

### `v1.8.0` -> `v1.9.0`

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
- the tracked `lynxburn` setup now expects the old theme-owned IMAP and metric
  widgets to live in `lxbar`, not in `themes/lynxburn/widgets.lua`
- if you previously copied older examples using `theme.color_scheme = "default"`,
  switch to `theme.color_scheme = "lynxburn"`
  `default` still works as a compatibility alias, but it is no longer the
  canonical scheme name

### `v1.6.0` -> `v1.7.0`

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
