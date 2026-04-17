# lxaudio

`lxaudio` is an AwesomeWM audio widget for PipeWire/PulseAudio setups.

It shows:

- current default output volume
- mute state
- default input volume when a recording stream is active
- microphone activity indicator
- active playback streams
- available output and input devices
- basic MPRIS media controls for matched players

The main widget is compact, and it opens two popups:

- left click: playback streams and media controls
- right click: output/input device selection

## What It Does

At a high level, the project combines three pieces:

- a small bar widget that displays speaker state plus microphone activity and input volume while recording is active
- a playback popup that lists active sink inputs, lets you reroute them, and exposes play/pause/next/previous controls when a matching MPRIS player is found
- a device popup that lets you switch the default sink and source, plus open `pavucontrol`

The widget refreshes on a timer and also subscribes to `pactl subscribe` so it reacts to most audio changes quickly.

## Dependencies

This project is meant for AwesomeWM and assumes a Linux desktop with PulseAudio-compatible tooling available.

Required runtime dependencies:

- AwesomeWM with Lua support
- `pactl`
- Awesome libraries used by the widget: `awful`, `gears`, `wibox`, `beautiful`

Optional but recommended:

- `wpctl`
  Used for default sink volume and mute control when available.
- `playerctl`
  Enables player discovery, metadata, artwork lookup, and transport controls in the media popup.
- `pavucontrol`
  Used by the "Open pavucontrol" action in the devices popup.

Notes:

- `pactl` is still required even if `wpctl` is available, because stream and device enumeration is built around `pactl`.
- The widget can still render without `playerctl`, but media-player matching and transport controls will be unavailable.

## Installation

Place the project somewhere Awesome can `require`, with the module directory named `lxaudio`.

Example layout:

```text
~/.config/awesome/
├── rc.lua
└── lxaudio/
    ├── init.lua
    ├── audio.lua
    ├── media.lua
    ├── popup_devices.lua
    ├── popup_media.lua
    ├── popup_common.lua
    ├── util.lua
    └── widget.lua
```

Then require it from your Awesome config.

## Usage

Basic example in `rc.lua`:

```lua
local awful = require("awful")
local wibox = require("wibox")
local lxaudio = require("lxaudio")

local audio = lxaudio.new()

awful.screen.connect_for_each_screen(function(s)
    s.mywibox = awful.wibar({ position = "top", screen = s })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        nil,
        nil,
        {
            layout = wibox.layout.fixed.horizontal,
            audio.widget,
        },
    }
end)
```

You create an instance with `lxaudio.new(opts)` and place `instance.widget` anywhere a normal Awesome widget can be used.

### Mouse Controls

On the main widget:

- left click: toggle playback popup
- right click: toggle devices popup
- middle click on the output section: mute/unmute default sink
- scroll on the output section: change default sink volume
- middle click on the mic section: mute/unmute all non-monitor inputs
- scroll on the mic section: change default source volume

Inside the playback popup:

- left click a stream card: expand/collapse routing details
- middle click a stream card: mute/unmute that sink input
- scroll over a stream card: change that sink input volume
- click route targets: move the stream to another sink
- click transport buttons: previous, play/pause, next

Inside the devices popup:

- click an output: set it as default sink
- click an input: set it as default source
- click "Open pavucontrol": launch `pavucontrol`

## Configuration

`lxaudio.new(opts)` supports these options:

| Option | Default | Meaning |
| --- | --- | --- |
| `show_mic_activity` | `true` | Show the microphone icon and microphone volume bar when source outputs are active. |
| `refresh_interval` | `5` | Polling interval in seconds. |
| `width` | `50` | Width of the volume bar in the compact widget. |
| `step` | `0.05` | Volume step for scroll actions, expressed as `0.05 == 5%`. |
| `icon_muted` | `beautiful.lxaudio_icon_muted` or `" "` | Icon shown when the default output is muted. |
| `icon_unmuted` | `beautiful.lxaudio_icon_volume` or `" "` | Icon shown when the default output is not muted. |
| `icon_mic_active` | `beautiful.lxaudio_icon_mic_active` or `"🎙"` | Icon shown when microphone activity is detected. |
| `hover_close_timeout` | `beautiful.lxaudio_hover_close_timeout` or `1.5` | Seconds the pointer must stay outside the popup and anchor before auto-close. |
| `hover_close_poll_interval` | `beautiful.lxaudio_hover_close_poll_interval` or `0.25` | Poll interval used by the hover-close logic. |

Example:

```lua
local lxaudio = require("lxaudio")

local audio = lxaudio.new({
    width = 72,
    step = 0.02,
    refresh_interval = 2,
    show_mic_activity = false,
    icon_muted = "M ",
    icon_unmuted = "V ",
    icon_mic_active = "MIC",
})
```

Useful instance methods:

- `instance:refresh()`
  Refresh widget state immediately.
- `instance:reload()`
  Rebuild the internal widget and restart the timer.
- `instance:toggle_mute()`
  Toggle mute on the default sink.
- `instance:change_volume(delta)`
  Change default sink volume by a signed fractional step such as `0.05` or `-0.05`.
- `instance:volume_up(step)`
  Increase volume by `step` or the configured default `opts.step`.
- `instance:volume_down(step)`
  Decrease volume by `step` or the configured default `opts.step`.
- `instance:toggle_input_mute()`
  Toggle mute for all non-monitor input devices.
- `instance:change_input_volume(delta)`
  Change default input volume by a signed fractional step such as `0.05` or `-0.05`.
- `instance:input_volume_up(step)`
  Increase input volume by `step` or the configured default `opts.step`.
- `instance:input_volume_down(step)`
  Decrease input volume by `step` or the configured default `opts.step`.
- `instance:close_popups()`
  Close any open popups.
- `instance:toggle_media_popup(anchor_geo_or_opts, opts)`
  Toggle the playback popup manually. Supports `anchor = "widget"` or `anchor = "center"`.
- `instance:toggle_devices_popup(anchor_geo_or_opts, opts)`
  Toggle the device popup manually. Supports `anchor = "widget"` or `anchor = "center"`.
- `instance:show_media_popup(anchor_geo, opts)`
  Show the playback popup without toggling it off if already visible.
- `instance:show_devices_popup(anchor_geo, opts)`
  Show the device popup without toggling it off if already visible.

### Keyboard Shortcuts

The instance API is intended to be usable from Awesome keybindings.

Example:

```lua
local awful = require("awful")
local gears = require("gears")
local lxaudio = require("lxaudio")

local audio = lxaudio.new({
    step = 0.05,
})

root.keys(gears.table.join(
    root.keys(),
    awful.key({}, "XF86AudioRaiseVolume", function()
        audio:volume_up()
    end),
    awful.key({}, "XF86AudioLowerVolume", function()
        audio:volume_down()
    end),
    awful.key({}, "XF86AudioMute", function()
        audio:toggle_mute()
    end),
    awful.key({ "Mod4" }, "p", function()
        audio:toggle_media_popup({
            hover_close = false,
            anchor = "center",
        })
    end),
    awful.key({ "Mod4", "Shift" }, "p", function()
        audio:toggle_devices_popup({
            hover_close = false,
            anchor = "center",
        })
    end),
    awful.key({}, "Escape", function()
        audio:close_popups()
    end)
))
```

Notes:

- `toggle_*_popup({ hover_close = false, anchor = "center" })` is the keyboard-friendly form. It uses one key to open or close the popup, centers it on the focused screen, and disables the "mouse leaves popup" auto-close timer.
- `toggle_*_popup(mouse.current_widget_geometry)` remains the mouse-oriented form and anchors the popup to the widget.
- `anchor = "widget"` asks the popup to anchor to the widget even when no explicit geometry is passed. `anchor = "center"` forces centered placement on the focused screen.
- For keyboard-driven volume control, `volume_up()`, `volume_down()`, and `toggle_mute()` use the same backend logic as the widget mouse bindings.

## Theming

The widget reads colors, dimensions, and icons from `beautiful`.

Supported theme keys:

| Theme Variable | Purpose |
| --- | --- |
| `beautiful.lxaudio_icon_muted` | Muted speaker icon. |
| `beautiful.lxaudio_icon_volume` | Unmuted speaker icon. |
| `beautiful.lxaudio_icon_mic_active` | Microphone activity icon. |
| `beautiful.lxaudio_widget_muted_fg` | Foreground color of the compact icon while muted. |
| `beautiful.lxaudio_widget_fg` | Foreground color of the compact icon while unmuted. |
| `beautiful.lxaudio_widget_mic_fg` | Foreground color of the mic activity icon. |
| `beautiful.lxaudio_widget_mic_muted_fg` | Foreground color of the mic icon while recording inputs are muted. |
| `beautiful.lxaudio_bar_bg` | Background color of the volume bar. |
| `beautiful.lxaudio_bar_fg` | Fill color of the volume bar. |
| `beautiful.lxaudio_mic_bar_bg` | Background color of the microphone volume bar. |
| `beautiful.lxaudio_mic_bar_fg` | Fill color of the microphone volume bar. |
| `beautiful.lxaudio_bg_hover` | Hover background used in popup rows. |
| `beautiful.lxaudio_button_bg` | Media transport button background. |
| `beautiful.lxaudio_button_hover` | Media transport button hover background. |
| `beautiful.lxaudio_popup_width_media` | Width of the playback popup. |
| `beautiful.lxaudio_popup_width_devices` | Width of the device popup. |
| `beautiful.lxaudio_artwork_width` | Target artwork width in the playback popup. |
| `beautiful.lxaudio_artwork_max_height` | Maximum rendered artwork height. |
| `beautiful.lxaudio_hover_close_timeout` | Hover-close timeout override. |
| `beautiful.lxaudio_hover_close_poll_interval` | Hover-close poll interval override. |

Example theme snippet:

```lua
beautiful.lxaudio_icon_muted = "mute "
beautiful.lxaudio_icon_volume = "vol "
beautiful.lxaudio_icon_mic_active = "rec"

beautiful.lxaudio_widget_fg = "#e8d7b6"
beautiful.lxaudio_widget_muted_fg = "#9b8f86"
beautiful.lxaudio_widget_mic_fg = "#ff7a7a"
beautiful.lxaudio_widget_mic_muted_fg = "#9b8f86"

beautiful.lxaudio_bar_bg = "#221917"
beautiful.lxaudio_bar_fg = "#e0b56a"
beautiful.lxaudio_mic_bar_bg = "#221917"
beautiful.lxaudio_mic_bar_fg = "#d98f8f"

beautiful.lxaudio_bg_hover = "#3a2f2b"
beautiful.lxaudio_button_bg = "#2c2320"
beautiful.lxaudio_button_hover = "#5b3d28"

beautiful.lxaudio_popup_width_media = 360
beautiful.lxaudio_popup_width_devices = 360

beautiful.lxaudio_artwork_width = 420
beautiful.lxaudio_artwork_max_height = 680
```

Fallbacks:

- if a custom `lxaudio_*` theme variable is missing, the code falls back to common Awesome theme colors such as `fg_normal`, `bg_minimize`, `bg_focus`, and `fg_urgent`
- if an icon variable is missing, built-in text icons are used

## Known Limitations And Edge Cases

- AwesomeWM-only: this is not a general Lua library and expects the Awesome widget/runtime environment.
- Linux audio stack assumptions: the implementation is built around `pactl`, with optional `wpctl` and `playerctl`.
- Stream-to-player matching is heuristic-based: browser tabs, unusual player names, sandboxed apps, and custom MPRIS names may not match the expected media player.
- Artwork support is limited to `file://` art URLs exposed by `playerctl`. Remote URLs are ignored.
- Mic activity is inferred from active source outputs, not actual input level, so the mic icon and mic volume bar are shown based on recording activity rather than live signal amplitude.
- The mic volume bar controls the default source volume, but its middle click mute action applies to active recording streams and non-monitor input devices together.
- Only basic playback transport is supported. There is no seek, position display, playlist UI, or per-player popup.
- Device labels are currently just the raw sink/source names from `pactl`; there is no friendly-name normalization yet.
- The widget is primarily focused on the default sink for top-level volume/mute operations.
- Popup layout and text density may need theme tuning for very narrow widths or unusually long device/stream names.
- The widget both polls and subscribes. That keeps it responsive, but it can still momentarily lag behind fast external changes depending on backend timing.
- Hover-close behavior depends on pointer geometry and popup anchoring. On unusual layouts or rapid mouse movement, the close timing may feel slightly aggressive or slightly delayed.
- Keyboard-invoked popups should usually be shown with `hover_close = false`; otherwise they may close immediately if the pointer is already outside the popup.
- If `pavucontrol` is not installed, the advanced action in the devices popup will fail silently from the widget’s perspective.

## File Overview

- [init.lua](/home/anthrax/.config/awesome/lxaudio/init.lua): instance lifecycle, timers, refresh logic, popup management
- [widget.lua](/home/anthrax/.config/awesome/lxaudio/widget.lua): compact bar widget and mouse bindings
- [audio.lua](/home/anthrax/.config/awesome/lxaudio/audio.lua): sink/source/stream inspection and control via `pactl` and `wpctl`
- [media.lua](/home/anthrax/.config/awesome/lxaudio/media.lua): MPRIS player lookup, metadata, artwork, and transport control via `playerctl`
- [popup_media.lua](/home/anthrax/.config/awesome/lxaudio/popup_media.lua): playback streams popup
- [popup_devices.lua](/home/anthrax/.config/awesome/lxaudio/popup_devices.lua): device selection popup
- [popup_common.lua](/home/anthrax/.config/awesome/lxaudio/popup_common.lua): shared popup UI helpers
- [util.lua](/home/anthrax/.config/awesome/lxaudio/util.lua): shared shell and text helpers
