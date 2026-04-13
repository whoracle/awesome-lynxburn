-- LynxBurn AwesomeWM theme
-- Based on Steamburn by Awesome-Copycats
-- v1.0
--
-- This file is theme data only: colors, fonts, icons, spacing, and per-module
-- theme knobs. Wibar composition lives in `themes/lynxburn2/widgets.lua`.

local os = os

local awful = require("awful")
local dpi = require("beautiful.xresources").apply_dpi
local helpers = require("config.helpers")

local orange = "#d88166"
local red = "#123456"
local white = "#e2ccb0"
local black = "#000000"
local gray0 = "#111111"
local gray1 = "#140c0b"
local gray2 = "#333333"
local gray = "#94928F"
local font = "Terminus 8"

local theme = {}

theme.wibar_height = "20"
theme.wibar_position = "top"
theme.space = " "

theme.widget_padding_top = 2
theme.widget_padding_bottom = theme.widget_padding_top
theme.widget_padding_left = theme.widget_padding_top
theme.widget_padding_right = theme.widget_padding_left

theme.zenburn_dir = require("awful.util").get_themes_dir() .. "zenburn"
theme.dir = os.getenv("HOME") .. "/.config/awesome/themes/lynxburn2"
theme.wallpaper = os.getenv("HOME") .. "/.wallpaper"
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = false

theme.font = font
theme.fg_normal = white
theme.fg_focus = orange
theme.fg_urgent = red
theme.bg_normal = gray2
theme.bg_focus = theme.bg_normal
theme.bg_urgent = gray1
theme.bg_occupied = theme.bg_normal
theme.bg_empty = theme.bg_normal
theme.border_normal = black
theme.border_focus = gray
theme.border_marked = gray
theme.tasklist_bg_normal = gray2
theme.tasklist_bg_focus = gray1
theme.tasklist_fg_normal = gray
theme.tasklist_fg_focus = orange
theme.taglist_bg_normal = gray2
theme.taglist_bg_focus = gray1
theme.taglist_fg_normal = gray
theme.taglist_fg_focus = orange

theme.taglist_squares_sel = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel = theme.dir .. "/icons/square_unsel.png"
theme.menu_height = dpi(16)
theme.menu_width = dpi(140)
theme.awesome_icon = theme.dir .. "/icons/awesome.png"
theme.menu_submenu_icon = theme.dir .. "/icons/submenu.png"

theme.titlebar_close_button_normal = theme.zenburn_dir .. "/titlebar/close_normal.png"
theme.titlebar_close_button_focus = theme.zenburn_dir .. "/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal = theme.zenburn_dir .. "/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus = theme.zenburn_dir .. "/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive = theme.zenburn_dir .. "/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive = theme.zenburn_dir .. "/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = theme.zenburn_dir .. "/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active = theme.zenburn_dir .. "/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive = theme.zenburn_dir .. "/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive = theme.zenburn_dir .. "/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = theme.zenburn_dir .. "/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active = theme.zenburn_dir .. "/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive = theme.zenburn_dir .. "/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive = theme.zenburn_dir .. "/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = theme.zenburn_dir .. "/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active = theme.zenburn_dir .. "/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = theme.zenburn_dir .. "/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive = theme.zenburn_dir .. "/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = theme.zenburn_dir .. "/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active = theme.zenburn_dir .. "/titlebar/maximized_focus_active.png"

theme.icon_clock = theme.dir .. "/icons/clock.png"
theme.icon_date = theme.dir .. "/icons/cal.png"
theme.icon_mail = theme.dir .. "/icons/mail.png"
theme.icon_cpu = theme.dir .. "/icons/cpu.png"
theme.icon_sysload = theme.dir .. "/icons/cpu.png"
theme.icon_mem = theme.dir .. "/icons/mem.png"
theme.icon_fs = theme.dir .. "/icons/hdd.png"
theme.icon_volume = theme.dir .. "/icons/vol.png"
theme.icon_coretemp = theme.dir .. "/icons/temp.png"
theme.icon_battery = theme.dir .. "/icons/battery.png"
theme.icon_powermenu = theme.dir .. "/icons/cpu.png"

theme.icon_playerctl_prev = theme.dir .. "/icons/prev.png"
theme.icon_playerctl_play = theme.dir .. "/icons/play.png"
theme.icon_playerctl_pause = theme.dir .. "/icons/pause.png"
theme.icon_playerctl_next = theme.dir .. "/icons/next.png"

theme.vol = theme.dir .. "/icons/vol.png"
theme.vol_low = theme.dir .. "/icons/vol_low.png"
theme.vol_no = theme.dir .. "/icons/vol_no.png"
theme.vol_mute = theme.dir .. "/icons/vol_mute.png"

theme.border_width = 1
theme.menu_height = 20
theme.menu_width = 140
theme.useless_gap = 5

theme.notification_icon_size = 50
theme.notification_bg = black
theme.notification_border_width = 1
theme.notification_border_color = gray
theme.notification_max_width = 500

theme.layout_txt_fairv = "vertical"
theme.layout_txt_fairh = "horizontal"
theme.layout_txt_centerwork = "centered"
theme.layout_txt_floating = "floating"
theme.layout_txt_tile = "tiling"
theme.layout_txt_tileleft = "tiling left"
theme.layout_txt_tilebottom = "tiling bottom"
theme.layout_txt_tiletop = "tiling top"
theme.layout_txt_spiral = "spiral"
theme.layout_txt_dwindle = "dwindle"
theme.layout_txt_max = "max"
theme.layout_txt_fullscreen = "fullscreen"
theme.layout_txt_magnifier = "magnifier"
theme.layout_txt_termfair = "termfair"
theme.layout_txt_centerfair = "centerfair"
theme.layout_txt_centerworkh = "centerh"

theme.layout_fairv = theme.dir .. "/icons/fairv.png"
theme.layout_centerwork = theme.dir .. "/icons/centerwork.png"
theme.layout_floating = theme.dir .. "/icons/floating.png"
theme.layout_tile = theme.dir .. "/tile.png"
theme.layout_tileleft = theme.dir .. "/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/tilebottom.png"
theme.layout_tiletop = theme.dir .. "/tiletop.png"
theme.layout_spiral = theme.dir .. "/spiral.png"
theme.layout_dwindle = theme.dir .. "/dwindle.png"
theme.layout_max = theme.dir .. "/max.png"
theme.layout_fullscreen = theme.dir .. "/fullscreen.png"
theme.layout_magnifier = theme.dir .. "/magnifier.png"

theme.lxaudio_bg_hover = "#444444"
theme.lxaudio_button_bg = gray2
theme.lxaudio_button_hover = "#666666"
theme.lxaudio_popup_width_media = 420
theme.lxaudio_popup_width_devices = 420
theme.lxaudio_hover_close_timeout = 2
theme.lxaudio_hover_close_poll_interval = 0.25
theme.lxaudio_artwork_max_size = 320
theme.lxaudio_artwork_width_ratio = 0.33
theme.lxaudio_icon_volume = ""
theme.lxaudio_icon_muted = ""
theme.lxaudio_icon_brightness = "󰃠"
theme.lxaudio_icon_suspended = ""
theme.lxaudio_icon_resumed = ""
theme.lxaudio_icon_mic_active = "🎙"
theme.lxaudio_bar_bg = gray1
theme.lxaudio_bar_fg = white

theme.lxnotify_icon_suspended = "󰂛  "
theme.lxnotify_icon_notifications = "󰂚  "
theme.lxnotify_icon_idle = "󰂚 "
theme.lxnotify_widget_font = "Terminus 7"
theme.lxnotify_widget_fg = "#e8d7b6"
theme.lxnotify_widget_suspended_fg = "#9b8f86"
theme.lxnotify_popup_bg = gray2
theme.lxnotify_notification_card_bg = "#444444"
theme.lxnotify_notification_meta_fg = "#b9aea3"
theme.lxnotify_bg_hover = "#666666"
theme.lxnotify_button_bg = "#444444"
theme.lxnotify_button_hover = "#666666"
theme.lxnotify_popup_width = 360
theme.lxnotify_popup_edge = "right"
theme.lxnotify_notification_icon_size = 32
theme.lxnotify_group_icon_size = 20
theme.lxnotify_urgency_low_fg = "#7aa2c9"
theme.lxnotify_urgency_normal_fg = "#c0b18b"
theme.lxnotify_urgency_critical_fg = "#d97777"

theme.lxdisplay_icon = "󰃟 "
theme.lxdisplay_icon_night = "󰖔 "
theme.lxdisplay_show_bar = false
theme.lxdisplay_icon_font = font
theme.lxdisplay_widget_fg = white
theme.lxdisplay_widget_suspended_fg = "#8b8177"
theme.lxdisplay_bar_width = 36
theme.lxdisplay_bar_height = 8
theme.lxdisplay_bar_spacing = 8
theme.lxdisplay_bar_bg = theme.lxaudio_bar_bg
theme.lxdisplay_bar_fg = theme.lxaudio_bar_fg
theme.lxdisplay_osd_bar_bg = theme.lxaudio_bar_bg
theme.lxdisplay_osd_bar_fg = theme.lxaudio_bar_fg
theme.lxdisplay_osd_width = 260
theme.lxdisplay_osd_height = 18
theme.lxdisplay_osd_margin = 16
theme.lxdisplay_osd_timeout = 1
theme.lxdisplay_osd_screen_margin = 60

theme.lxbluetooth_icon = ""
theme.lxnetwork_icon = ""
theme.lxpowerprofiles_icon_ac = ""
theme.lxpowerprofiles_icon_battery = ""
theme.lxpowerprofiles_profile_fg_powersave = "#9b8f86"
theme.lxpowerprofiles_profile_fg_balanced = white
theme.lxpowerprofiles_profile_fg_performance = "#d97777"

theme.lxrunner_width = 520
theme.lxrunner_row_count = 10
theme.lxrunner_history_limit = 10
theme.lxrunner_bg = gray2
theme.lxrunner_border_color = gray
theme.lxrunner_border_width = 1
theme.lxrunner_radius = 6
theme.lxrunner_outer_margin = 10
theme.lxrunner_padding = 12
theme.lxrunner_input_bg = gray0
theme.lxrunner_input_fg = white
theme.lxrunner_prompt_fg = orange
theme.lxrunner_row_bg = gray2
theme.lxrunner_row_fg = "#b9aea3"
theme.lxrunner_row_selected_bg = "#444444"
theme.lxrunner_row_selected_fg = white
theme.lxrunner_row_padding = 10
theme.lxrunner_cursor = "_"

local theme_overrides = helpers.load_optional_module("config.override.theme", {})
local custom_at_screen_connect = theme_overrides.at_screen_connect

theme_overrides.at_screen_connect = nil
helpers.deep_merge(theme, theme_overrides)

-- Wire the per-screen builder from the sibling widgets module. The actual
-- service/widget lookup happens inside that builder so theme values are already
-- available on `beautiful`.
theme.at_screen_connect = require("themes.lynxburn2.widgets").build(theme)

if custom_at_screen_connect then
    theme.at_screen_connect = custom_at_screen_connect
end

return theme
