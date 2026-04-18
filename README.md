# AwesomeWM Configuration

This repository contains a refactored AwesomeWM configuration centered around a
small `config/` layer and a single theme directory. Third-party modules live in
their own folders and are treated as vendored code.

## Maintenance Boundary

Files you are expected to edit directly:

- `rc.lua`
- `config/*.lua`
- `lxbar/`
- `lxcommon/`
- `themes/lynxburn2/theme.lua`
- `themes/lynxburn2/widgets.lua`

Vendored / external code you generally should not edit here:

- `lain/`
- `freedesktop/`
- `lxaudio/`
- `lxbluetooth/`
- `lxnetwork/`
- `lxnotify/`
- `lxrunner/`
- `lxdisplay/`
- `lxpowerprofiles/`

The `lx*` directories are local modules with their own ownership boundary and
are intended to become submodules later.

## Layout

### Top Level

- `rc.lua`
  Bootstraps Awesome, loads the theme, instantiates shared services, and wires
  together layouts, keys, rules, signals, and screens.

- `config/`
  Main maintainable configuration split by responsibility.

- `lxcommon/`
  Shared building blocks for the `lx*` family: widget registry, popup manager,
  popup placement helpers, and shared OSD primitives.

- `lxbar/`
  Unified top-level widget that renders registered `lx*` compact widgets and
  exposes shared popup actions such as popup cycling.

- `themes/lynxburn2/theme.lua`
  Theme values: colors, fonts, icon paths, widget settings, popup sizing, and
  per-module theme knobs.

- `themes/lynxburn2/widgets.lua`
  Wibar construction and theme-local widget composition.

### `config/`

- `init.lua`
  Aggregates the maintainable config modules behind `require("config.init")`.

- `defaults.lua`
  Central default user-facing config values. This is the base layer merged with
  top-level `config.lua`.

- `config_data.lua`
  Shared loader and merge layer for centralized config sections such as
  `settings`, `commands`, `screens`, `theme`, and `lxmodules`.

- `helpers.lua`
  Small shared helpers such as startup error handling and run-once autostart.

- `layouts.lua`
  Layout list and Quake terminal setup.

- `keys.lua`
  Global and client keybindings. Most user interaction changes belong here.

- `mouse.lua`
  Root, taglist, tasklist, and client mouse bindings.

- `rules.lua`
  Application placement and behavior rules.

- `signals.lua`
  Client lifecycle signals, titlebar setup, and border behavior.

- `screens.lua`
  Per-screen initialization, wallpaper handling, layout defaults, and DPI.

- `services.lua`
  Shared singleton instances for the `lx*` modules plus registration into
  `lxcommon.registry` and `lxcommon.popup_manager`.

- `osd.lua`
  Small config-owned OSD helpers outside the `lx*` family. The shared progress
  and text OSD primitives used by `lxaudio` and `lxdisplay` now live in
  `lxcommon/osd.lua`.

## Startup Flow

The high-level startup order is:

1. `rc.lua` loads `config`
2. startup error handling is installed
3. the selected theme is loaded with `beautiful.init(...)`
4. long-lived service instances are created
5. `lx*` widgets and popup handles are registered through `config/services.lua`
6. layouts, keybindings, mouse bindings, rules, signals, and screens are wired
7. `autostart_once` commands are launched via `run_once`
8. plain `autostart` commands are spawned every startup

This split is intentional:

- theme values live in `theme.lua`
- wibar structure lives in `widgets.lua`
- service/module ownership lives in `config/services.lua`
- user-editable behavior lives in top-level `config.lua`, merged over
  `config/defaults.lua`
- shared `lx*` composition and popup coordination live in `lxcommon/` and
  `lxbar/`
- bar composition now lives in `lxmodules.lxbar`
- module behavior now lives in `lxmodules.<module>`

## Central Config

The intended user config entrypoint is top-level `config.lua` next to `rc.lua`.
It is merged over `config/defaults.lua`.

Centralized sections currently include:

- `settings`
- `commands`
- `theme`
- `screens`
- `keys`
- `rules`
- `lxmodules`

Within `lxmodules`:

- `lxmodules.lxbar` owns bar composition such as order and cycle participation
- `lxmodules.<module>` owns per-module behavior and backend wiring
- `lxmodules.lxrunner.aliases` owns runner aliases

Examples:

- `commands.terminal`
- `theme.name`
- `screens.center.tags.primary.layout`
- `lxmodules.lxbar.order`
- `lxmodules.lxdisplay.redshift`
- `lxmodules.lxrunner.aliases`

Legacy `config/override/*.lua` files are migration-only scaffolding now and are
no longer read by the runtime.

## Theme Split

The theme directory is deliberately split into:

- `theme.lua`
  Pure theme/config data

- `widgets.lua`
  Actual widget composition for the wibar and screen setup

If you want to:

- change colors, fonts, icon paths, widget sizing, or module-specific theme
  values: edit `theme.lua`
- reorder the classic theme widgets or change their wrapping/composition: edit
  `widgets.lua`
- change `lx*` module order/composition behavior: edit `lxmodules.lxbar` in
  top-level `config.lua`
- change `lx*` module behavior/backend config: edit `lxmodules.<module>` in
  top-level `config.lua`

## External Dependencies

### Core Runtime

Required to run this config at all:

- `awesome`
- Lua libraries shipped with Awesome (`awful`, `gears`, `wibox`, `naughty`)
- the vendored module directories in this repo

### Common External Commands Used By This Config

Used directly by the current maintainable config:

- `urxvt`
- `thunar`
- `vivaldi-stable`
- `playerctl`
- `xbacklight`
- `xset`
- `redshift`
- `i3lock`
- `scrot`
- `secret-tool`
- `numlockx`

Also referenced in program definitions or optional autostart commands:

- `gimp`
- `sxiv`
- `conky`
- `nm-applet`
- `blueman-applet`
- `pasystray`
- `nextcloud`
- `gromit-mpx`

### Mail Password Lookup

The IMAP password is not stored directly in the theme code. It is configured
through `commands.lain.imap_secret`, which currently uses `secret-tool` from
GNOME Keyring.

Current default lookup configured in `config/defaults.lua`:

```sh
secret-tool lookup service awesomewm-imap account anthrax@lynxcore.org
```

To store or update it:

```sh
secret-tool store --label="AwesomeWM IMAP" service awesomewm-imap account anthrax@lynxcore.org
```

## Notable Module Ownership

### `lxaudio`

- owns the audio widget
- owns audio state and popup content
- keyboard volume calls request OSD explicitly
- uses shared OSD primitives from `lxcommon.osd`

### `lxdisplay`

- owns the display widget
- owns brightness and redshift state
- scroll brightness changes do not show OSD by default
- keyboard brightness changes do request OSD explicitly
- owns redshift control plumbing
- uses shared OSD primitives from `lxcommon.osd`

### `lxnotify`

- owns notification aggregation and popup behavior
- owns the compact bell-state contract and notification action/dismiss behavior

### `lxcommon`

- owns shared `lx*` infrastructure rather than any one module's backend state
- currently owns:
  - registry for compact widgets
  - popup handle registry / popup manager
  - popup placement helpers
  - shared OSD primitives

### `lxbar`

- owns shared top-level `lx*` composition in the wibar
- renders registered module widgets in one container
- exposes shared popup actions such as popup cycling in bar order
- current default widget order is:
  - network
  - audio
  - notify
  with additional bar modules opt-in/configured under `lxmodules.lxbar`

### `lxrunner`

- owns the program launcher, alias handling, history, and runner UI
- history is persisted in `~/.lxrunner_history`
- history stores the canonical launched match label rather than the typed prefix

## Common Edit Locations

If you want to change:

- keybindings: `config/keys.lua`
- app commands and tool paths: top-level `config.lua` under `commands`
- monitor mapping / tag names / modifier keys: top-level `config.lua` under `settings`
- client placement rules: `config/rules.lua`
- screen-specific DPI and default layouts: top-level `config.lua` under `screens`
- classic wibar order/layout: `themes/lynxburn2/widgets.lua`
- `lx*` bar composition: top-level `config.lua` under `lxmodules.lxbar`
- `lx*` shared popup/runtime behavior: `config/services.lua`, `lxbar/init.lua`,
  `lxcommon/*.lua`
- colors, glyphs, popup sizes, per-widget theme settings: `themes/lynxburn2/theme.lua`
- `lxrunner` aliases and runner behavior: top-level `config.lua` under
  `lxmodules.lxrunner`, plus `lxrunner/` for implementation

## Installation / Local Testing

Typical local testing flow during refactors:

1. edit this repo in `~/tmp/awesome`
2. replace the live config with it
3. reload Awesome

Example:

```sh
rm -rf ~/.config/awesome
cp -r ~/tmp/awesome ~/.config/awesome
awesome-client 'awesome.restart()'
```

If you prefer a safer copy step, replace the `rm -rf` with your own sync
workflow.

## Notes

- This repo was intentionally modularized only far enough to make maintenance
  reasonable. It is not trying to become a framework.
- `lxcommon` and `lxbar` are the current shared architecture for the `lx*`
  modules. They are intentionally small and should stay pragmatic.
- The `config` aggregator exists so `rc.lua` can use `local config =
  require("config.init")` and then address modules as `config.keys`,
  `config.lxmodules`, and so on.
- Top-level `config.lua` is the intended user config entrypoint, merged over
  `config/defaults.lua`.
- The current docs intentionally describe the repo-owned `lx*` behavior, not the
  vendored upstream `lain` subtree.
