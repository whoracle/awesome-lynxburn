# lxbluetooth

`lxbluetooth` is the compact AwesomeWM Bluetooth widget and popup used by this
config.

It is intentionally small: it shows controller power state, lists paired
devices, and exposes quick connect/disconnect and power actions. It is not
meant to replace a full Bluetooth manager.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- `bluetoothctl`
- `blueman-manager` for the external full manager action

Internal:

- `lxcommon.popup_control`
- `lxcommon.popup_placement`
- `lxcommon.popup_ui`
- `lxcommon.screen`
- `lxcommon.util`
- `lxcommon.widget_feedback`

## Features

- compact top-level Bluetooth glyph widget
- periodic refresh of controller power state
- popup with:
  - open-manager action
  - controller power toggle
  - paired device list
  - connect/disconnect actions
  - keyboard selection support
- middle-click controller power toggle on the top-level widget
- popup cycling participation through shared `lxbar` services

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "lxbluetooth", "lxnetwork", "lxmedia", "lxnotify" },
    },
}
```

Direct popup use:

```lua
lxbar:toggle_popup_by_role("bluetooth", "primary", {
    keyboard_navigation = true,
})
```

## Controls

Top-level widget:

- left click: toggle popup
- middle click: toggle controller power
- right click: open `blueman-manager`

Popup:

- left click action row: trigger that action
- left click device row: connect or disconnect that device
- right click: no secondary action
- `Up` / `Down`: move selection
- `Enter`: activate selected action or connect/disconnect selected device
- `Escape`: close popup
- `Left` / `Right`: no special action

## Configuration

`lxbluetooth` is configured through `lxmodules.lxbluetooth`:

```lua
lxmodules = {
    lxbluetooth = {
        refresh_interval = 15,
    },
}
```

Supported knobs:

- `refresh_interval`

## Theme Variables

`lxbluetooth` reads these `beautiful` keys:

- `lxbluetooth_icon`
- `lxbluetooth_icon_font`
- `lxbluetooth_icon_width`
- `lxbluetooth_widget_fg`
- `lxbluetooth_widget_disabled_fg`
- `lxbluetooth_widget_hover_bg`
- `lxbluetooth_widget_press_bg`
- `lxbluetooth_popup_bg`
- `lxbluetooth_popup_width`
- `lxbluetooth_popup_placement`
- `lxbluetooth_button_hover`
- `lxbluetooth_selected_bg`
- `lxbluetooth_meta_fg`
- `lxbluetooth_hover_close_timeout`
- `lxbluetooth_hover_close_poll_interval`

Placement is configured as `"center"` or `"side"`. When set to `"side"`, the
actual side follows `lxmodules.lxbar.popup_side`.

## Screenshots

- `[placeholder] top-level widget`
- `[placeholder] bluetooth popup`
- `[placeholder] paired device list`

## File Layout

- `init.lua`: constructor, widget setup, and periodic refresh timer
- `theme.lua`: theme accessors and top-level widget refresh logic
- `state.lua`: bluetoothctl parsing, manager launch, power toggle, and device refresh
- `popup.lua`: popup rendering, device rows, and popup selection state
- `controller.lua`: popup open/close, keygrabber wiring, and hover/outside-click dismissal

## Notes

- `lxbluetooth` currently works with paired devices exposed through
  `bluetoothctl`
- the top-level startup preflight checks `bluetoothctl` and the configured
  `blueman-manager` command when `lxbluetooth` is enabled in
  `lxmodules.lxbar.order`
- no secrets or credentials are embedded in the module
