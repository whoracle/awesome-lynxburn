# lxnotify

`lxnotify` is the local AwesomeWM notification inbox used by this config.

It retains actionable or missed `naughty` notifications in a compact popup
UI. It is not a generic notification database and it does not try to own every
live-notification behavior on the desktop.

## Dependencies

External:

- AwesomeWM core libraries: `awful`, `gears`, `wibox`, `beautiful`
- `naughty`

Internal:

- `lxcommon.popup_control`
- `lxcommon.popup_placement`
- `lxcommon.widget_feedback`
- `lxbar` only if popup cycling integration is enabled through shared services

## Features

- intercept new `naughty` notifications into a retained inbox
- compact bell-only top-level widget
- grouped and ungrouped notification cards
- per-group detail view
- keyboard navigation inside the popup
- popup cycling participation through shared `lxbar` services
- separate toggles for:
  - daemon suspension
  - inbox interception pause
- notification action invocation and dismiss handling

## Example Usage

lxbar block:

```lua
lxmodules = {
    lxbar = {
        order = { "network", "media", "notify" },
    },
}
```

Keybinding via service action:

```lua
{
    description = "show notification popup",
    group = "awesome",
    on_press = "show_notification_popup",
}
```

## Controls

Top-level widget:

- left click: toggle popup
- middle click: toggle `naughty` pause/suspension
- right click: dismiss all stored notifications

Popup cards:

- notification card left click: dismiss
- notification card right click: invoke notification action / activate client
- group card left click: enter group
- group card right click: enter group

## Keyboard Controls

When the popup is opened in keyboard-friendly mode:

- `Up` / `Down`: move selection
- `Right`:
  - notification card: dismiss
  - group card: enter group
- `Enter`:
  - notification card: invoke action / activate client
  - group card: enter group
- `Left`:
  - inside group: go back
  - top-level list: close popup
- `Escape`: close popup

If popup cycling is enabled through `lxbar`, the shared prev/next popup
keychains are also passed into the popup keygrabber so cycling can continue
while `lxnotify` is focused.

## Configuration

`lxnotify` is configured through `lxmodules.lxnotify`:

```lua
lxmodules = {
    lxnotify = {
        notification_denylist = {
            { app_name = "Volume OSD" },
        },
        notification_title_max_length = 72,
        notification_body_max_length = 140,
        notification_source_max_length = 28,
        notification_time_format = "%H:%M",
        popup_visible_items = 7,
        interception_paused = false,
        debug_notifications = false,
    },
}
```

Supported knobs:

- `notification_denylist`
- `notification_title_max_length`
- `notification_body_max_length`
- `notification_source_max_length`
- `notification_time_format`
- `popup_visible_items`
- `interception_paused`
- `debug_notifications`

## Theme Variables

`lxnotify` reads these `beautiful` keys:

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
- `lxnotify_hover_close_timeout`
- `lxnotify_hover_close_poll_interval`
- `lxnotify_notification_title_max_length`
- `lxnotify_notification_body_max_length`
- `lxnotify_notification_source_max_length`
- `lxnotify_notification_time_format`
- `lxnotify_popup_visible_items`
- `lxnotify_urgency_low_fg`
- `lxnotify_urgency_normal_fg`
- `lxnotify_urgency_critical_fg`

Placement is configured as `"center"` or `"side"`. When set to `"side"`, the
actual side follows `lxmodules.lxbar.popup_side`.

## Dismiss Semantics

When `naughty` is suspended, dismissing stored notifications should clear the
`lxnotify` inbox without destroying the underlying notification object in ways
that trigger browser or web-app side effects. The module preserves that split.

## Public Instance API

Commonly used instance methods:

- `instance:refresh()`
- `instance:reload()`
- `instance:toggle_suspend()`
- `instance:toggle_daemon_pause()`
- `instance:toggle_interception_pause()`
- `instance:close_popups()`
- `instance:toggle_notification_popup(opts)`
- `instance:show_notification_popup(opts)`
- `instance:dismiss_all()`
- `instance:dismiss_group(group_key)`

## Screenshots

- `[placeholder] inbox popup`
- `[placeholder] grouped detail view`
- `[placeholder] bell widget states`

## Code Layout

- `init.lua`: constructor and public module entry point
- `theme.lua`: theme accessors, widget markup, refresh/reload helpers
- `store.lua`: notification interception, filtering, entry lifecycle, and dismiss logic
- `popup_state.lua`: grouped view state, selection, scrolling, and popup list rebuilding
- `controller.lua`: popup session control, keygrabber wiring, hover-close, and open/close paths
- `popup.lua`: popup shell, geometry, and header widgets
- `cards.lua`: notification and burst-group card rendering
- `format.lua`: notification text normalization, summaries, and grouping keys
- `debug.lua`: normalized notification snapshots and denylist matching helpers
- `actions.lua`: notification invoke / destroy helpers
- `widget.lua`: compact bell widget
- `util.lua`: theme lookup and shared widget helpers

## Notes

- browser and web-app notifications remain the most fragile invocation path
  because their action objects and client associations are less predictable than
  native app notifications
- no secrets or passwords are currently embedded in `lxnotify`
