# lxdisplay Spec

## Goal

`lxdisplay` is a small AwesomeWM-native display control module/widget in the same spirit as `lxaudio`:

- it owns display-related UI behavior
- it can expose a top-level widget for the wibar
- it owns the brightness OSD
- it provides mouse-driven brightness and redshift controls

The initial scope is intentionally narrow. It does not need to become a full display manager.

## Initial Scope

The first implementation should focus on:

- a top-level widget with a bulb glyph
- optional brightness bar next to the glyph
- brightness control by mouse scroll on the icon and, if enabled, the bar
- brightness OSD ownership
- configurable minimum brightness clamp
- basic redshift integration:
  - configured location
  - configured day temperature
  - configured night temperature
  - middle click to suspend/resume redshift behavior

## Naming / Role

The name `lxdisplay` is acceptable even though the first version is mostly:

- brightness
- color temperature / redshift

The module may later grow into broader display-related functionality.

## Non-Goals For V1

The following are explicitly out of scope for the first implementation:

- multi-monitor configuration logic
- xrandr layout management
- color profile handling
- display hotplug automation
- keyboard bindings for redshift control
- a rich redshift status UI
- fully replacing every behavior of `redshift-gtk`

## Core Behavior

### Widget

`lxdisplay` should expose a widget suitable for placement in the existing theme/wibar code.

The widget should contain:

- a bulb icon/glyph
- optionally a horizontal bar representing brightness

The bar should be configurable:

- enabled or disabled
- width
- colors taken from theme values where practical

The icon should always remain usable even if the bar is hidden.

### Brightness Control

Brightness should be controlled by scroll events on:

- the bulb icon
- the optional bar

Expected behavior:

- scroll up increases brightness
- scroll down decreases brightness
- brightness changes should clamp to a configurable minimum

The module should not allow the display to dim all the way to 0 unless the user explicitly configures that.

Recommended default:

- minimum brightness around 5% or 10%

Brightness command execution should remain configurable in case `xbacklight` is replaced later.

Recommended command config shape:

```lua
brightness = {
    get = "xbacklight -get",
    set = "xbacklight -set %d",
    step = 5,
    min = 10,
    off = "xset dpms force off",
}
```

Implementation note:

- if `set` is available, clamp by reading the current brightness and issuing a computed set command
- this is preferable to plain `-inc` / `-dec` if a hard minimum is required

### Brightness OSD

`lxdisplay` should own the brightness OSD instead of `config/osd.lua`.

Behavior:

- brightness changes performed through `lxdisplay` can optionally request OSD display
- widget mouse-scroll brightness changes should not show the OSD by default
- keyboard-triggered brightness actions should be able to request the OSD explicitly, matching the current volume OSD pattern
- OSD styling should follow the existing notification/theme direction
- the OSD should be analogous to the current volume OSD:
  - compact
  - bottom-centered
  - transient
  - progress-bar based

It is acceptable for the first implementation to move or adapt the current brightness OSD logic from `config/osd.lua`.

## Redshift Integration

### Goal

`lxdisplay` should provide a thin control layer for redshift-related behavior, not necessarily a complete in-process implementation of redshift logic.

The practical requirement is:

- the user wants day/night color temperature behavior
- the user wants middle click to suspend or resume it

### Configuration

The module should support redshift configuration values for:

- latitude
- longitude
- day temperature
- night temperature

Recommended config shape:

```lua
redshift = {
    enabled = true,
    latitude = "...",
    longitude = "...",
    temperature_day = 6500,
    temperature_night = 4500,
}
```

### Control Model

Preferred model for V1:

- `lxdisplay` controls an external `redshift` process or `redshift-gtk` compatible behavior
- it does not need to reimplement scheduling logic internally

That means `lxdisplay` should, if practical:

- start redshift/redshift-gtk with configured values
- stop it when suspended
- restart it when resumed

If direct control of `redshift-gtk` is awkward, it is acceptable for V1 to instead control plain `redshift` itself and leave tray behavior out of scope.

### Suspend / Resume

Middle click on the widget should toggle redshift suspension.

Expected behavior:

- if redshift is active, middle click suspends it
- if redshift is suspended, middle click resumes it

Open implementation question:

- on suspend, should the display immediately reset to neutral temperature (`6500K`)?

Recommended behavior:

- yes; for now suspend should behave like `redshift -x`, meaning the current adjustment is removed from the screen immediately

### Status Indication

For V1, the widget does not need a rich text label for redshift status.

Acceptable simple options:

- no visible state change at first
- subtle icon/bar color change later
- optional tooltip later

This can stay minimal in the first version.

## Mouse Interaction

Required mouse behavior:

- scroll up: brightness up
- scroll down: brightness down
- middle click: suspend/resume redshift

Optional for later:

- left click for a small menu or state popup
- right click for advanced settings

These are not required for V1.

## Configuration Source

As with the rest of this config refactor, `lxdisplay` should pull its visual configuration from the Awesome theme/config rather than requiring a large parameter list on creation.

Configuration should likely come from:

- theme values for colors, sizes, fonts, bar styling
- a config/program definition section for external commands

This should follow the same general philosophy as the current refactor:

- avoid globals
- avoid overengineering
- keep the data in obvious places

## Integration Expectations

The eventual integration should likely look like:

- `config.services` exposes a singleton `lxdisplay` instance
- theme/widget code requests the widget from that service
- keybindings or mouse actions call methods on the service instance

This mirrors the current `lxaudio` pattern and keeps widget behavior encapsulated.

## Suggested Public Surface

The exact API can stay small. Something in this shape is sufficient:

- `new()`
- `widget()`
- `brightness_up(opts)`
- `brightness_down(opts)`
- `brightness_off()`
- `brightness_refresh()`
- `redshift_toggle()`
- `redshift_suspend()`
- `redshift_resume()`

Optional behavior flags:

- `show_osd = true/false`

## Staged Implementation Plan

Implementation should be done in small testable steps:

1. create the module skeleton and top-level widget
2. move brightness OSD ownership into `lxdisplay`
3. wire mouse scroll brightness control with minimum clamp
4. add basic redshift config and suspend/resume control
5. optionally replace existing external redshift autostart usage if the new control path is clean

## Open Questions

These do not block the spec, but they should be resolved during implementation:

1. Should suspend restore neutral color temperature immediately, or only stop further adjustment?
   Recommended: restore neutral immediately if feasible.

2. Should `lxdisplay` manage plain `redshift` directly instead of `redshift-gtk`?
   Recommended: yes, if that yields simpler deterministic control.

3. Should the widget expose any visible redshift state in V1?
   Recommended: no strong requirement; minimal behavior is fine.
