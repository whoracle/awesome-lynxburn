# Wayland / SomeWM Notes

This file tracks the current migration plan for running this config under
Wayland via `SomeWM`, a wlroots-based compositor that aims to be AwesomeWM Lua
compatible.

The goal is to keep the config hot-swappable between:

- AwesomeWM on X11
- SomeWM on Wayland

without permanently forking the whole config.

Preferred end state, if at all possible:

- one repo
- one shared config surface and one shared config entry point where possible
- platform-specific defaults and backends only where they are genuinely needed

## Current Context

- `SomeWM` is based on AwesomeWM `4.4`
- it provides a compatibility checker via:

```bash
somewm --check /home/anthrax/tmp/awesome/rc.lua
```

- X11-specific code may be stubbed, ignored, or break at runtime
- some Awesome features may also differ because of the older base version
- the “AwesomeWM-compatible” assumption for this migration is tied to the
  `1.4` line of SomeWM specifically
- SomeWM `2.0` should be treated as its own target with potentially different
  compatibility assumptions, not as an automatic continuation of the `1.4`
  branch behavior

## Initial Compatibility Findings

The initial `somewm --check` report flagged these areas:

- `scrot` in `config/defaults.lua`
  Use `grim`/`slurp` or a compositor-native screenshot path instead
- `xset` in `config/defaults.lua`, `config/preflight.lua`, and `lxdisplay`
  Wayland compositors or tools like `wlr-randr` should own display power/state
- `xclip` / `xsel` in `lxrunner/history.lua`
  Replace with `wl-paste` / `wl-copy`
- missing `lpeg`
  This is an environment/package issue, not an X11 issue

## Agreed Plan Of Attack

### 1. Terminal First

Before deeper Wayland work, get a dependable native terminal working for
testing:

- translate the current `urxvt` setup from `~/.Xresources` to `foot.ini`
- switch `commands.terminal` to `foot`
- optionally start `foot -d` in `autostart_once` for the SomeWM path

The point is to have a stable Wayland-native terminal before debugging the rest
of the config inside a Wayland session.

### 2. Add Shared Platform Detection

Add one shared helper such as:

- `config.platform`
- or `lxcommon.platform`

with simple predicates:

- `is_x11()`
- `is_wayland()`
- optionally `is_somewm()`

This should be the single place where session/backend detection happens.

### 3. Split Shared And Platform Defaults

Current preferred direction:

- keep one shared `config.lua`
- support two example configs:
  - `config.awesome.example.lua`
  - `config.somewm.example.lua`
- load one shared defaults file plus one platform defaults file
- let `config.lua.platform` override runtime detection when needed

This keeps the shape simple and avoids an overlay stack.

### 4. Gate Known X11-Only Paths

After platform detection exists, gate the clearly X11-only paths:

- screenshot defaults and screenshot preflight checks
- `xset`-based display power commands
- `xclip` / `xsel` primary-selection paste
- `xbacklight` defaults if they do not work in the Wayland session

The first goal is graceful behavior and correct dependency checks, not perfect
feature parity yet.

### 5. Replace X11-Specific Backends

Planned replacements:

- `xrandr`
  likely `wlr-randr`
- `scrot`
  likely `grim` / `slurp`
  `awesome.screenshot()` may be explored later, but should not block first pass
- `xbacklight`
  likely `brightnessctl` or another compositor/session-safe backend
- `xclip` / `xsel`
  `wl-copy` / `wl-paste`

### 6. Tackle `lxdisplay` Last

`lxdisplay` is the hardest Wayland migration target because it currently owns:

- brightness backend integration
- display off behavior
- `xrandr` profile application
- gamma/redshift scheduling
- startup display-profile application

This likely needs a backend abstraction instead of ad-hoc command swapping.

## Expected First Implementation Slice

The first practical SomeWM/Wayland pass should be:

1. `foot` config from `~/.Xresources`
2. shared platform detection
3. shared defaults plus platform defaults loading
4. Wayland-aware screenshot, clipboard, and brightness/default/preflight fixes
5. only then start on `lxdisplay` backend work

## Current Status

Implemented:

- shared platform detection in `config.platform`
- shared defaults plus platform defaults split
- config-dir-aware theme loading so a `~/.config/somewm` checkout does not
  assume `~/.config/awesome`
- tracked `config.somewm.example.lua` and `config.awesome.example.lua`
- Wayland screenshot defaults based on `grim` / `slurp`
- Wayland primary-selection paste for `lxrunner` through `wl-paste`
- SomeWM `lxdisplay` backend for display profiles through `wlr-randr`
- Wayland-safe default brightness commands through `brightnessctl`
- Wayland-safe default display-off command through `wlopm`
- shared `settings.keyboard` handling:
  - `setxkbmap` on Awesome/X11
  - `awful.input.xkb_*` on SomeWM/Wayland
- translated `foot` config at `wayland/foot.ini.example`

Current `somewm --check /home/anthrax/tmp/awesome/rc.lua` status:

- no compatibility issues found

## Open Questions

- how much of `lxdisplay` can stay config-compatible while swapping out the
  underlying backend
- whether `wlr-randr` is dependable enough for startup display-profile
  application on real hardware or should remain a best-effort helper next to a
  user shell script
- whether `grim` / `slurp` is preferable to any compositor-native screenshot
  API long-term
- whether SomeWM-specific compatibility quirks from the Awesome `4.4` base
  should be handled via runtime detection or explicit `config.lua.platform`
- whether it is worth explicitly version-gating SomeWM quirks if `1.4` and
  `2.x` diverge too much for a single compatibility assumption

## Popup Input Redesign

The current popup/keygrabber model has become too brittle under SomeWM and is
at risk of destabilizing the X11 path as well. Further patching is not the
right next step.

Desired shared behavior:

- root mouse button `10` must open a terminal globally, regardless of popup
  state
- `lx*` popups must be openable via:
  - top-level mouse click
  - direct keyboard shortcut
  - popup cycling
- once open, popup keys must work reliably:
  - `Escape` closes
  - `Up` / `Down` navigate
  - `Return` triggers primary action
  - `Left` / `Right` trigger popup-defined lateral actions
- popup-specific extra keys must remain possible, currently mainly XF86 media
  keys in `lxmedia`
- clicking outside a popup must dismiss it
- hover-close for mouse-opened popups is dropped
- `lxrunner` should likely be treated separately as a text-input popup rather
  than a normal navigation popup

Preferred next direction:

- investigate whether focused `awful.popup` / `wibox` objects can receive
  keyboard events directly instead of relying on global keygrabbers
- if focus-based popup input works reliably, prefer it over explicit key
  grabbing
- keep one shared behavior contract for Awesome/X11 and SomeWM, even if backend
  implementation differs

Next-session checklist:

1. verify from Awesome/SomeWM docs or a minimal popup prototype whether a popup
   can be given dependable keyboard focus
2. if needed, spawn a minimal test popup and inspect whether it shows up as a
   focused/input-owning surface in Awesome/SomeWM state
3. confirm whether a focused popup receives `Escape`, `Up`, `Down`, and
   `Return` without a global keygrabber
4. confirm root mouse button `10` still works while such a popup is focused
5. investigate `lxrunner` separately, since it currently flickers and likely
   belongs to a dedicated text-input session model

Current documentation/source check:

- `awful.popup` is a `wibox`
- `wibox` is backed by a `drawin`, not by a managed `client`
- documented `wibox` / widget input signals cover mouse events:
  `button::press`, `button::release`, `mouse::enter`, `mouse::leave`, and
  `mouse::move`
- no documented `wibox` keyboard focus or key event signal was found in the
  installed Awesome or SomeWM Lua sources
- `wibox.input_passthrough` explicitly talks about forwarding mouse and
  keyboard events to the object below the wibox, which supports the conclusion
  that a wibox itself is not a normal keyboard focus target
- SomeWM has keyboard-focus handling for Wayland `layer_surface` objects, but
  that is a separate surface type and does not make Awesome Lua `wibox` popups
  focusable clients

Working conclusion:

- a pure client-focus model is probably not available for `awful.popup` /
  `wibox` popups
- the redesign should still centralize popup input ownership, but it will likely
  need one controlled input capture layer rather than per-module keygrabbers
