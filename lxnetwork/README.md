# lxnetwork

`lxnetwork` is the compact AwesomeWM WiFi popup used by this config.

It is intentionally narrow in scope: it shows wireless state, scans visible
networks, allows connect/toggle actions, and stops there. It is not meant to
become a full network-management shell.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- `nmcli`

Internal:

- `lxcommon.popup_control`
- `lxcommon.popup_placement`
- `lxcommon.popup_ui`
- `lxcommon.screen`
- `lxcommon.util`
- `lxcommon.widget_feedback`

## Features

- compact top-level WiFi glyph widget
- periodic refresh of wireless-enabled state and active VPN presence
- popup with:
  - current connection summary
  - known visible networks
  - additional visible networks
  - keyboard selection support
- WiFi rescan action
- WiFi enable/disable action
- direct connect for known/open networks
- password prompt for secured unknown networks
- popup cycling participation through shared `lxbar` services

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "lxnetwork", "lxmedia", "lxnotify" },
    },
}
```

Keybinding via popup cycling or direct popup toggle:

```lua
lxbar:toggle_popup_by_role("network", "primary", {
    keyboard_navigation = true,
})
```

## Controls

Top-level widget:

- left click: toggle popup
- right click: rescan visible networks

Popup:

- `Up` / `Down`: move selection
- `Enter`: activate selected action or connect to selected network
- `Escape`: close popup
- shared popup prev/next keychains continue cycling when passed in through
  `lxbar`

Password prompt:

- text entry goes straight to the prompt buffer
- `BackSpace`: delete one character
- `Enter`: submit password and connect
- `Escape`: cancel

## Configuration

`lxnetwork` is configured through `lxmodules.lxnetwork`:

```lua
lxmodules = {
    lxnetwork = {
        refresh_interval = 20,
    },
}
```

Supported knobs:

- `refresh_interval`

## Theme Variables

`lxnetwork` reads these `beautiful` keys:

- `lxnetwork_icon`
- `lxnetwork_icon_disabled`
- `lxnetwork_icon_font`
- `lxnetwork_icon_width`
- `lxnetwork_widget_fg`
- `lxnetwork_widget_disabled_fg`
- `lxnetwork_widget_vpn_fg`
- `lxnetwork_widget_hover_bg`
- `lxnetwork_widget_press_bg`
- `lxnetwork_popup_bg`
- `lxnetwork_popup_width`
- `lxnetwork_popup_placement`
- `lxnetwork_button_hover`
- `lxnetwork_selected_bg`
- `lxnetwork_meta_fg`
- `lxnetwork_signal_bar_width`
- `lxnetwork_signal_bar_bg`
- `lxnetwork_signal_bar_fg`
- `lxnetwork_hover_close_timeout`
- `lxnetwork_hover_close_poll_interval`

Placement is configured as `"center"` or `"side"`. When set to `"side"`, the
actual side follows `lxmodules.lxbar.popup_side`.

## Screenshots

- `[placeholder] top-level widget`
- `[placeholder] network popup`
- `[placeholder] password prompt`

## File Layout

- `init.lua`: constructor, widget setup, and periodic refresh timer
- `theme.lua`: theme accessors and top-level widget refresh logic
- `state.lua`: `nmcli` parsing, connection refresh, scan, and connect behavior
- `popup.lua`: popup rendering, network rows, and popup selection state
- `password_prompt.lua`: password prompt lifecycle and input handling
- `controller.lua`: popup open/close, keygrabber wiring, and hover/outside-click dismissal

## Notes

- `lxnetwork` currently only handles WiFi state through `nmcli`
- the top-level startup preflight checks `nmcli` when `lxnetwork` is enabled in
  `lxmodules.lxbar.order`
- no embedded secrets or machine-specific credentials are stored in the module
