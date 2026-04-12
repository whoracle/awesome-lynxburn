# AwesomeWM Configuration

This repository contains a refactored AwesomeWM configuration centered around a
small `config/` layer and a single theme directory. Third-party modules live in
their own folders and are treated as vendored code.

## Maintenance Boundary

Files you are expected to edit directly:

- `rc.lua`
- `config/*.lua`
- `themes/lynxburn2/theme.lua`
- `themes/lynxburn2/widgets.lua`

Vendored / external code you generally should not edit here:

- `lain/`
- `freedesktop/`
- `lxaudio/`
- `lxnotify/`
- `lxrunner/`
- `lxdisplay/`

The `lx*` directories are local modules with their own ownership boundary and
are intended to become submodules later.

## Layout

### Top Level

- `rc.lua`
  Bootstraps Awesome, loads the theme, instantiates shared services, and wires
  together layouts, keys, rules, signals, and screens.

- `config/`
  Main maintainable configuration split by responsibility.

- `themes/lynxburn2/theme.lua`
  Theme values: colors, fonts, icon paths, widget settings, popup sizing, and
  per-module theme knobs.

- `themes/lynxburn2/widgets.lua`
  Wibar construction and theme-local widget composition.

### `config/`

- `init.lua`
  Aggregates the config modules behind `require("config")`.

- `settings.lua`
  Static user preferences such as mod keys, monitor mapping, workspace names,
  and theme selection.

- `programs.lua`
  External command definitions and runtime command configuration. This is the
  first place to look when changing launchers, screenshot commands, brightness,
  or Redshift behavior.

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
  Shared singleton instances for `lxaudio`, `lxnotify`, `lxrunner`, and
  `lxdisplay`.

- `osd.lua`
  Generic text-only OSD helpers that are still owned by the main config. Volume
  and brightness OSD ownership now lives in `lxaudio` and `lxdisplay`
  respectively.

## Startup Flow

The high-level startup order is:

1. `rc.lua` loads `config`
2. startup error handling is installed
3. the selected theme is loaded with `beautiful.init(...)`
4. long-lived service instances are created
5. layouts, keybindings, mouse bindings, rules, signals, and screens are wired
6. `autostart_once` commands are launched via `run_once`
7. plain `autostart` commands are spawned every startup

This split is intentional:

- theme values live in `theme.lua`
- wibar structure lives in `widgets.lua`
- service/module ownership lives in `config/services.lua`
- user-editable behavior lives in `config/*.lua`

## Theme Split

The theme directory is deliberately split into:

- `theme.lua`
  Pure theme/config data

- `widgets.lua`
  Actual widget composition for the wibar and screen setup

If you want to:

- change colors, fonts, icon paths, widget sizing, or module-specific theme
  values: edit `theme.lua`
- reorder widgets on the bar or change their wrapping/composition: edit
  `widgets.lua`

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
- `picom`
- `unclutter`
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

The IMAP password is not stored in Lua code. It is fetched through
`secret-tool` from GNOME Keyring.

Current lookup used by the theme widget:

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
- owns volume and mute OSD
- keyboard volume calls request OSD explicitly

### `lxdisplay`

- owns the display widget
- owns brightness OSD
- scroll brightness changes do not show OSD by default
- keyboard brightness changes do request OSD explicitly
- owns Redshift control plumbing

### `lxnotify`

- owns notification aggregation and popup behavior

### `lxrunner`

- owns the program launcher, alias handling, history, and runner UI

## Common Edit Locations

If you want to change:

- keybindings: `config/keys.lua`
- app commands and tool paths: `config/programs.lua`
- monitor mapping / workspace names / modifier keys: `config/settings.lua`
- client placement rules: `config/rules.lua`
- screen-specific DPI and default layouts: `config/screens.lua`
- wibar order/layout: `themes/lynxburn2/widgets.lua`
- colors, glyphs, popup sizes, per-widget theme settings: `themes/lynxburn2/theme.lua`

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
- The `config` aggregator exists so `rc.lua` can use `local config =
  require("config")` and then address modules as `config.keys`,
  `config.programs`, and so on.
- Some legacy commands and optional tools remain in `programs.lua` even if they
  are not always enabled in autostart.
