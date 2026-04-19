# Temporary Migration Notes

This file is temporary and only exists to get older machines from tag
`migrate` onto the current config shape.

If every target machine already runs the current tree, this file can be
discarded.

## Target Shape

The user-facing config entrypoint is top-level `config.lua`.

Tracked repo state now ships:

- `config/defaults.lua`
  shipped defaults
- `config.example.lua`
  tracked example override file
- local top-level `config.lua`
  gitignored machine-specific state

The current top-level config sections are:

1. `settings = { ... }`
2. `commands = { ... }`
3. `theme = { ... }`
4. `screens = { ... }`
5. `keys = { ... }`
6. `rules = function(context) ... end`
7. `lxmodules = { ... }`

## Important Migrations

### Bar And Module Config

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

### Popup Placement

- global side selection now lives at `lxmodules.lxbar.popup_side`
- per-popup placement values should now be `"center"` or `"side"`
- old per-popup `"left"` / `"right"` values should be removed

### Display Backend Config

- old `commands.brightness.*` -> `lxmodules.lxdisplay.brightness.*`
- old `commands.redshift.*` -> `lxmodules.lxdisplay.redshift.*`

### Runner Config

- old `lxmodules.lxrunner.options.width` -> `lxmodules.lxrunner.width`
- old `lxmodules.lxrunner.options.row_count` -> `lxmodules.lxrunner.row_count`
- old `lxmodules.lxrunner.options.history_limit` ->
  `lxmodules.lxrunner.history_limit`
- old `lxmodules.lxrunner.options.prompt` -> `lxmodules.lxrunner.prompt`
- runner aliases now belong under `lxmodules.lxrunner.aliases`

### Rules

- machine-specific application placement should now live in local `config.lua`
  under `rules = function(context) ... end`
- tracked repo defaults should stay minimal and generic

### Theme Notes

- theme overrides remain flat under `theme = { ... }`
- the runtime theme contract remains flat `beautiful.<key>`
- OSD timing and hover-close timing remain theme-owned

## Notebook Migration From `migrate`

For a notebook currently sitting on tag `migrate`:

1. Update the repo to the current state.
2. Copy `config.example.lua` to local `config.lua`.
3. Move notebook-specific values into `config.lua`, especially:
   - `settings.monitors`
   - `screens`
   - personal `commands` such as terminal, launcher, and file browser
   - `commands.autostart_once` / `commands.autostart`
   - `commands.lain.*` mail settings
   - `lxmodules.lxdisplay.redshift.*`
   - `lxmodules.lxrunner.aliases`
   - local `rules = function(context) ... end`
   - any local key overrides
4. Do not restore tracked `lxrunner/aliases.lua`; aliases now belong in
   `lxmodules.lxrunner.aliases`.
5. Delete obsolete split override files once their data has been moved.

## Cleanup After Migration

After the target machine works on the current config shape:

- delete obsolete non-example files from `config/overrides/`
- do not create new split override files
- keep future machine-local state in top-level `config.lua`
