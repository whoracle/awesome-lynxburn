# Remaining Migration Notes

The repo runtime no longer depends on split `config/override/*.lua` files.

For a live config migration, move any remaining data from non-example files in
`~/.config/awesome/config/override/` into top-level `~/.config/awesome/config.lua`.

Current target sections are:

1. `settings.lua` -> `settings = { ... }`
2. `programs.lua` -> `commands = { ... }`
3. `theme.lua` -> `theme = { ... }`
4. `screens.lua` -> `screens = { ... }`
5. `keys.lua` -> `keys = { ... }`
6. `rules.lua` -> `rules = function(context) ... end`
7. `lxrunner_aliases.lua` -> `lxmodules = { lxrunner = { aliases = { ... } } }`

Module- and bar-related config should now live under `lxmodules`, for example:

- `lxmodules.lxbar.order`
- `lxmodules.lxbar.modules.network.cycle`
- `lxmodules.lxdisplay.redshift`
- `lxmodules.lxrunner.aliases`

Notebook migration checklist for the current session's config-shape changes:

1. Remove any remaining top-level `widgets = { ... }` config.
2. Move bar composition into `lxmodules.lxbar`, for example:
   - `widgets.order` -> `lxmodules.lxbar.order`
   - `widgets.modules.<name>.cycle` -> `lxmodules.lxbar.modules.<name>.cycle`
3. Move per-module behavior out of `widgets.modules.<name>` into
   `lxmodules.lx<name>`, for example:
   - `widgets.modules.audio.refresh_interval` -> `lxmodules.lxmedia.refresh_interval`
   - `widgets.modules.notify.popup_visible_items` -> `lxmodules.lxnotify.popup_visible_items`
   - `widgets.modules.powerprofiles.refresh_interval` -> `lxmodules.lxpower.refresh_interval`
4. Move display backend/module config out of `commands` and into
   `lxmodules.lxdisplay`:
   - `commands.brightness.*` -> `lxmodules.lxdisplay.brightness.*`
   - `commands.redshift.*` -> `lxmodules.lxdisplay.redshift.*`
5. Flatten runner config:
   - `lxmodules.lxrunner.options.width` -> `lxmodules.lxrunner.width`
   - `lxmodules.lxrunner.options.row_count` -> `lxmodules.lxrunner.row_count`
   - `lxmodules.lxrunner.options.history_limit` -> `lxmodules.lxrunner.history_limit`
   - `lxmodules.lxrunner.options.prompt` -> `lxmodules.lxrunner.prompt`
6. Do not copy visibility timeout settings into centralized config:
   - OSD timeouts and hover-close timing remain theme-owned
   - keep those in `theme = { ... }` or the selected theme file
7. Module presence in `lxbar` is now controlled by `lxmodules.lxbar.order`:
   - remove any legacy `widgets.modules.<name>.enabled` settings
   - if a module should not appear in the bar, leave it out of `lxmodules.lxbar.order`
8. After copying the migrated data, delete obsolete non-example files in
   `~/.config/awesome/config/override/`.

Once the live machine has copied over anything it still needs, the remaining
non-example files in `config/override/` can be deleted there as well.
