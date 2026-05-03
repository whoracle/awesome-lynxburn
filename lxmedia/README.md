# lxmedia

`lxmedia` is an AwesomeWM audio widget for PipeWire/PulseAudio setups.

It shows:

- current default output volume
- mute state
- default input volume when a recording stream is active
- microphone activity indicator
- active playback streams
- available output and input devices
- basic MPRIS media controls for matched players

The main widget is compact, and it opens two popups:

- primary click: playback streams and media controls
- secondary click: output/input device selection

## What It Does

At a high level, the project combines three pieces:

- a small bar widget that displays speaker state plus microphone activity and input volume while recording is active
- a playback popup that lists active sink inputs, lets you reroute them, and exposes play/pause/next/previous controls when a matching MPRIS player is found
- a device popup that lets you switch the default sink and source, plus open `pavucontrol`

The widget refreshes on a timer and also subscribes to `pactl subscribe` so it reacts to most audio changes quickly.

## Dependencies

`lxmedia` assumes AwesomeWM and a Linux desktop with PulseAudio-compatible
tooling available.

Required runtime dependencies:

- AwesomeWM with Lua support
- `pactl`
- `playerctl`
- `pavucontrol`
- Awesome libraries used by the widget: `awful`, `gears`, `wibox`, `beautiful`

Notes:

- `pactl` is used for compact-widget audio control plus popup stream/device enumeration.
- `playerctl` is required for media-player discovery, metadata, artwork lookup, transport controls, and media-key integration through MPRIS players.
- `pavucontrol` is required for the "Open pavucontrol" action in the devices popup.
- the top-level startup preflight checks all three of these tools when `lxmedia`
  is enabled in `lxmodules.lxbar.order`

## Repo Usage

The module lives in this repo as `lxmedia` and is loaded through the normal
config service/bootstrap flow. If you copy it elsewhere, keep the directory name
as `lxmedia` so Awesome can `require` it.

Example layout:

```text
~/.config/awesome/
├── rc.lua
└── lxmedia/
    ├── init.lua
    ├── audio.lua
    ├── media.lua
    ├── runtime.lua
    ├── devices_popup_controller.lua
    ├── media_popup_controller.lua
    ├── popup_devices.lua
    ├── popup_media.lua
    └── widget.lua
```

Then require it from your Awesome config.

## Usage

Basic example in `rc.lua`:

```lua
local awful = require("awful")
local wibox = require("wibox")
local lxmedia = require("lxmedia")

local audio = lxmedia.new()

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

You create an instance with `lxmedia.new(opts)` and place `instance.widget` anywhere a normal Awesome widget can be used.

### Mouse Controls

On the main widget:

- primary click: toggle playback popup
- secondary click: toggle devices popup
- middle click on the widget shell: mute/unmute default sink
- middle click on the output section: mute/unmute default sink
- scroll on the output section: change default sink volume
- middle click on the mic section: mute/unmute all non-monitor inputs
- scroll on the mic section: change default source volume

Inside the playback popup:

- left click a stream row/card: mute/unmute that sink input
- right click a player-backed stream row/card: play/pause that player
- middle click a stream row/card: mute/unmute that sink input
- scroll over a stream row/card: change that sink input volume
- click transport buttons: previous, play/pause, next
- click bars/meters directly: set the corresponding level
- if a stream is routed to a non-default sink, click its output target row to
  move it to another sink

Inside the devices popup:

- left click an output: set it as default sink
- left click an input: set it as default source
- left click a stream row: expand/collapse route targets
- right click a stream row: mute/unmute that sink input
- left click a route target: move the stream to another sink
- left click "Open pavucontrol": launch `pavucontrol`

## Configuration

`lxmedia.new(opts)` supports these options:

| Option | Default | Meaning |
| --- | --- | --- |
| `show_mic_activity` | `true` | Show the microphone icon and microphone volume bar when source outputs are active. |
| `refresh_interval` | `5` | Polling interval in seconds. |
| `width` | `50` | Width of the volume bar in the compact widget. |
| `step` | `0.05` | Volume step for scroll actions, expressed as `0.05 == 5%`. |
| `hover_close_timeout` | `beautiful.lxmedia_hover_close_timeout` or `1.5` | Seconds the pointer must stay outside the popup and anchor before auto-close when `hover_close = true` is passed. |
| `hover_close_poll_interval` | `beautiful.lxmedia_hover_close_poll_interval` or `0.25` | Poll interval used by the optional hover-close logic. |

Example:

```lua
local lxmedia = require("lxmedia")

local audio = lxmedia.new({
    width = 72,
    step = 0.02,
    refresh_interval = 2,
    show_mic_activity = false,
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
  Toggle the playback popup manually. Supports widget anchoring or explicit
  placement via `opts.placement`.
- `instance:toggle_devices_popup(anchor_geo_or_opts, opts)`
  Toggle the device popup manually. Supports widget anchoring or explicit
  placement via `opts.placement`.
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
local lxmedia = require("lxmedia")

local audio = lxmedia.new({
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
            placement = "center",
        })
    end),
    awful.key({ "Mod4", "Shift" }, "p", function()
        audio:toggle_devices_popup({
            hover_close = false,
            placement = "side",
        })
    end),
    awful.key({}, "Escape", function()
        audio:close_popups()
    end)
))
```

Notes:

- popups stay open until `Esc`, toggle, or outside click by default.
- `toggle_*_popup({ hover_close = true })` opts into pointer-leave auto-close behavior.
- `toggle_*_popup(mouse.current_widget_geometry)` remains the mouse-oriented form and anchors the popup to the widget.
- popup placement follows the shared `"center"` / `"side"` contract; actual
  left/right side selection comes from `lxmodules.lxbar.popup_side`
- For keyboard-driven volume control, `volume_up()`, `volume_down()`, and `toggle_mute()` use the same backend logic as the widget mouse bindings.

Popup keyboard behavior:

- playback popup:
  - `Up` / `Down`: move selection
  - `Enter`: mute/unmute the selected sink input
  - `Left` / `Right`: decrease/increase selected sink input volume
  - `Home`: set selected sink input volume to `100%`
  - `End`: mute/unmute the selected sink input
  - `Escape`: close popup
- devices popup:
  - `Up` / `Down`: move selection
  - `Enter`: trigger the selected row's primary action
  - `Escape`: close popup

## Theming

The widget reads colors, dimensions, and icons from `beautiful`.

Supported theme keys:

| Theme Variable | Purpose |
| --- | --- |
| `beautiful.lxmedia_icon_muted` | Muted speaker icon. |
| `beautiful.lxmedia_icon_volume` | Unmuted speaker icon. |
| `beautiful.lxmedia_icon_mic_active` | Microphone activity icon. |
| `beautiful.lxmedia_widget_muted_fg` | Foreground color of the compact icon while muted. |
| `beautiful.lxmedia_widget_fg` | Foreground color of the compact icon while unmuted. |
| `beautiful.lxmedia_widget_mic_fg` | Foreground color of the mic activity icon. |
| `beautiful.lxmedia_widget_mic_muted_fg` | Foreground color of the mic icon while recording inputs are muted. |
| `beautiful.lxmedia_bar_bg` | Background color of the volume bar. |
| `beautiful.lxmedia_bar_fg` | Fill color of the volume bar. |
| `beautiful.lxmedia_mic_bar_bg` | Background color of the microphone volume bar. |
| `beautiful.lxmedia_mic_bar_fg` | Fill color of the microphone volume bar. |
| `beautiful.lxmedia_bg_hover` | Hover background used in popup rows. |
| `beautiful.lxmedia_button_bg` | Media transport button background. |
| `beautiful.lxmedia_button_hover` | Media transport button hover background. |
| `beautiful.lxmedia_popup_width_media` | Width of the playback popup. |
| `beautiful.lxmedia_popup_width_devices` | Width of the device popup. |
| `beautiful.lxmedia_artwork_width` | Target artwork width in the playback popup. |
| `beautiful.lxmedia_artwork_max_height` | Maximum rendered artwork height. |
| `beautiful.lxmedia_hover_close_timeout` | Hover-close timeout override. |
| `beautiful.lxmedia_hover_close_poll_interval` | Hover-close poll interval override. |

Example theme snippet:

```lua
beautiful.lxmedia_icon_muted = "mute "
beautiful.lxmedia_icon_volume = "vol "
beautiful.lxmedia_icon_mic_active = "rec"

beautiful.lxmedia_widget_fg = "#e8d7b6"
beautiful.lxmedia_widget_muted_fg = "#9b8f86"
beautiful.lxmedia_widget_mic_fg = "#ff7a7a"
beautiful.lxmedia_widget_mic_muted_fg = "#9b8f86"

beautiful.lxmedia_bar_bg = "#221917"
beautiful.lxmedia_bar_fg = "#e0b56a"
beautiful.lxmedia_mic_bar_bg = "#221917"
beautiful.lxmedia_mic_bar_fg = "#d98f8f"

beautiful.lxmedia_bg_hover = "#3a2f2b"
beautiful.lxmedia_button_bg = "#2c2320"
beautiful.lxmedia_button_hover = "#5b3d28"

beautiful.lxmedia_popup_width_media = 360
beautiful.lxmedia_popup_width_devices = 360

beautiful.lxmedia_artwork_width = 420
beautiful.lxmedia_artwork_max_height = 680
```

Fallbacks:

- if a custom `lxmedia_*` theme variable is missing, the code falls back to common Awesome theme colors such as `fg_normal`, `bg_minimize`, `bg_focus`, and `fg_urgent`
- if an icon variable is missing, built-in text icons are used

## Screenshots

- `[placeholder] compact widget`
- `[placeholder] media popup`
- `[placeholder] devices popup`

## Further Reading

- [Top-level roadmap](../ROADMAP.md)
- [lxmedia spec](./SPEC.md)

## Known Limitations And Edge Cases

- AwesomeWM-only: this is not a general Lua library and expects the Awesome widget/runtime environment.
- Linux audio stack assumptions: the implementation is built around `pactl` for audio control and `playerctl` for MPRIS integration.
- Stream-to-player matching is heuristic-based: browser tabs, unusual player names, sandboxed apps, and custom MPRIS names may not match the expected media player.
- Artwork support is limited to `file://` art URLs exposed by `playerctl`. Remote URLs are ignored.
- Mic activity is inferred from active source outputs, not actual input level, so the mic icon and mic volume bar are shown based on recording activity rather than live signal amplitude.
- The mic volume bar controls the default source volume, but its middle click mute action applies to active recording streams and non-monitor input devices together.
- Only basic playback transport is supported. There is no seek, position display, playlist UI, or per-player popup.
- Device labels are currently just the raw sink/source names from `pactl`; there is no friendly-name normalization yet.
- The widget is primarily focused on the default sink for top-level volume/mute operations.
- Popup layout and text density may need theme tuning for very narrow widths or unusually long device/stream names.
- The widget both polls and subscribes. That keeps it responsive, but it can still momentarily lag behind fast external changes depending on backend timing.
- Optional hover-close behavior depends on pointer geometry and popup anchoring. On unusual layouts or rapid mouse movement, the close timing may feel slightly aggressive or slightly delayed.

## File Overview

- [init.lua](/home/anthrax/tmp/awesome/lxmedia/init.lua): constructor plus core volume/input actions
- [runtime.lua](/home/anthrax/tmp/awesome/lxmedia/runtime.lua): widget rebuild, timer/subscription setup, refresh, and OSD helpers
- [devices_popup_controller.lua](/home/anthrax/tmp/awesome/lxmedia/devices_popup_controller.lua): device-popup selection and activation helpers
- [media_popup_controller.lua](/home/anthrax/tmp/awesome/lxmedia/media_popup_controller.lua): media-popup selection, player transport, and keyboard actions
- [widget.lua](/home/anthrax/tmp/awesome/lxmedia/widget.lua): compact bar widget and mouse bindings
- [audio.lua](/home/anthrax/tmp/awesome/lxmedia/audio.lua): sink/source/stream inspection and control via `pactl`
- [media.lua](/home/anthrax/tmp/awesome/lxmedia/media.lua): MPRIS player lookup, metadata, artwork, and transport control via `playerctl`
- [popup_media.lua](/home/anthrax/tmp/awesome/lxmedia/popup_media.lua): playback streams popup
- [popup_devices.lua](/home/anthrax/tmp/awesome/lxmedia/popup_devices.lua): device selection popup
