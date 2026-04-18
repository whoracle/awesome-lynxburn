# Migration Notes

This repo no longer reads split `config/override/*.lua` files at runtime.

The user-facing config entrypoint is top-level `config.lua`.

## Current Target Shape

Move legacy config into these sections:

1. `settings = { ... }`
2. `commands = { ... }`
3. `theme = { ... }`
4. `screens = { ... }`
5. `keys = { ... }`
6. `rules = function(context) ... end`
7. `lxmodules = { ... }`

## Key Migrations

### Bar and module config

- old `widgets.order` -> `lxmodules.lxbar.order`
- old `widgets.modules.<name>.cycle` -> `lxmodules.lxbar.modules.<name>.cycle`
- old `widgets.modules.<name>.*` runtime behavior ->
  `lxmodules.lx<name>.*`

Examples:

- `widgets.modules.audio.refresh_interval` ->
  `lxmodules.lxmedia.refresh_interval`
- `widgets.modules.notify.popup_visible_items` ->
  `lxmodules.lxnotify.popup_visible_items`
- `widgets.modules.powerprofiles.refresh_interval` ->
  `lxmodules.lxpower.refresh_interval`

### Popup placement

- global side selection now lives at `lxmodules.lxbar.popup_side`
- per-popup placement values should be `"center"` or `"side"`
- remove old per-popup `"left"` / `"right"` values

### Display backend config

- old `commands.brightness.*` -> `lxmodules.lxdisplay.brightness.*`
- old `commands.redshift.*` -> `lxmodules.lxdisplay.redshift.*`

### Runner config

- old `lxmodules.lxrunner.options.width` -> `lxmodules.lxrunner.width`
- old `lxmodules.lxrunner.options.row_count` -> `lxmodules.lxrunner.row_count`
- old `lxmodules.lxrunner.options.history_limit` ->
  `lxmodules.lxrunner.history_limit`
- old `lxmodules.lxrunner.options.prompt` -> `lxmodules.lxrunner.prompt`
- old runner aliases belong under `lxmodules.lxrunner.aliases`

## Theme Notes

- OSD timing and hover-close timing remain theme-owned
- flat theme overrides still go in `theme = { ... }`
- the runtime theme contract is flat `beautiful.<key>`

## Cleanup After Migration

Once the live config has copied over the values it still needs:

- delete obsolete non-example files from `config/override/`
- do not create new split override files
