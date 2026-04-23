# lxdisplay

`lxdisplay` is the compact AwesomeWM display-side QoL module used by this
config.

Right now it owns brightness control, built-in night-mode/redshift-style gamma
scheduling, and a compact `xrandr`-driven popup for activating configured
display profiles or attaching transient displays. It is intentionally not a
full display manager.

If `lxmodules.lxdisplay.profiles` is unset, the display-management popup is
disabled and the module stays in brightness/redshift-only mode.

If profiles are configured, `lxdisplay` auto-applies one on startup by default.
Set `auto_apply = false` to disable that behavior while debugging.

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
the `xrandr`-compatible command used for redshift and display-profile actions
when `lxdisplay` is enabled in `lxmodules.lxbar.order`.

## Features

- compact top-level brightness widget
- left-click absolute brightness setting on the compact bar
- right-click popup for display profiles and transient display actions
- scroll-based brightness control
- brightness OSD
- built-in redshift/night-mode scheduling
- sunrise/sunset scheduling when latitude/longitude are configured
- fallback clock-based day/night scheduling
- middle-click suspend/resume for redshift behavior
- config-driven `xrandr` display profiles with passthrough output arguments
- one-shot detection for transient displays outside the active profile
- startup auto-apply for one chosen profile, with a panic mirror fallback

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "lxdisplay", "lxnetwork", "lxmedia", "lxnotify" },
    },
}
```

Config example:

```lua
lxmodules = {
    lxdisplay = {
        auto_apply = false,
        refresh_interval = 15,
        profiles = {
            {
                name = "Roadwarrior (Mobile)",
                default = true,
                outputs = {
                    ["eDP-1"] = {
                        mode = "auto",
                        primary = true,
                    },
                },
            },
        },
        detected = {
            extend_relative_to = "profile-primary",
            extend_direction = "left",
        },
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
- right click: open display-profile popup
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
        auto_apply = true,
        refresh_interval = 15,
        enable_osd = true,
        osd_width = 260,
        osd_height = 18,
        osd_margin = 16,
        profiles = {
            {
                name = "Battlestation (Home)",
                default = true,
                outputs = {
                    ["eDP-1"] = {
                        mode = "auto",
                        primary = true,
                    },
                    ["HDMI-1"] = {
                        mode = "auto",
                        left_of = "eDP-1",
                    },
                },
            },
        },
        detected = {
            extend_relative_to = "profile-primary",
            extend_direction = "left",
        },
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
- `auto_apply`
- `enable_osd`
- `osd_width`
- `osd_height`
- `osd_margin`
- `profiles`
- `profiles[].name`
- `profiles[].default`
- `profiles[].outputs`
- `profiles[].outputs.<output>.mode`
- `profiles[].outputs.<output>.friendly_name`
- `profiles[].outputs.<output>.optional`
- `profiles[].outputs.<output>.initial_state`
- `profiles[].outputs.<output>.*`
- `detected.extend_relative_to`
- `detected.extend_direction`
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

If `profiles` is `nil` or omitted, `lxdisplay` does not register a popup and
does not perform display-profile or transient-display actions.

Startup profile selection works like this:

- no profiles: do nothing
- one profile: use it automatically
- multiple profiles with exactly one `default = true`: use that one
- multiple profiles with no default or multiple defaults: notify, then fall back
  to the first profile

If startup profile application fails, `lxdisplay` falls back to a hardcoded
panic layout that enables all connected outputs with `--auto` and mirrors them
to the primary output so some screen stays usable.

`profiles[].outputs.<output>.mode` is special-cased:

- `"auto"` becomes `--auto`
- any other string becomes `--mode <value>`

Every other output key is passed through to `xrandr` by turning underscores
into dashes and prefixing `--`. Examples:

- `left_of = "eDP-1"` becomes `--left-of eDP-1`
- `rotate = "left"` becomes `--rotate left`
- `primary = true` becomes `--primary`

`friendly_name` is display-only metadata for the popup/profile summaries and is
not passed through to `xrandr`.

Optional outputs stay attached to a profile without making the profile fail
when the hardware is absent:

- `optional = true` means that output may be missing without invalidating the
  profile
- `initial_state = "on" | "off"` controls whether a connected optional output
  is enabled or forced off when the profile is applied
- optional outputs stay visible in the popup layout summary even when off
- optional outputs that are currently off are rendered with the optional-output
  theme color instead of disappearing from the layout summary

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
- `lxdisplay_popup_width`
- `lxdisplay_popup_placement`
- `lxdisplay_popup_bg`
- `lxdisplay_button_hover`
- `lxdisplay_selected_bg`
- `lxdisplay_meta_fg`
- `lxdisplay_optional_fg`
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
- `[placeholder] display profile popup`
- `[placeholder] brightness OSD`
- `[placeholder] night-mode state`

## File Layout

- `init.lua`: constructor and instance wiring
- `helpers.lua`: pure math and scheduling helpers
- `displays.lua`: display-profile normalization, detection, and `xrandr` apply logic
- `popup.lua`: popup rendering and popup-selection behavior
- `theme.lua`: widget rendering, OSD, and theme-driven display state
- `brightness.lua`: brightness command execution and refresh flow
- `redshift.lua`: gamma application, scheduling, and transition logic

## Notes

- active-profile applies fail loudly when a configured output is not connected
- no secrets or credentials are embedded in the module
