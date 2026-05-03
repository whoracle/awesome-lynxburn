# lxbar

`lxbar` is the shared bar composition layer for the local `lx*` modules.

It does not create the screen wibar itself. Its job is to provide the widget
that gets placed inside the wibar, keep the visible order stable, and route
popup requests.

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
- hosting of configured custom non-`lx*` widgets inside the same bar flow
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
lxbar:toggle_popup_by_role("lxmedia", "primary", {
    keyboard_navigation = true,
})

lxbar:cycle_popups(1, {
    keyboard_navigation = true,
})
```

Custom widget example:

```lua
lxmodules = {
    lxbar = {
        order = {
            "lxnetwork",
            "lxmedia",
            "custom:mail",
            "custom:cpu",
            "custom:systray",
        },
        screens = { "center", "left" },
        custom_widgets = {
            mail = require("widgets.mail_imap"),
            cpu = require("widgets.cpu"),
            systray = require("widgets.systray"),
        },
    },
}
```

Constructor shape:

```lua
return function(context)
    return {
        widget = ...,
        width = 32,
        style = "lxbar",
    }
end
```

## Configuration

User-facing config lives under `lxmodules.lxbar`.

Current knobs:

- `lxmodules.lxbar.order`
  Final top-level widget order in the bar.

- `lxmodules.lxbar.popup_side`
  Global left/right side used when a popup chooses `"side"` placement.

- `lxmodules.lxbar.screens`
  Optional allowlist of configured screen names from `settings.monitors`.
  When set, `lxbar` is shown only on those screens.

- `lxmodules.lxbar.modules.<lxmodule>.cycle`
  Whether a visible module participates in popup cycling.

- `lxmodules.lxbar.custom_widgets`
  Map of custom widget constructors keyed by the name used in `custom:<name>`
  order entries.

Custom widgets are hosted visually inside `lxbar`, but they do not participate
in popup cycling and do not get `lx*` interaction semantics automatically.
Use the `custom:<name>` prefix in `order` so custom widgets are easy to spot.

Supported custom widget spec keys:

- `widget`
  The widget instance to host.
- `width`
  Optional exact-width constraint.
- `style`
  Visual wrapping mode:
  - `"lxbar"`: default; wrap in the normal bar shell
  - `"raw"`: host without the extra `lxbar` background/padding shell

Custom widgets are intentionally simple. If a widget needs popup cycling,
module-level key/mouse contracts, or shared popup ownership, it should become a
real `lx*` module instead of a `custom:<name>` widget.

## Theme Variables

`lxbar` does not expose its own dedicated theme variables.

The bar shell/theme is currently provided by the selected theme and the widgets
that `lxbar` hosts.

## Screenshots

- TODO: lxbar with default module set
- TODO: popup cycling demonstration

## Further Reading

- [Top-level roadmap](../ROADMAP.md)
- [lxbar spec](./SPEC.md)

## File Layout

- `init.lua`: widget composition, popup routing, and popup cycling entrypoints
