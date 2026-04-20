# lxdisplay

`lxdisplay` is the compact AwesomeWM display-side QoL module used by this
config.

Right now it owns brightness control plus built-in night-mode/redshift-style
gamma scheduling. It is intentionally not a full display manager.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- brightness backend command such as `xbacklight` or `brightnessctl`
- `xrandr` for gamma application

Internal:

- `lxcommon`
  - `osd`
  - `util`

The top-level startup preflight checks the effective brightness commands plus
the configured redshift backend command when `lxdisplay` is enabled in
`lxmodules.lxbar.order`.

## Features

- compact top-level brightness widget
- left-click absolute brightness setting on the compact bar
- scroll-based brightness control
- brightness OSD
- built-in redshift/night-mode scheduling
- sunrise/sunset scheduling when latitude/longitude are configured
- fallback clock-based day/night scheduling
- middle-click suspend/resume for redshift behavior

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "display", "network", "media", "notify" },
    },
}
```

Config example:

```lua
lxmodules = {
    lxdisplay = {
        refresh_interval = 15,
        brightness = {
            get = "xbacklight -get",
            set = "xbacklight -set %d",
            step = 5,
            min = 10,
            off = "xset dpms force off",
        },
        redshift = {
            enabled = true,
            autostart = true,
            latitude = 47.9990,
            longitude = 7.8421,
        },
    },
}
```

## Controls

Top-level widget:

- left click on compact bar: set brightness to clicked position
- middle click: toggle redshift/night mode suspend state
- scroll up: brightness up
- scroll down: brightness down

Programmatic actions:

- `brightness_up`
- `brightness_down`
- `brightness_off`
- `redshift_toggle`
- `redshift_suspend`
- `redshift_resume`

## Configuration

`lxdisplay` is configured through `lxmodules.lxdisplay`:

```lua
lxmodules = {
    lxdisplay = {
        refresh_interval = 15,
        enable_osd = true,
        osd_width = 260,
        osd_height = 18,
        osd_margin = 16,
        brightness = {
            get = "xbacklight -get",
            set = "xbacklight -set %d",
            step = 5,
            min = 10,
            off = "xset dpms force off",
        },
        redshift = {
            command = "xrandr",
            enabled = true,
            autostart = true,
            latitude = nil,
            longitude = nil,
            temperature_day = 6500,
            temperature_night = 4500,
            transition_steps = 16,
            transition_interval = 0.05,
            refresh_interval = 120,
            schedule_transition_seconds = 3600,
            day_start = "07:00",
            night_start = "19:00",
        },
    },
}
```

Supported knobs:

- `refresh_interval`
- `enable_osd`
- `osd_width`
- `osd_height`
- `osd_margin`
- `brightness.get`
- `brightness.set`
- `brightness.step`
- `brightness.min`
- `brightness.off`
- `redshift.command`
- `redshift.enabled`
- `redshift.autostart`
- `redshift.latitude`
- `redshift.longitude`
- `redshift.temperature_day`
- `redshift.temperature_night`
- `redshift.transition_steps`
- `redshift.transition_interval`
- `redshift.refresh_interval`
- `redshift.schedule_transition_seconds`
- `redshift.day_start`
- `redshift.night_start`

## Theme Variables

`lxdisplay` reads these `beautiful` keys:

- `lxdisplay_icon`
- `lxdisplay_icon_night`
- `lxdisplay_icon_brightness`
- `lxdisplay_icon_font`
- `lxdisplay_icon_width`
- `lxdisplay_widget_fg`
- `lxdisplay_widget_suspended_fg`
- `lxdisplay_bar_width`
- `lxdisplay_bar_height`
- `lxdisplay_bar_spacing`
- `lxdisplay_bar_padding`
- `lxdisplay_bar_end_margin`
- `lxdisplay_bar_bg`
- `lxdisplay_bar_fg`
- `lxdisplay_widget_hover_bg`
- `lxdisplay_widget_press_bg`
- `lxdisplay_osd_bar_bg`
- `lxdisplay_osd_bar_fg`
- `lxdisplay_osd_width`
- `lxdisplay_osd_height`
- `lxdisplay_osd_margin`
- `lxdisplay_osd_timeout`

## Screenshots

- `[placeholder] compact widget`
- `[placeholder] brightness OSD`
- `[placeholder] night-mode state`

## File Layout

- `init.lua`: constructor and instance wiring
- `helpers.lua`: pure math and scheduling helpers
- `theme.lua`: widget rendering, OSD, and theme-driven display state
- `brightness.lua`: brightness command execution and refresh flow
- `redshift.lua`: gamma application, scheduling, and transition logic

## Notes

- `lxdisplay` currently has no popup UI
- no secrets or credentials are embedded in the module
