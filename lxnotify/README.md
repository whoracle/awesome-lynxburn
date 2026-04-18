# lxnotify

`lxnotify` is the local AwesomeWM notification inbox used by this config.

It is not a generic notification mirror. Its job is to retain actionable or
missed notifications in a compact popup-oriented UI, while still letting the
rest of the desktop decide whether live `naughty` popups are shown.

## Current Behavior

`lxnotify` currently provides:

- interception of new `naughty` notifications into a retained inbox
- a compact bell-only top-level widget
- a right-edge popup with:
  - grouped and ungrouped notification cards
  - keyboard navigation
  - group detail view
  - dismiss / action handling
- separate control over:
  - `naughty` suspension
  - interception pause

The compact widget no longer shows a numeric unread count.

Its current visual contract is:

- unread always overrides to red
- gold bell: `naughty` enabled, intercept enabled
- grey bell: `naughty` enabled, intercept disabled
- struck gold bell: `naughty` disabled, intercept enabled
- struck grey bell: both disabled

## Mouse Controls

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

## Notes On Dismiss Semantics

One important behavior difference exists when `naughty` is suspended:

- dismissing stored notifications from `lxnotify` should remove them from the
  retained inbox
- it should not destroy the underlying notification object in a way that
  triggers browser/web-app side effects

The current code explicitly avoids underlying destroy calls during suspended
dismiss-all paths for that reason.

## Instance API

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

## Theme Keys

`lxnotify` is themed through `beautiful.lxnotify_*`.

The most important current keys are:

- `beautiful.lxnotify_icon_suspended`
- `beautiful.lxnotify_icon_idle`
- `beautiful.lxnotify_widget_fg`
- `beautiful.lxnotify_widget_suspended_fg`
- `beautiful.lxnotify_urgency_critical_fg`
- `beautiful.lxnotify_popup_width`
- `beautiful.lxnotify_popup_placement`
- `beautiful.lxnotify_popup_bg`
- `beautiful.lxnotify_notification_card_bg`
- `beautiful.lxnotify_bg_hover`
- `beautiful.lxnotify_button_hover`
- `beautiful.lxnotify_selected_bg`

The popup width in the current theme is normalized to `360`.
Placement is configured as `"center"` or `"side"`; the actual left/right side
comes from `lxmodules.lxbar.popup_side`.

## Code Layout

- `init.lua`: instance lifecycle, interception hooks, popup state, and public API
- `popup.lua`: popup shell, geometry, and header widgets
- `cards.lua`: notification and burst-group card rendering
- `format.lua`: notification text normalization, summaries, and grouping keys
- `debug.lua`: normalized notification snapshots and denylist matching helpers
- `actions.lua`: notification invoke / destroy helpers
- `widget.lua`: compact bell widget
- `util.lua`: theme lookup and shared widget helpers

## Known Rough Edges

- browser and web-app notifications remain the most fragile invocation path
  because their action objects and client associations are less predictable than
  native app notifications
- `lxnotify` still owns more popup/controller duplication than it should; some
  of that should eventually move into `lxcommon`
