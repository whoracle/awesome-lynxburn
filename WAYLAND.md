# Wayland / SomeWM

This repo can be run under Wayland through
[`SomeWM`](https://github.com/trip-zip/somewm), a wlroots compositor with an
AwesomeWM-compatible Lua surface.

This is not the daily-driven path yet. AwesomeWM 4.3 on X11 is still the
baseline. SomeWM support exists so the config can be tested without permanently
forking it.

The compatibility target here is SomeWM `1.4`. SomeWM `2.x` is its own thing
and should not be assumed to behave like the `1.4` compatibility branch.

## Goal

The intended shape is:

- one repo
- one shared `rc.lua`
- one shared user-facing config surface where possible
- platform-specific defaults and backends only where they are actually needed

In practice that means AwesomeWM/X11 and SomeWM/Wayland share most modules, but
some commands and backends differ.

## Current Status

Implemented:

- platform detection in `config.platform`
- shared defaults plus platform-specific defaults
- `config.awesome.example.lua` and `config.somewm.example.lua`
- config-dir-aware theme loading, so a `~/.config/somewm` checkout does not
  assume `~/.config/awesome`
- Wayland screenshot defaults based on `grim` / `slurp`
- Wayland primary-selection paste for `lxrunner` through `wl-paste`
- Wayland brightness commands through `brightnessctl`
- Wayland display-off command through `wlopm`
- shared `settings.keyboard` handling:
  - `setxkbmap` on AwesomeWM/X11
  - `awful.input.xkb_*` on SomeWM/Wayland
- a SomeWM `lxdisplay` backend using `wlr-randr`
- translated `foot` config at `wayland/foot.ini.example`

Current check command:

```bash
somewm --check /home/anthrax/tmp/awesome/rc.lua
```

Current result:

- no compatibility issues reported by `somewm --check`

That only means the static compatibility check passes. It does not mean every
runtime behavior is polished.

## Running A Test Session

The most useful test command so far has been:

```bash
somewm -c .config/somewm/rc.lua -d 2>&1 | tee ~/somewm.log
```

If session services behave oddly, wrap it in `dbus-run-session`:

```bash
dbus-run-session somewm -c ~/.config/somewm/rc.lua -d 2>&1 | tee ~/somewm.log
```

This has not been tested thoroughly through a display manager.

## Known Issues

- `lxdisplay` on Wayland is not dependable enough to be the main monitor setup
  path yet. `wlr-randr` commands can pass and still not produce the expected
  physical layout on the tested machine.
- Startup output layout is especially fragile. A small user shell script after
  login is currently more reliable than relying on `lxdisplay`.
- The tested SomeWM session can feel sluggish. This may be related to the local
  NVIDIA/wlroots/screen setup rather than the config alone.
- SomeWM is not daily-driven here, so regressions are more likely than on the
  AwesomeWM/X11 path.

## Backend Replacements

Current or planned Wayland-side replacements:

- `xrandr` -> `wlr-randr` for `lxdisplay`
- `scrot` -> `grim` / `slurp`
- `xbacklight` -> `brightnessctl`
- `xclip` / `xsel` -> `wl-copy` / `wl-paste`
- `xset dpms` style display-off commands -> `wlopm`

`lxdisplay` is the complicated one because it owns more than one X11-specific
behavior:

- brightness integration
- display-off behavior
- profile application
- gamma/redshift scheduling
- startup display-profile application

Keep that backend split explicit. Do not hide Wayland behavior behind a pile of
one-off command substitutions.

## Popup Input

Popups are not normal clients.

`awful.popup` is a `wibox`, and a `wibox` is backed by a `drawin`, not by a
managed client. The documented widget input signals cover mouse events, not a
normal keyboard-focus model. SomeWM has keyboard-focus handling for Wayland
layer surfaces, but that does not make Awesome Lua `wibox` popups behave like
focused clients.

Current direction:

- keep popup input ownership centralized in `lxcommon`
- keep modules responsible for popup content and module-specific extra actions
- keep `lxrunner` separate from regular navigation popups because it is a
  text-input popup
- preserve the AwesomeWM/X11 behavior contract while making SomeWM fixes

The shared behavior contract is:

- root mouse button `10` opens a terminal globally
- popups can be opened from top-level clicks, direct shortcuts, and popup
  cycling
- `Escape` closes the active popup
- `Up` / `Down` navigate cards
- `Return` triggers the primary card action
- `Left` / `Right` trigger popup-defined lateral actions
- module-specific extra keys remain possible, currently mainly XF86 media keys
  in `lxmedia`
- clicking outside a popup dismisses it

## Open Questions

- whether `wlr-randr` can be made reliable enough for startup profile
  application, or whether Wayland monitor setup should stay explicitly
  user-scriptable
- whether `grim` / `slurp` should remain the screenshot path, or whether an
  Awesome/SomeWM-native screenshot helper becomes useful later
- whether SomeWM `1.4` quirks and future `2.x` behavior should be version-gated
  if both targets ever matter
- whether SomeWM compatibility belongs in regular daily testing, or remains a
  best-effort branch until the compositor side settles
