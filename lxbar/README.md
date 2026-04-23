# lxbar

`lxbar` is the small shared bar composition layer for the local `lx*` modules.

It is responsible for:

- composing registered top-level module widgets into one horizontal layout
- honoring configured module order
- routing popup open/toggle calls by module and semantic popup role
- owning popup cycling across registered modules

## Dependencies

External runtime:

- AwesomeWM

Awesome/Lua libraries:

- `wibox`

Other local modules:

- `lxcommon.registry`
- `lxcommon.popup_manager`

`lxbar` does not directly depend on individual modules; they register themselves
through `config.services` and `lxcommon.registry`.

## Feature List

- horizontal composition of registered module widgets
- bar order based on registry order / configured `lxmodules.lxbar.order`
- popup open/toggle routing by module id and popup id
- popup open/toggle routing by semantic popup role
- popup cycling in final visible widget order

## Example Usage

Basic use from the service layer or directly:

```lua
local lxbar = require("lxbar").new()

some_wibar:setup({
    layout = wibox.layout.align.horizontal,
    nil,
    nil,
    lxbar.widget,
})
```

Popup routing examples:

```lua
lxbar:toggle_popup_by_role("media", "primary", {
    keyboard_navigation = true,
})

lxbar:cycle_popups(1, {
    keyboard_navigation = true,
})
```

## Configuration

User-facing config lives under `lxmodules.lxbar`.

Current knobs:

- `lxmodules.lxbar.order`
  Final top-level widget order in the bar.

- `lxmodules.lxbar.popup_side`
  Global left/right side used when a popup chooses `"side"` placement.

- `lxmodules.lxbar.modules.<lxname>.cycle`
  Whether a visible module participates in popup cycling.

## Theme Variables

`lxbar` does not expose its own dedicated theme variables.

The bar shell/theme is currently provided by the selected theme and the widgets
that `lxbar` hosts.

## Screenshots

- TODO: lxbar with default module set
- TODO: popup cycling demonstration

## File Layout

- `init.lua`: widget composition, popup routing, and popup cycling entrypoints
