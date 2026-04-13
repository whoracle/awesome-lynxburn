-- LynxBurn AwesomeWM theme, streamlined proposal.
--
-- This version keeps only theme keys that are consumed by:
-- - Awesome core widgets and notifications used by this config
-- - themes/lynxburn2/widgets.lua
-- - the bundled lxaudio, lxnotify, lxdisplay, and lxrunner modules
--
-- It intentionally drops copycats-era fields that are currently unused.

local os = os

local awful = require("awful")
local helpers = require("config.helpers")

local palette = {
    accent = "#d88166",
    urgent = "#123456",
    fg = "#e2ccb0",
    bg = "#333333",
    bg_alt = "#140c0b",
    bg_dark = "#111111",
    border = "#94928F",
    black = "#000000",
    hover = "#444444",
    hover_strong = "#666666",
    muted = "#9b8f86",
    meta = "#b9aea3",
    low = "#7aa2c9",
    normal = "#c0b18b",
    critical = "#d97777",
}

local font = "Terminus 8"
local padding = 2
local theme_dir = os.getenv("HOME") .. "/.config/awesome/themes/lynxburn2"
local zenburn_dir = awful.util.get_themes_dir() .. "zenburn"

local roles = {
    panel_bg = palette.bg,
    panel_bg_active = palette.bg_alt,
    panel_bg_muted = palette.bg_dark,
    panel_border = palette.border,
    text = palette.fg,
    text_accent = palette.accent,
    text_urgent = palette.urgent,
    text_muted = palette.muted,
    text_meta = palette.meta,
    raised_bg = palette.hover,
    hover_bg = palette.hover_strong,
    notification_bg = palette.black,
    bar_bg = palette.bg_alt,
    bar_fg = palette.fg,
}

local theme = {
    dir = theme_dir,
    wallpaper = os.getenv("HOME") .. "/.wallpaper",

    font = font,
    border_width = 1,
    useless_gap = 5,

    wibar_height = 20,
    wibar_position = "top",
    space = " ",
    widget_padding_top = padding,
    widget_padding_bottom = padding,
    widget_padding_left = padding,
    widget_padding_right = padding,

    fg_normal = roles.text,
    fg_focus = roles.text_accent,
    fg_urgent = roles.text_urgent,
    bg_normal = roles.panel_bg,
    bg_focus = roles.panel_bg,
    bg_urgent = roles.panel_bg_active,
    border_normal = roles.notification_bg,
    border_focus = roles.panel_border,

    tasklist_plain_task_name = true,
    tasklist_disable_icon = false,
    tasklist_bg_normal = roles.panel_bg,
    tasklist_bg_focus = roles.panel_bg_active,
    tasklist_fg_normal = roles.panel_border,
    tasklist_fg_focus = roles.text_accent,
    taglist_bg_normal = roles.panel_bg,
    taglist_bg_focus = roles.panel_bg_active,
    taglist_fg_normal = roles.panel_border,
    taglist_fg_focus = roles.text_accent,
    taglist_squares_sel = theme_dir .. "/icons/square_sel.png",
    taglist_squares_unsel = theme_dir .. "/icons/square_unsel.png",

    notification_icon_size = 50,
    notification_bg = roles.notification_bg,
    notification_border_width = 1,
    notification_border_color = roles.panel_border,
    notification_max_width = 500,

    titlebar_close_button_normal = zenburn_dir .. "/titlebar/close_normal.png",
    titlebar_close_button_focus = zenburn_dir .. "/titlebar/close_focus.png",
    titlebar_ontop_button_normal_inactive = zenburn_dir .. "/titlebar/ontop_normal_inactive.png",
    titlebar_ontop_button_focus_inactive = zenburn_dir .. "/titlebar/ontop_focus_inactive.png",
    titlebar_ontop_button_normal_active = zenburn_dir .. "/titlebar/ontop_normal_active.png",
    titlebar_ontop_button_focus_active = zenburn_dir .. "/titlebar/ontop_focus_active.png",
    titlebar_sticky_button_normal_inactive = zenburn_dir .. "/titlebar/sticky_normal_inactive.png",
    titlebar_sticky_button_focus_inactive = zenburn_dir .. "/titlebar/sticky_focus_inactive.png",
    titlebar_sticky_button_normal_active = zenburn_dir .. "/titlebar/sticky_normal_active.png",
    titlebar_sticky_button_focus_active = zenburn_dir .. "/titlebar/sticky_focus_active.png",
    titlebar_floating_button_normal_inactive = zenburn_dir .. "/titlebar/floating_normal_inactive.png",
    titlebar_floating_button_focus_inactive = zenburn_dir .. "/titlebar/floating_focus_inactive.png",
    titlebar_floating_button_normal_active = zenburn_dir .. "/titlebar/floating_normal_active.png",
    titlebar_floating_button_focus_active = zenburn_dir .. "/titlebar/floating_focus_active.png",
    titlebar_maximized_button_normal_inactive = zenburn_dir .. "/titlebar/maximized_normal_inactive.png",
    titlebar_maximized_button_focus_inactive = zenburn_dir .. "/titlebar/maximized_focus_inactive.png",
    titlebar_maximized_button_normal_active = zenburn_dir .. "/titlebar/maximized_normal_active.png",
    titlebar_maximized_button_focus_active = zenburn_dir .. "/titlebar/maximized_focus_active.png",

    icon_mail = theme_dir .. "/icons/mail.png",
    icon_cpu = theme_dir .. "/icons/cpu.png",
    icon_sysload = theme_dir .. "/icons/cpu.png",
    icon_mem = theme_dir .. "/icons/mem.png",
    icon_fs = theme_dir .. "/icons/hdd.png",
    icon_powermenu = theme_dir .. "/icons/cpu.png",

    layout_txt_fairv = "vertical",
    layout_txt_fairh = "horizontal",
    layout_txt_centerwork = "centered",
    layout_txt_centerworkh = "centerh",
    layout_txt_floating = "floating",

    lxaudio_bg_hover = roles.raised_bg,
    lxaudio_button_hover = roles.hover_bg,
    lxaudio_hover_close_timeout = 2,
    lxaudio_icon_volume = "",
    lxaudio_icon_muted = "",
    lxaudio_icon_brightness = "󰃠",
    lxaudio_icon_mic_active = "🎙",
    lxaudio_bar_bg = roles.bar_bg,
    lxaudio_bar_fg = roles.bar_fg,

    lxnotify_icon_suspended = "󰂛 ",
    lxnotify_icon_notifications = "󰂚 ",
    lxnotify_icon_idle = "󰂚 ",
    lxnotify_widget_font = "Terminus 7",
    lxnotify_widget_fg = "#e8d7b6",
    lxnotify_widget_suspended_fg = roles.text_muted,
    lxnotify_notification_card_bg = roles.raised_bg,
    lxnotify_notification_meta_fg = roles.text_meta,
    lxnotify_bg_hover = roles.hover_bg,
    lxnotify_button_bg = roles.raised_bg,
    lxnotify_button_hover = roles.hover_bg,
    lxnotify_popup_width = 360,
    lxnotify_popup_edge = "right",
    lxnotify_notification_icon_size = 32,
    lxnotify_group_icon_size = 20,
    lxnotify_urgency_low_fg = palette.low,
    lxnotify_urgency_normal_fg = palette.normal,
    lxnotify_urgency_critical_fg = palette.critical,

    lxdisplay_icon = "󰃟 ",
    lxdisplay_icon_night = "󰖔 ",
    lxdisplay_show_bar = false,
    lxdisplay_widget_suspended_fg = "#8b8177",
    lxdisplay_bar_bg = roles.bar_bg,
    lxdisplay_bar_fg = roles.bar_fg,
    lxdisplay_osd_bar_bg = roles.bar_bg,
    lxdisplay_osd_bar_fg = roles.bar_fg,
    lxdisplay_osd_width = 260,
    lxdisplay_osd_height = 18,
    lxdisplay_osd_margin = 16,
    lxdisplay_osd_timeout = 1,
    lxdisplay_osd_screen_margin = 60,

    lxrunner_input_bg = roles.panel_bg_muted,
    lxrunner_row_count = 10,
    lxrunner_history_limit = 10,
    lxrunner_row_fg = roles.text_meta,
    lxrunner_row_selected_bg = roles.raised_bg,
    lxrunner_row_selected_fg = roles.text,
}

local theme_overrides = helpers.load_optional_module("config.override.theme", {})
local custom_at_screen_connect = theme_overrides.at_screen_connect

theme_overrides.at_screen_connect = nil
helpers.deep_merge(theme, theme_overrides)

theme.at_screen_connect = require("themes.lynxburn2.widgets").build(theme)

if custom_at_screen_connect then
    theme.at_screen_connect = custom_at_screen_connect
end

return theme
