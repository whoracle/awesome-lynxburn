# lxpower

`lxpower` is the compact AwesomeWM power-profile widget and popup used by this
config.

It exposes the current AC/battery source, current power profile, basic battery
time hints, and dGPU runtime state, then lets you switch or pin profiles from a
small popup. It is not meant to become a full power-management dashboard.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- `powerprofilesctl`
- Linux power-supply sysfs under `/sys/class/power_supply`
- Linux DRM/pci sysfs for optional dGPU runtime status detection

Internal:

- `lxcommon.popup_control`
- `lxcommon.popup_controller`
- `lxcommon.popup_session`
- `lxcommon.popup_ui`
- `lxcommon.util`
- `lxcommon.widget_feedback`

## Features

- compact top-level widget for current source/profile state
- left-click profile toggle between the active source pair
- right-click popup for direct profile selection
- profile pinning from the popup
- preferred profile memory per power source
- battery time-to-empty/time-to-full hints when available
- dGPU runtime-status display
- popup cycling participation through shared `lxbar` services

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "lxnetwork", "lxmedia", "lxnotify", "lxpower" },
    },
}
```

Direct popup use:

```lua
lxbar:toggle_popup_by_role("power", "secondary", {
    keyboard_navigation = true,
})
```

## Controls

Top-level widget:

- left click: toggle popup
- middle click: toggle between the active source profile pair
- right click: toggle pinning for the current profile

Popup:

- left click profile row: activate that profile
- right click profile row: pin that profile, or unpin it if it is already the active pinned profile
- `Up` / `Down`: move selection
- `Enter`: activate selected profile
- `Right`: pin selected profile
- `Left`: unpin current profile
- `Escape`: close popup

## Configuration

`lxpower` is configured through `lxmodules.lxpower`:

```lua
lxmodules = {
    lxpower = {
        refresh_interval = 20,
        preferred_profiles = {
            battery = "power-saver",
            ac = "balanced",
        },
    },
}
```

Supported knobs:

- `refresh_interval`
- `preferred_profiles.battery`
- `preferred_profiles.ac`

Valid preferred profile values:

- `"power-saver"`
- `"balanced"`
- `"performance"`

## Theme Variables

`lxpower` reads these `beautiful` keys:

- `lxpower_icon_ac`
- `lxpower_icon_battery`
- `lxpower_icon_pinned`
- `lxpower_icon_font`
- `lxpower_icon_width`
- `lxpower_widget_fg`
- `lxpower_widget_hover_bg`
- `lxpower_widget_press_bg`
- `lxpower_popup_bg`
- `lxpower_popup_width`
- `lxpower_popup_placement`
- `lxpower_button_hover`
- `lxpower_selected_bg`
- `lxpower_meta_fg`
- `lxpower_hover_close_timeout`
- `lxpower_hover_close_poll_interval`
- `lxpower_profile_fg_powersave`
- `lxpower_profile_fg_balanced`
- `lxpower_profile_fg_performance`

Placement is configured as `"center"` or `"side"`. When set to `"side"`, the
actual side follows `lxmodules.lxbar.popup_side`.

## Screenshots

- `[placeholder] top-level widget`
- `[placeholder] profile popup`
- `[placeholder] pinned profile state`

## File Layout

- `init.lua`: constructor, widget setup, and periodic refresh timer
- `theme.lua`: theme accessors, profile labels, and top-level widget refresh logic
- `state.lua`: sysfs/powerprofilesctl reads and profile-management behavior
- `popup.lua`: popup rendering, status lines, and popup selection state
- `controller.lua`: popup open/close, keygrabber wiring, and hover/outside-click dismissal

## Notes

- `lxpower` currently targets Linux systems exposing the expected sysfs power
  and DRM state files
- the top-level startup preflight checks `powerprofilesctl` when `lxpower` is
  enabled in `lxmodules.lxbar.order`
- no secrets or credentials are embedded in the module
