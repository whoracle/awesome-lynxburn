# lxnotify

AwesomeWM widget notification center

## Features

- intercept notifications sent via naughty
- wibar widget that shows number of unread notifications
- on click / keyboard toggle, displays a popup menu with unread notifications
- popup renders compact cards with title, truncated body, urgency, source, and timestamp
- updated notifications refresh the existing card instead of creating duplicates
- popup header includes independent controls for popup suppression and interception pause
- burst notifications group into summary cards that open a dedicated detail view
- cards and burst groups show notification icons when available
- themeable via `beautiful`

Notifications are (currently) not Consumed, but duplicated, so your regular naughty notifications will keep working.

`lxnotify` is intended to behave as a short-term retained inbox for missed or inconvenient notifications, not as a strict mirror of currently live `naughty` popups. Notifications may remain available in `lxnotify` after the original popup has expired so they can be reviewed later.

Possible future direction:

- keep a collapsed list of past-session notifications
- keep a separate list of follow-up notifications

## Dependencies

- AwesomeWM with Lua support
- `beautiful`
- `awful`
- `naughty`
- `gears`

## Installation

Place the project somewhere Awesome can `require`, with the module directory named `lxnotify`.

Example layout:

```text
~/.config/awesome/
├── rc.lua
└── lxnotify/
    ├── actions.lua
    ├── cards.lua
    ├── debug.lua
    ├── format.lua
    ├── init.lua
    ├── popup.lua
    ├── util.lua
    └── widget.lua
```

## Code Layout

The codebase is split by responsibility:

- `init.lua`: instance lifecycle, interception hooks, popup state, and public API
- `popup.lua`: popup shell, geometry, and header widgets
- `cards.lua`: notification and burst-group card rendering
- `format.lua`: notification text normalization, summaries, and grouping keys
- `debug.lua`: normalized notification snapshots and denylist matching helpers
- `actions.lua`: dismiss/invoke helpers for underlying `naughty` notifications
- `widget.lua`: compact wibar widget
- `util.lua`: theme lookup, screen resolution, and shared widget helpers

If you change behavior permanently, update the relevant module and keep this README in sync with the user-facing result rather than every transient implementation detail.

## Usage

Basic example in `rc.lua`:

```lua
local awful = require("awful")
local wibox = require("wibox")
local lxnotify = require("lxnotify")

local notify = lxnotify.new()

awful.screen.connect_for_each_screen(function(s)
    s.mywibox = awful.wibar({ position = "top", screen = s })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        nil,
        nil,
        {
            layout = wibox.layout.fixed.horizontal,
            notify.widget,
        },
    }
end)
```

You create an instance with `lxnotify.new(opts)` and place `instance.widget` anywhere a normal Awesome widget can be used.

Visual configuration is read from `beautiful.lxnotify_*` inside the module code. In a typical Awesome theme file, that means defining the keys on the theme table itself, for example `theme.lxnotify_popup_bg = "#333333"`, which `beautiful` then exposes as `beautiful.lxnotify_popup_bg`. `opts` is intentionally limited to behavioral switches such as interception pause, debugging, and denylist rules. Popup colors, card colors, hover colors, sizes, widths, and related styling should be configured in the theme, not passed to `lxnotify.new()`.

### Mouse Controls

On the main widget:

- left click: toggle notification popup
- right click: dismiss all unread notifications
- middle click: silence visible notification popups while lxnotify continues to capture

Inside the popup:

- left click a notification card: dismiss notification
- right click a notification card: invoke its default action, focus an associated client, or fall back to its run/callback handler
- header button: toggle popup suppression
- header button: toggle lxnotify interception pause
- burst group header: open a dedicated detail view for that burst
- group detail header button: dismiss the entire currently opened burst group
- mouse wheel inside the popup: scroll the currently visible popup list or group detail list
- when opened in keyboard-friendly mode, `Up` / `Down` move the selected card, `Right` dismisses a notification or opens a burst group, `Enter` invokes the selected notification action, and `Left` goes back from group detail or closes the popup from the top-level list

## Configuration

`lxnotify.new(opts)` supports these behavioral options:

| Option | Default | Meaning |
| --- | --- | --- |
| `debug_notifications` | `false` | Log a debug snapshot of each intercepted notification via Awesome's warning log. |
| `notification_denylist` | `{}` | Array of filter rules used to skip selected notifications. |
| `interception_paused` | `false` | Start lxnotify with notification capture paused. |

Visual `opts` such as popup colors, card colors, hover colors, dimensions, icon sizes, and text limits are not part of the intended configuration surface anymore; set the corresponding `theme.lxnotify_*` keys instead.

Useful instance methods:

- `instance:refresh()`
  Refresh widget state immediately.
- `instance:reload()`
  Refresh widget state and reapply popup layout if visible.
- `instance:toggle_suspend()`
  Toggle visible notification popups without disabling lxnotify capture.
- `instance:toggle_daemon_pause()`
  Toggle visible notification popups without disabling lxnotify capture.
- `instance:toggle_interception_pause()`
  Toggle lxnotify interception of new notifications.
- `instance:close_popups()`
  Close any open popups.
- `instance:toggle_notification_popup(opts)`
  Toggle the notification popup manually.
- `instance:show_notification_popup(opts)`
  Show the notification popup without toggling it off if already visible.
- `instance:dismiss_active_group()`
  Dismiss every notification in the currently opened burst group.
- `instance:debug_notification(notification)`
  Log the normalized debug snapshot for one notification when debugging is enabled.
- `instance:should_ignore_notification(notification)`
  Return `true` when a notification matches the configured denylist.


### Keyboard Shortcuts

The instance API is intended to be usable from Awesome keybindings.

Example:

```lua
local awful = require("awful")
local gears = require("gears")
local lxnotify = require("lxnotify")

local notificationcenter = lxnotify.new()

root.keys(gears.table.join(
    root.keys(),
    awful.key({"Mod4"}, "n", function()
        notificationcenter:toggle_suspend()
    end),
    awful.key({ "Mod4", "Shift" }, "p", function()
        notificationcenter:toggle_notification_popup({
            hover_close = false,
            toggle_key = {
                modifiers = { "Mod4", "Shift" },
                key = "p",
            },
        })
    end),
    awful.key({}, "Escape", function()
        notificationcenter:close_popups()
    end)
))
```

Notes:

- `toggle_*_popup({ hover_close = false, toggle_key = { modifiers = { ... }, key = "..." } })` is the keyboard-friendly form. It disables the "mouse leaves popup" auto-close timer and lets the modal popup treat the same key chord as "close".
- keyboard-friendly popup sessions also start a modal keygrabber for `Up`, `Down`, `Right`, `Enter`, and `Left`
- if `toggle_key` is omitted, the popup still supports `Left` to close, but the original Awesome root keybinding cannot fire while the modal keygrabber is active
- the notification popup is always shown as a screen-edge panel on the resolved screen
- `notification_denylist` entries may be functions or tables. Table values are matched against the normalized debug snapshot; string values support exact match or Lua pattern match.

Example denylist:

```lua
local notificationcenter = lxnotify.new({
    debug_notifications = true,
    notification_denylist = {
        { app_name = "my-volume-osd" },
        { category = "calendar" },
        function(snapshot)
            return snapshot.title == "Volume" and snapshot.app_name == "naughty"
        end,
    },
})
```

## Theming

The widget reads colors, dimensions, and icons from `beautiful`.

In practice, when you are defining your theme, you usually set these on the theme table:

```lua
theme.lxnotify_popup_bg = "#181512"
theme.lxnotify_notification_card_bg = "#2c2320"
theme.lxnotify_button_hover = "#5b3d28"
```

After the theme is initialized, those become available as `beautiful.lxnotify_*`.

Supported theme keys:

| Theme Variable | Purpose |
| --- | --- |
| `beautiful.lxnotify_icon_suspended` | Muted speaker icon. |
| `beautiful.lxnotify_icon_notifications` | Unmuted speaker icon. |
| `beautiful.lxnotify_icon_idle` | Microphone activity icon. |
| `beautiful.lxnotify_widget_suspended_fg` | Foreground color of the compact icon while suspended. |
| `beautiful.lxnotify_widget_fg` | Foreground color of the compact icon while active. |
| `beautiful.lxnotify_popup_bg` | Popup panel background. |
| `beautiful.lxnotify_notification_card_bg` | Notification and group card background. |
| `beautiful.lxnotify_notification_meta_fg` | Metadata label foreground color. |
| `beautiful.lxnotify_bg_hover` | Hover background used in popup rows. |
| `beautiful.lxnotify_selected_border` | Border color used for the keyboard-selected popup card. |
| `beautiful.lxnotify_button_bg` | Button background. |
| `beautiful.lxnotify_button_hover` | Button hover background. |
| `beautiful.lxnotify_popup_width` | Width of the notification popup. |
| `beautiful.lxnotify_popup_edge` | Screen edge used by the popup. |
| `beautiful.lxnotify_hover_close_timeout` | Hover-close timeout override. |
| `beautiful.lxnotify_hover_close_poll_interval` | Hover-close poll interval override. |
| `beautiful.lxnotify_notification_title_max_length` | Title truncation limit for compact cards. |
| `beautiful.lxnotify_notification_body_max_length` | Body truncation limit for compact cards. |
| `beautiful.lxnotify_notification_source_max_length` | Source truncation limit for compact cards. |
| `beautiful.lxnotify_notification_time_format` | Timestamp format for compact cards. |
| `beautiful.lxnotify_notification_icon_size` | Preferred icon size for notification cards. |
| `beautiful.lxnotify_group_icon_size` | Preferred icon size for grouped burst headers. |
| `beautiful.notification_icon_size` | Fallback icon size for notification and group cards. |
| `beautiful.lxnotify_urgency_low_fg` | Foreground color of low-urgency labels. |
| `beautiful.lxnotify_urgency_normal_fg` | Foreground color of normal-urgency labels. |
| `beautiful.lxnotify_urgency_critical_fg` | Foreground color of critical-urgency labels. |
| `beautiful.lxnotify_popup_visible_items` | Maximum number of cards shown in the popup viewport at once. |

Example theme snippet:

```lua
theme.lxnotify_icon_suspended = "susp "
theme.lxnotify_icon_notifications = "unr "
theme.lxnotify_icon_idle = "clear"

theme.lxnotify_widget_fg = "#e8d7b6"
theme.lxnotify_widget_suspended_fg = "#9b8f86"

theme.lxnotify_popup_bg = "#181512"
theme.lxnotify_notification_card_bg = "#2c2320"
theme.lxnotify_notification_meta_fg = "#b9aea3"
theme.lxnotify_bg_hover = "#3a2f2b"
theme.lxnotify_selected_border = "#c0b18b"
theme.lxnotify_button_bg = "#2c2320"
theme.lxnotify_button_hover = "#5b3d28"
theme.lxnotify_popup_width = 460
theme.lxnotify_popup_edge = "right"

theme.lxnotify_notification_icon_size = 32
theme.lxnotify_group_icon_size = 20
theme.lxnotify_urgency_low_fg = "#7aa2c9"
theme.lxnotify_urgency_normal_fg = "#c0b18b"
theme.lxnotify_urgency_critical_fg = "#d97777"
```

Fallbacks:

- if a custom `lxnotify_*` theme variable is missing, the code falls back to common Awesome theme colors such as `bg_normal`, `bg_minimize`, `bg_focus`, `fg_minimize`, `fg_normal`, and `fg_urgent`
- if an icon variable is missing, built-in text icons are used
