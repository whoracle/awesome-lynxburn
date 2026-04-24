# lynxburn

`lynxburn` is the bundled AwesomeWM theme used by this config.

It owns the visual layer: spacing, fonts, icon paths, Awesome core theme keys,
and theme-scoped values consumed by the bundled `lx*` modules. It also
provides the per-screen wibar assembly used by the current desktop and now
supports swappable color schemes inside the same theme shell.

Normal in-bar widgets should now go through `lxbar`, including custom
non-`lx*` widgets such as the bundled `systray`, IMAP mail, and `lain`
metric examples.
`themes/lynxburn/widgets.lua` remains the right place only for theme-owned
shell composition and for extra widgets you intentionally place outside
`lxbar`.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `beautiful`, `gears`, `wibox`
- `lain`
- the Zenburn Awesome theme assets for titlebar button images

Internal:

- `config.theme`
- `config.config_data`
- `config.helpers`
- `config.services`
- `config.tags`
- `config.layouts`

## Features

- central bundled theme entrypoint for this repo
- swappable color-scheme layer for Awesome core and bundled modules
- structural theme layer for spacing, sizing, placement, icon paths, and other
  non-color theme values
- per-screen wibar assembly in `widgets.lua`
- support for user theme overrides through top-level `config.lua`
- bundled theme keys for `lxmedia`, `lxnotify`, `lxdisplay`, `lxrunner`,
  `lxbluetooth`, `lxnetwork`, `lxpower`, and `lxsecrets`

## Example Usage

Top-level config override:

```lua
theme = {
    name = "lynxburn",
    color_scheme = "lynxburn",
    font = "Hack Nerd Font Mono 10",
    wallpaper = os.getenv("HOME") .. "/.wallpaper-alt",
    lxrunner_row_selected_bg = "#4a2f25",
    lxdisplay_bar_fg = "#d88166",
}
```

Theme initialization path:

```lua
local beautiful = require("beautiful")
local config = require("config.init")

config.theme.init(beautiful)
```

## Configuration

The theme is configured through the top-level `theme` table in `config.lua`.

Supported top-level knobs:

- `name`
- `color_scheme`
- any `beautiful.*` key defined by `themes/lynxburn/theme.lua`

Bundled color schemes:

- `lynxburn`
- `nord`
- `zenburn`
- `catppuccin`
- `solarized_light`
- `solarized_dark`
- `kanagawa_wave`
- `kanagawa_dragon`
- `kanagawa_lotus`

The current flow is:

1. `config.theme.name()` chooses the theme name, defaulting to `lynxburn`
2. `config.theme.color_scheme()` chooses the color scheme, defaulting to `lynxburn`
3. `config.theme.init(beautiful)` loads `themes/<name>/theme.lua`
4. `themes/<name>/theme.lua` composes the structural layer plus the chosen
   color scheme
5. keys from `config.lua` under `theme = { ... }` are applied as final overrides

## Theme Variables

Core/theme-shell values:

- `dir`
- `wallpaper`
- `font`
- `border_width`
- `useless_gap`
- `wibar_height`
- `wibar_position`
- `space`
- `widget_padding_top`
- `widget_padding_bottom`
- `widget_padding_left`
- `widget_padding_right`
- `tasklist_plain_task_name`
- `tasklist_disable_icon`
- `fg_normal`
- `fg_focus`
- `fg_minimize`
- `fg_urgent`
- `bg_normal`
- `bg_focus`
- `bg_minimize`
- `bg_systray`
- `bg_urgent`
- `border_normal`
- `border_focus`

Awesome core widget values:

- `tasklist_bg_normal`
- `tasklist_bg_focus`
- `tasklist_fg_normal`
- `tasklist_fg_focus`
- `taglist_bg_normal`
- `taglist_bg_focus`
- `taglist_fg_normal`
- `taglist_fg_focus`
- `taglist_squares_sel`
- `taglist_squares_unsel`
- `notification_icon_size`
- `notification_bg`
- `notification_fg`
- `notification_border_width`
- `notification_border_color`
- `notification_max_width`

Awesome titlebar assets:

- `titlebar_close_button_normal`
- `titlebar_close_button_focus`
- `titlebar_ontop_button_normal_inactive`
- `titlebar_ontop_button_focus_inactive`
- `titlebar_ontop_button_normal_active`
- `titlebar_ontop_button_focus_active`
- `titlebar_sticky_button_normal_inactive`
- `titlebar_sticky_button_focus_inactive`
- `titlebar_sticky_button_normal_active`
- `titlebar_sticky_button_focus_active`
- `titlebar_floating_button_normal_inactive`
- `titlebar_floating_button_focus_inactive`
- `titlebar_floating_button_normal_active`
- `titlebar_floating_button_focus_active`
- `titlebar_maximized_button_normal_inactive`
- `titlebar_maximized_button_focus_inactive`
- `titlebar_maximized_button_normal_active`
- `titlebar_maximized_button_focus_active`

Legacy/bundled widget assets:

- `icon_mail`
- `icon_cpu`
- `icon_sysload`
- `icon_mem`
- `icon_fs`
- `icon_powermenu`

Layout label values:

- `layout_txt_fairv`
- `layout_txt_fairh`
- `layout_txt_centerwork`
- `layout_txt_centerworkh`
- `layout_txt_floating`

`lxmedia` values:

- `lxmedia_bg_hover`
- `lxmedia_popup_bg`
- `lxmedia_button_bg`
- `lxmedia_button_hover`
- `lxmedia_hover_close_poll_interval`
- `lxmedia_hover_close_timeout`
- `lxmedia_osd_timeout`
- `lxmedia_popup_placement_media`
- `lxmedia_popup_placement_devices`
- `lxmedia_popup_width_media`
- `lxmedia_popup_width_devices`
- `lxmedia_artwork_width`
- `lxmedia_artwork_max_height`
- `lxmedia_icon_volume`
- `lxmedia_icon_muted`
- `lxmedia_icon_brightness`
- `lxmedia_icon_mic_active`
- `lxmedia_icon_mic_muted`
- `lxmedia_icon_width`
- `lxmedia_bar_bg`
- `lxmedia_bar_fg`
- `lxmedia_mic_bar_bg`
- `lxmedia_mic_bar_fg`
- `lxmedia_osd_bar_bg`
- `lxmedia_osd_bar_fg`
- `lxmedia_widget_fg`
- `lxmedia_widget_muted_fg`
- `lxmedia_widget_mic_fg`
- `lxmedia_widget_mic_muted_fg`
- `lxmedia_selected_border`

`lxnotify` values:

- `lxnotify_icon_suspended`
- `lxnotify_icon_idle`
- `lxnotify_icon_width`
- `lxnotify_widget_font`
- `lxnotify_widget_fg`
- `lxnotify_widget_suspended_fg`
- `lxnotify_widget_hover_bg`
- `lxnotify_widget_press_bg`
- `lxnotify_popup_bg`
- `lxnotify_notification_card_bg`
- `lxnotify_notification_meta_fg`
- `lxnotify_card_hover_bg`
- `lxnotify_button_bg`
- `lxnotify_button_hover`
- `lxnotify_popup_width`
- `lxnotify_popup_placement`
- `lxnotify_notification_icon_size`
- `lxnotify_group_icon_size`
- `lxnotify_selected_bg`
- `lxnotify_urgency_low_fg`
- `lxnotify_urgency_normal_fg`
- `lxnotify_urgency_critical_fg`

`lxdisplay` values:

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
- `lxdisplay_button_bg`
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

`lxbluetooth` values:

- `lxbluetooth_icon`
- `lxbluetooth_popup_placement`
- `lxbluetooth_icon_width`
- `lxbluetooth_widget_fg`
- `lxbluetooth_widget_disabled_fg`
- `lxbluetooth_widget_hover_bg`
- `lxbluetooth_widget_press_bg`
- `lxbluetooth_popup_bg`
- `lxbluetooth_button_hover`
- `lxbluetooth_selected_bg`
- `lxbluetooth_meta_fg`
- `lxbluetooth_popup_width`

`lxnetwork` values:

- `lxnetwork_icon`
- `lxnetwork_icon_disabled`
- `lxnetwork_popup_placement`
- `lxnetwork_icon_width`
- `lxnetwork_widget_fg`
- `lxnetwork_widget_disabled_fg`
- `lxnetwork_widget_hover_bg`
- `lxnetwork_widget_press_bg`
- `lxnetwork_popup_bg`
- `lxnetwork_button_hover`
- `lxnetwork_selected_bg`
- `lxnetwork_meta_fg`
- `lxnetwork_widget_vpn_fg`
- `lxnetwork_signal_bar_bg`
- `lxnetwork_signal_bar_fg`
- `lxnetwork_popup_width`

`lxpower` values:

- `lxpower_icon_ac`
- `lxpower_icon_battery`
- `lxpower_popup_placement`
- `lxpower_popup_width`
- `lxpower_icon_pinned`
- `lxpower_icon_width`
- `lxpower_widget_fg`
- `lxpower_widget_hover_bg`
- `lxpower_widget_press_bg`
- `lxpower_popup_bg`
- `lxpower_button_hover`
- `lxpower_selected_bg`
- `lxpower_meta_fg`
- `lxpower_profile_fg_powersave`
- `lxpower_profile_fg_balanced`
- `lxpower_profile_fg_performance`

`lxsecrets` values:

- `lxsecrets_icon`
- `lxsecrets_icon_font`
- `lxsecrets_icon_width`
- `lxsecrets_widget_fg`
- `lxsecrets_widget_suspended_fg`
- `lxsecrets_widget_attention_fg`
- `lxsecrets_widget_hover_bg`
- `lxsecrets_widget_press_bg`
- `lxsecrets_popup_bg`
- `lxsecrets_popup_width`
- `lxsecrets_popup_placement`
- `lxsecrets_button_bg`
- `lxsecrets_button_hover`
- `lxsecrets_selected_bg`
- `lxsecrets_meta_fg`

`lxrunner` values:

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

- `[placeholder] full desktop with wibar`
- `[placeholder] widget cluster close-up`
- `[placeholder] popup-heavy workflow with theme colors`
- `[placeholder] palette: lynxburn`
- `[placeholder] palette: zenburn`
- `[placeholder] palette: nord`
- `[placeholder] palette: catppuccin`
- `[placeholder] palette: solarized_light`
- `[placeholder] palette: solarized_dark`
- `[placeholder] palette: kanagawa_wave`
- `[placeholder] palette: kanagawa_dragon`
- `[placeholder] palette: kanagawa_lotus`

## File Layout

- `theme.lua`: theme composition entrypoint and final override merge
- `structure.lua`: spacing, sizing, icon paths, placements, and other
  non-color theme values
- `colors/lynxburn.lua`: the bundled house palette, role mapping, fonts, and
  color-bearing theme keys
- `colors/default.lua`: compatibility alias for the `lynxburn` color scheme
- `colors/nord.lua`: bundled cool dark alternative
- `colors/zenburn.lua`: bundled classic Zenburn-inspired alternative
- `colors/catppuccin.lua`: bundled soft dark alternative
- `colors/solarized_light.lua`: bundled light alternative
- `colors/solarized_dark.lua`: bundled classic dark Solarized alternative
- `colors/kanagawa_wave.lua`: bundled Kanagawa Wave variant
- `colors/kanagawa_dragon.lua`: bundled Kanagawa Dragon variant
- `colors/kanagawa_lotus.lua`: bundled Kanagawa Lotus light variant
- `widgets.lua`: per-screen wibar assembly and theme-specific widget setup

## Notes

- user-facing theme overrides belong in top-level `config.lua`, not in
  per-module config
- `widgets.lua` still intentionally owns:
  - wallpaper application
  - wibar assembly
  - tasklist/taglist/layout switcher composition
  - systray / clock / date placement
- `widgets.lua` still contains older non-`lx*` widget assembly that will likely
  be reduced later as more functionality moves into modules; the main likely
  future move candidates are the IMAP mail widget, the lain metric widgets, and
  the custom power menu popup
- `color_scheme` changes only the scheme layer; spacing/layout/widget placement
  remains owned by the `lynxburn` theme shell
