# lxrunner

`lxrunner` is the compact AwesomeWM-native launcher used by this config.

It searches PATH commands, configured aliases, desktop entries, and recent
launch history in one small popup. It is intentionally narrow and does not try
to become a Rofi clone.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- `find` for PATH command and desktop-entry discovery
- optional `xclip` or `xsel` for middle-click primary-selection paste

Internal:

- `config.config_data`
- `lxcommon.util`

## Features

- centered launcher popup
- PATH command discovery
- desktop entry discovery
- alias support from `lxmodules.lxrunner.aliases`
- alias decorations via icon or glyph
- launch history with recency and invocation-count bias
- tab completion
- middle-click primary-selection paste in the input box

## Example Usage

Keybinding via service action:

```lua
{
    description = "toggle runner",
    group = "launcher",
    on_press = "toggle_lxrunner",
}
```

Config example:

```lua
lxmodules = {
    lxrunner = {
        width = 640,
        row_count = 12,
        history_limit = 20,
        prompt = "Run",
        aliases = {
            {
                name = "browser",
                type = "template",
                glyph = "󰖟",
                command = "firefox %s",
            },
        },
    },
}
```

## Controls

Popup:

- type to filter PATH commands, aliases, desktop entries, and history
- `Up` / `Down`: move selection
- `Tab`: complete highlighted/common prefix
- `Enter`: launch selection
- `BackSpace`: delete one character
- `Escape`: close runner
- middle click in the input field: paste primary selection

## Configuration

`lxrunner` is configured through `lxmodules.lxrunner`:

```lua
lxmodules = {
    lxrunner = {
        width = 520,
        row_count = 5,
        history_limit = 5,
        prompt = "Run",
        aliases = {},
    },
}
```

Supported knobs:

- `width`
- `row_count`
- `history_limit`
- `history_file`
- `prompt`
- `aliases`

Alias fields:

- `name`
- `type`
- `command`
- `env`
- `icon`
- `glyph`
- `glyph_font`
- `description`

Alias `type` values currently used:

- `"shell"`
- `"template"`

## Theme Variables

`lxrunner` reads these `beautiful` keys:

- `lxrunner_bg`
- `lxrunner_border_color`
- `lxrunner_border_width`
- `lxrunner_cursor`
- `lxrunner_input_bg`
- `lxrunner_input_fg`
- `lxrunner_input_font`
- `lxrunner_prompt_fg`
- `lxrunner_radius`
- `lxrunner_outer_margin`
- `lxrunner_padding`
- `lxrunner_row_bg`
- `lxrunner_row_fg`
- `lxrunner_row_font`
- `lxrunner_row_padding`
- `lxrunner_row_selected_bg`
- `lxrunner_row_selected_fg`
- `lxrunner_icon_font`
- `lxrunner_icon_size`
- `lxrunner_icon_text_spacing`

## Screenshots

- `[placeholder] empty runner`
- `[placeholder] filtered results`
- `[placeholder] alias with glyph/icon`

## File Layout

- `init.lua`: constructor and module wiring
- `sources.lua`: PATH, desktop-entry, and alias loading/resolution
- `history.lua`: history persistence, ranking, filtering, and completion
- `ui.lua`: prompt/result rendering and popup construction
- `controller.lua`: keygrabber, mousegrabber, and show/hide/toggle flow
- `icons/`: built-in row-decoration icons

## Notes

- `lxrunner` stores launch history in `~/.lxrunner_history` by default
- persisted history entries also track invocation counts and use them during
  ranking
- the top-level startup preflight checks `find` because command and
  desktop-entry discovery depend on it
- no secrets or credentials are embedded in the module
