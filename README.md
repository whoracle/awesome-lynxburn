# LynxBurn AwesomeWM Config

This repository contains an AwesomeWM configuration with a small top-level
config surface, a bundled `lynxburn` theme, and a set of local `lx*` modules
for the bar, popups, notifications, media, networking, power, display control,
and launcher behavior.

It is usable as a real daily-driver config, but it is still a personal config
first rather than a polished general-purpose distribution.

## What To Expect

- this repo is actively shaped around one real desktop setup
- the config surface is intended to be reusable, but ongoing refactors and
  feature work can still move things around
- focused bug reports and targeted improvements are welcome
- larger feature ideas should be discussed before implementation
- there is no stability guarantee or support SLA

## Dependencies

Core runtime:

- AwesomeWM
- the Lua libraries shipped with AwesomeWM, including `awful`, `beautiful`,
  `gears`, `naughty`, and `wibox`
- `lain`
- a font with broad glyph coverage for the bar and popup icons, ideally
  something like `Hack Nerd Font Mono`

Common external commands used by the current config:

- `playerctl`
- `xbacklight` or an equivalent brightness backend if you override it
- `xset`
- `xrandr`
- `scrot`
- `secret-tool` if you use the current IMAP password lookup flow
  To store a secret, use something like this: `secret-tool store --label="AwesomeWM IMAP" service awesomewm-imap account me@example.org`.
  Then configure the IMAP widget like this:
  ```lua
    commands = {
`     lain = {
        imap_mail = "me@example.org",
        imap_secret = "secret-tool lookup service awesomewm-imap account me@example.org",
        imap_server = "mail.example.org",
      },
    },
  ```

Common desktop programs referenced by the defaults:

- a terminal emulator
- a file browser
- optional applets or tray tools such as network, Bluetooth, audio, or sync
  applets if you add them to your own setup

This README intentionally does not include distro-specific installation steps
yet.

## Startup Preflight

After Awesome has loaded successfully, the config runs a startup preflight pass
for dependencies that would otherwise tend to fail silently or degrade module
behavior in confusing ways.

Current behavior:

- missing tools are grouped by `core` or `lx*` module
- the report is written to stderr, which typically means `~/.xsession-errors`
- the same report is shown as a `naughty` notification
- bar-module checks are only performed for modules currently enabled through
  `lxmodules.lxbar.order`
- shipped screenshot-command dependencies such as `scrot` / `xdg-open` are only
  checked when those default commands are still in use rather than overridden
  locally

This is intentionally a concrete binary/command inventory, not a broader
service-health or environment-diagnostics framework.

## Quickstart

The user-facing config entrypoint is top-level `config.lua`.

1. Copy `config.example.lua` to `config.lua`.
2. Adjust `commands` so the config points at programs that actually exist on
   your system.
3. Adjust `screens` so monitor indices, tag names, and per-tag layouts match
   your setup.
4. Adjust `lxmodules` to choose bar order, popup cycling participation, and
   module-specific behavior.
5. Adjust `theme` only for appearance-related overrides.

Minimal example:

```lua
theme = {
    wallpaper = os.getenv("HOME") .. "/.wallpaper",
}

commands = {
    terminal = "alacritty",
    filebrowser = "thunar",
}

screens = {
    tag_order = { "primary", "secondary", "tertiary" },
    tag_defaults = {
        primary = {
            layout = "fair.horizontal",
            layouts = { "fair.horizontal", "centerwork.horizontal", "floating" },
        },
        secondary = {
            layout = "centerwork",
            layouts = { "centerwork", "fair", "floating" },
        },
        tertiary = {
            layout = "floating",
            layouts = { "floating" },
        },
    },
    center = {
        dpi = 96,
    },
}

lxmodules = {
    lxbar = {
        order = { "lxbluetooth", "lxnetwork", "lxmedia", "lxnotify", "lxdisplay", "lxpower" },
        popup_side = "right",
        modules = {
            bluetooth = { cycle = false },
        },
    },
    lxrunner = {
        width = 640,
        row_count = 10,
    },
}
```

## Configuration Model

The current config layers are:

- `config/defaults.lua`
  Repository defaults
- `config.example.lua`
  Tracked example override file
- `config.lua`
  Your local machine-specific overrides

The main top-level sections are:

- `commands`
- `keys`
- `lxmodules`
- `rules`
- `screens`
- `settings`
- `theme`

General ownership rules:

- put program/backend choices under `commands`
- put user keybinding overrides under `keys`
- put bar order and popup-cycle participation under `lxmodules.lxbar`
- put module behavior under `lxmodules.<module>`
- put monitor, tag, and layout config under `screens`
- put appearance overrides under `theme`

Dependency and startup-check details for individual modules live in the module
READMEs.

## Modules And Theme

Module-specific usage, feature lists, config knobs, and theme variables live in
their own READMEs.

Core shared pieces:

- [`lxcommon`](./lxcommon/README.md)
- [`lxbar`](./lxbar/README.md)

Modules:

- [`lxmedia`](./lxmedia/README.md)
- [`lxnotify`](./lxnotify/README.md)
- [`lxnetwork`](./lxnetwork/README.md)
- [`lxbluetooth`](./lxbluetooth/README.md)
- [`lxpower`](./lxpower/README.md)
- [`lxdisplay`](./lxdisplay/README.md)
- [`lxrunner`](./lxrunner/README.md)

Theme:

- [`lynxburn`](./themes/lynxburn/README.md)

Planned work lives in the corresponding module/theme SPEC files plus the
top-level [`SPEC.md`](./SPEC.md).

## Screenshots

- `[placeholder] full desktop overview`
- `[placeholder] lxbar and compact widget row`
- `[placeholder] popup stack and cycling flow`
- `[placeholder] lxrunner`

## Further Docs

- [`SPEC.md`](./SPEC.md): top-level planned work
- [`DEVELOPMENT.md`](./DEVELOPMENT.md): internal architecture and extension notes
- [`CONTRIBUTING.md`](./CONTRIBUTING.md): contribution scope and expectations
- [`CHANGELOG.md`](./CHANGELOG.md): repository changelog generated from commit history
- [`MIGRATE.md`](./MIGRATE.md): temporary notes for older machines still moving from the `migrate` tag
- [`LICENSE.md`](./LICENSE.md): repository licensing and third-party notices
