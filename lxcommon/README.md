# lxcommon

`lxcommon` is the shared helper layer used by the local `lx*` modules.

It is not a standalone end-user widget. Its job is to hold small reusable
pieces that would otherwise be duplicated across popup-oriented modules.

## Dependencies

External runtime:

- AwesomeWM

Awesome/Lua libraries:

- `awful`
- `gears`
- `naughty`
- `wibox`
- `beautiful`

Other local modules:

- none required; this is the shared layer itself

## Feature List

- shared popup placement helpers
- shared popup registration and cycling helpers
- shared popup key, outside-click, optional hover-close, and best-effort global
  shortcut fallback helpers
- shared named-popup descriptor controller/session wiring for popup-oriented
  modules
- shared popup shell/session for swapping popup contents during cycling
- shared popup UI row/card helpers
- shared widget feedback/highlight syncing
- shared compact OSD helper

## Example Usage

Used from other modules, not directly from `lxbar`.

```lua
local popup_control = require("lxcommon.popup_control")
local popup_ui = require("lxcommon.popup_ui")
local popup_placement = require("lxcommon.popup_placement")
local widget_feedback = require("lxcommon.widget_feedback")
```

Example popup row usage:

```lua
local popup_ui = require("lxcommon.popup_ui")

local row = popup_ui.make_selectable_click_row("Example", function()
    print("clicked")
end, {
    selected = true,
    inner_bg = "#222222",
    hover_bg = "#444444",
    outer_bg = "#222222",
    selected_bg = "#666666",
})
```

## Configuration

`lxcommon` does not expose its own user-facing config section.

It reads shared environment indirectly through:

- module theme keys (`beautiful.lx*`)
- `lxmodules.lxbar.popup_side` for shared `"side"` popup placement resolution

## Theme Variables

`lxcommon` does not define its own dedicated `beautiful.lxcommon_*` surface.

It consumes generic theme values indirectly through callers, for example:

- `beautiful.notification_bg`
- `beautiful.notification_fg`
- `beautiful.bg_normal`
- `beautiful.bg_minimize`
- `beautiful.fg_normal`

Popup UI helpers themselves are driven by the colors and spacing passed in by
the calling module rather than by `lxcommon`-specific theme variables.

## Screenshots

- TODO: popup helper examples
- TODO: shared OSD example

## File Layout

- `init.lua`: convenience aggregator for the shared helper modules
- `osd.lua`: compact shared OSD helper used by display/media
- `popup_control.lua`: popup key handling, global-key fallback, outside-click
  dismissal, optional hover-close timers, and keygrabber lifecycle helpers
- `popup_controller.lua`: named popup descriptor wiring used by modules to
  delegate popup lifecycle, key handling, outside-click dismissal, and shared
  session integration to `lxcommon`
- `popup_manager.lua`: popup registration, deterministic active-popup tracking,
  and cycle-order resolution
- `popup_placement.lua`: shared `"center"` / `"side"` popup placement logic
- `popup_session.lua`: shared popup shell used to swap popup contents
  without hiding the top-level popup between cycle steps
- `popup_ui.lua`: reusable popup rows, cards, and button-feedback helpers
- `registry.lua`: shared top-level widget registry used by `lxbar`
- `widget_feedback.lua`: shared top-level widget highlight syncing helpers
- `dkjson.lua`: vendored JSON helper used by repo-owned modules without
  depending on `lain` internals
