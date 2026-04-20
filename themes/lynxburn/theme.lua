-- LynxBurn AwesomeWM theme.
--
-- This version keeps only theme keys that are consumed by:
-- - Awesome core widgets and notifications used by this config
-- - themes/lynxburn/widgets.lua
-- - the bundled lxmedia, lxnotify, lxdisplay, and lxrunner modules
--
-- It intentionally drops copycats-era fields that are currently unused.

local os = os

local awful = require("awful")
local helpers = require("config.helpers")
local config_theme = require("config.theme")

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

--local font = "Terminus 8"
local font = "Hack Nerd Font Mono 9"
local padding = 2
local theme_dir = os.getenv("HOME") .. "/.config/awesome/themes/lynxburn"
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
    systray_icon_spacing = padding,
    widget_padding_top = padding,
    widget_padding_bottom = padding,
    widget_padding_left = padding,
    widget_padding_right = padding,

    fg_normal = roles.text,
    fg_focus = roles.text_accent,
    fg_minimize = roles.text_muted,
    fg_urgent = roles.text_urgent,
    bg_normal = roles.panel_bg,
    bg_focus = roles.panel_bg,
    bg_minimize = roles.panel_bg_muted,
    bg_systray = roles.panel_bg_active,
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
    notification_fg = roles.text,
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

    lxmedia_bg_hover = roles.raised_bg,
    lxmedia_button_bg = roles.panel_bg,
    lxmedia_button_hover = roles.hover_bg,
    lxmedia_hover_close_poll_interval = 0.25,
    lxmedia_hover_close_timeout = 2,
    lxmedia_osd_timeout = 1,
    lxmedia_popup_placement_media = "center",
    lxmedia_popup_placement_devices = "side",
    lxmedia_popup_width_media = 360,
    lxmedia_popup_width_devices = 360,
    lxmedia_artwork_width = 420,
    lxmedia_artwork_max_height = 680,
    lxmedia_icon_volume = "",
    lxmedia_icon_muted = "",
    lxmedia_icon_brightness = "󰃠",
    lxmedia_icon_mic_active = "🎙",
    lxmedia_icon_mic_muted = "×",
    lxmedia_icon_width = 20,
    lxmedia_bar_bg = roles.bar_bg,
    lxmedia_bar_fg = roles.bar_fg,
    lxmedia_bar_hover_open_delay = 0.5,
    lxmedia_mic_bar_bg = roles.bar_bg,
    lxmedia_mic_bar_fg = "#d98f8f",
    lxmedia_widget_fg = "#e8d7b6",
    lxmedia_widget_muted_fg = roles.text_muted,
    lxmedia_widget_mic_fg = "#ff7a7a",
    lxmedia_widget_mic_muted_fg = roles.text_muted,
    lxmedia_selected_border = roles.text_accent,

    lxnotify_icon_suspended = "󰂛",
    lxnotify_icon_idle = "󰂚",
    lxnotify_widget_font = "Hack Nerd Font Mono 9",
    lxnotify_widget_fg = "#e8d7b6",
    lxnotify_widget_suspended_fg = roles.text_muted,
    lxnotify_widget_hover_bg = roles.hover_bg,
    lxnotify_widget_press_bg = roles.hover_bg,
    lxnotify_popup_bg = roles.panel_bg,
    lxnotify_notification_card_bg = roles.raised_bg,
    lxnotify_notification_meta_fg = roles.text_meta,
    lxnotify_card_hover_bg = roles.hover_bg,
    lxnotify_button_bg = roles.raised_bg,
    lxnotify_button_hover = roles.hover_bg,
    lxnotify_popup_width = 360,
    lxbluetooth_popup_width = 360,
    lxnetwork_popup_width = 360,
    lxpower_popup_width = 360,
    lxnotify_popup_placement = "side",
    lxnotify_notification_icon_size = 32,
    lxnotify_group_icon_size = 20,
    lxnotify_selected_bg = roles.text_accent,
    lxnotify_urgency_low_fg = palette.low,
    lxnotify_urgency_normal_fg = palette.normal,
    lxnotify_urgency_critical_fg = palette.critical,

    lxdisplay_icon = "󰃟",
    lxdisplay_icon_night = "󰖔",
    lxdisplay_icon_brightness = "󰃠",
    lxdisplay_icon_font = font,
    lxdisplay_icon_width = 22,
    lxdisplay_widget_fg = roles.text,
    lxdisplay_widget_suspended_fg = "#8b8177",
    lxdisplay_bar_width = 36,
    lxdisplay_bar_height = 8,
    lxdisplay_bar_spacing = 8,
    lxdisplay_bar_bg = roles.bar_bg,
    lxdisplay_bar_fg = roles.bar_fg,
    lxdisplay_bar_hover_open_delay = 0.5,
    lxdisplay_widget_hover_bg = roles.raised_bg,
    lxdisplay_widget_press_bg = roles.hover_bg,
    lxdisplay_osd_bar_bg = roles.bar_bg,
    lxdisplay_osd_bar_fg = roles.bar_fg,
    lxdisplay_osd_width = 260,
    lxdisplay_osd_height = 18,
    lxdisplay_osd_margin = 16,
    lxdisplay_osd_timeout = 1,

    lxbluetooth_icon = "",
    lxbluetooth_popup_placement = "side",
    lxbluetooth_icon_width = 24,
    lxbluetooth_widget_hover_bg = roles.raised_bg,
    lxbluetooth_widget_press_bg = roles.hover_bg,
    lxnetwork_icon = "",
    lxnetwork_icon_disabled = "󰖪",
    lxnetwork_popup_placement = "side",
    lxnetwork_icon_width = 30,
    lxnetwork_widget_hover_bg = roles.raised_bg,
    lxnetwork_widget_press_bg = roles.hover_bg,
    lxnetwork_widget_vpn_fg = palette.critical,
    lxpower_icon_ac = "",
    lxpower_icon_battery = "",
    lxpower_popup_placement = "center",
    lxpower_icon_pinned = "",
    lxpower_icon_width = 24,
    lxpower_widget_hover_bg = roles.raised_bg,
    lxpower_widget_press_bg = roles.hover_bg,
    lxpower_profile_fg_powersave = roles.text_muted,
    lxpower_profile_fg_balanced = roles.text,
    lxpower_profile_fg_performance = palette.critical,

    lxrunner_bg = roles.panel_bg,
    lxrunner_border_color = roles.panel_border,
    lxrunner_border_width = 1,
    lxrunner_cursor = "_",
    lxrunner_input_bg = roles.panel_bg_muted,
    lxrunner_input_fg = roles.text,
    lxrunner_input_font = font,
    lxrunner_prompt_fg = roles.text_accent,
    lxrunner_radius = 6,
    lxrunner_outer_margin = 10,
    lxrunner_padding = 12,
    lxrunner_row_bg = roles.panel_bg,
    lxrunner_row_fg = roles.text_meta,
    lxrunner_row_font = font,
    lxrunner_row_padding = 10,
    lxrunner_row_selected_bg = roles.raised_bg,
    lxrunner_row_selected_fg = roles.text,
    lxrunner_icon_font = font,
    lxrunner_icon_size = 14,
    lxrunner_icon_text_spacing = 8,
}

local theme_overrides = config_theme.overrides()
local custom_at_screen_connect = theme_overrides.at_screen_connect

theme_overrides.at_screen_connect = nil
helpers.deep_merge(theme, theme_overrides)

theme.at_screen_connect = require("themes.lynxburn.widgets").build(theme)

if custom_at_screen_connect then
    theme.at_screen_connect = custom_at_screen_connect
end

return theme
