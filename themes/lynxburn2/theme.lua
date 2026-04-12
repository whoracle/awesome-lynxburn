-- LynxBurn AwesomeWM theme
-- Based on Steamburn by Awesome-Copycats
-- v1.0

--
-- imports and defines
--

-- modules
local gears     = require("gears")
local lain      = require("lain")
local awful     = require("awful")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local dpi       = require("beautiful.xresources").apply_dpi

-- misc
local os       = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility
local markup   = lain.util.markup

-- colors
local orange   = "#d88166"
local red      = "#123456"
local white    = "#e2ccb0"
local black    = "#000000"
local gray0    = "#111111"
local gray1    = "#140c0b"
local gray2    = "#333333"
local gray     = "#94928F"

-- font
--local font     = "Misc Tamsyn 8"
--local font       = "Terminus 10.5"
local font       = "Terminus 8"


--
-- define our theme
--
local theme                                     = {}

-- wibar
theme.wibar_height   = "20"
theme.wibar_position = "top"

theme.space = " "

theme.widget_padding_top    = 2
theme.widget_padding_bottom = theme.widget_padding_top
theme.widget_padding_left   = theme.widget_padding_top
theme.widget_padding_right  = theme.widget_padding_left

-- envvars
theme.zenburn_dir                               = require("awful.util").get_themes_dir() .. "zenburn"
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/lynxburn2"
theme.wallpaper                                 = os.getenv("HOME") .. "/.wallpaper"
theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = false

-- font and colors
theme.font                                      = font
theme.fg_normal                                 = white
theme.fg_focus                                  = orange
theme.fg_urgent                                 = red
theme.bg_normal                                 = gray2
--theme.bg_focus                                  = gray0
theme.bg_focus                                  = theme.bg_normal
theme.bg_urgent                                 = gray1
theme.bg_occupied                               = theme.bg_normal
theme.bg_empty                                  = theme.bg_normal
theme.border_normal                             = black
theme.border_focus                              = gray
theme.border_marked                             = gray
theme.tasklist_bg_normal                        = gray2
theme.tasklist_bg_focus                         = gray1
theme.tasklist_fg_normal                        = gray
theme.tasklist_fg_focus                         = orange
theme.taglist_bg_normal                         = gray2
theme.taglist_bg_focus                          = gray1
theme.taglist_fg_normal                         = gray
theme.taglist_fg_focus                          = orange

-- icons for workspacelist and menus
theme.taglist_squares_sel                       = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel                     = theme.dir .. "/icons/square_unsel.png"
theme.menu_height                               = dpi(16)
theme.menu_width                                = dpi(140)
theme.awesome_icon                              = theme.dir .."/icons/awesome.png"
theme.menu_submenu_icon                         = theme.dir .. "/icons/submenu.png"

-- icons for client window titlebars
theme.titlebar_close_button_normal              = theme.zenburn_dir.."/titlebar/close_normal.png"
theme.titlebar_close_button_focus               = theme.zenburn_dir.."/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal           = theme.zenburn_dir.."/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus            = theme.zenburn_dir.."/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive     = theme.zenburn_dir.."/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive      = theme.zenburn_dir.."/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active       = theme.zenburn_dir.."/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active        = theme.zenburn_dir.."/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive    = theme.zenburn_dir.."/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive     = theme.zenburn_dir.."/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active      = theme.zenburn_dir.."/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active       = theme.zenburn_dir.."/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive  = theme.zenburn_dir.."/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   = theme.zenburn_dir.."/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    = theme.zenburn_dir.."/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     = theme.zenburn_dir.."/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = theme.zenburn_dir.."/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = theme.zenburn_dir.."/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = theme.zenburn_dir.."/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = theme.zenburn_dir.."/titlebar/maximized_focus_active.png"

-- widget icons
theme.icon_clock                                = theme.dir .. "/icons/clock.png"
theme.icon_date                                 = theme.dir .. "/icons/cal.png"
theme.icon_mail                                 = theme.dir .. "/icons/mail.png"
theme.icon_cpu                                  = theme.dir .. "/icons/cpu.png"
theme.icon_sysload                              = theme.dir .. "/icons/cpu.png"
theme.icon_mem                                  = theme.dir .. "/icons/mem.png"
theme.icon_fs                                   = theme.dir .. "/icons/hdd.png"
theme.icon_volume                               = theme.dir .. "/icons/vol.png"
theme.icon_coretemp                             = theme.dir .. "/icons/temp.png"
theme.icon_battery                              = theme.dir .. "/icons/battery.png"
theme.icon_powermenu                              = theme.dir .. "/icons/cpu.png"

-- playback controls
theme.icon_playerctl_prev                       = theme.dir .. "/icons/prev.png"
theme.icon_playerctl_play                       = theme.dir .. "/icons/play.png"
theme.icon_playerctl_pause                      = theme.dir .. "/icons/pause.png"
theme.icon_playerctl_next                       = theme.dir .. "/icons/next.png"

-- volume
theme.vol                                       = theme.dir .. "/icons/vol.png"
theme.vol_low                                   = theme.dir .. "/icons/vol_low.png"
theme.vol_no                                    = theme.dir .. "/icons/vol_no.png"
theme.vol_mute                                  = theme.dir .. "/icons/vol_mute.png"

-- basic geometry 
theme.border_width                              = 1
theme.menu_height                               = 20
theme.menu_width                                = 140
theme.useless_gap                               = 5

-- geometry of notifications
theme.notification_icon_size                    = 50
theme.notification_bg                           = black
theme.notification_border_width                 = 1
theme.notification_border_color                 = gray
--theme.notification_height                       = 50
--theme.notification_width                        = 250
theme.notification_max_width                    = 500
--theme.notification_max_height                   = 50

--
-- names for tiling modes
--

-- the ones we use
theme.layout_txt_fairv                          = "vertical"
theme.layout_txt_fairh                          = "horizontal"
theme.layout_txt_centerwork                     = "centered"

-- unused tiling modes. need to be here anyways.
theme.layout_txt_floating                       = "floating"
theme.layout_txt_tile                           = "tiling"
theme.layout_txt_tileleft                       = "tiling left"
theme.layout_txt_tilebottom                     = "tiling bottom"
theme.layout_txt_tiletop                        = "tiling top"
theme.layout_txt_spiral                         = "spiral"
theme.layout_txt_dwindle                        = "dwindle"
theme.layout_txt_max                            = "max"
theme.layout_txt_fullscreen                     = "fullscreen"
theme.layout_txt_magnifier                      = "magnifier"

-- lain extra tiling modes. also unused
theme.layout_txt_termfair                       = "termfair"
theme.layout_txt_centerfair                     = "centerfair"
theme.layout_txt_centerworkh                    = "centerh"

-- icons for tiling modes
theme.layout_fairv                              = theme.dir .. "/icons/fairv.png"
theme.layout_centerwork                         = theme.dir .. "/icons/centerwork.png"
theme.layout_floating                           = theme.dir .. "/icons/floating.png"

-- unused tiling modes. need to be here anyways.
theme.layout_tile                               = theme.dir .. "/tile.png"
theme.layout_tileleft                           = theme.dir .. "/tileleft.png"
theme.layout_tilebottom                         = theme.dir .. "/tilebottom.png"
theme.layout_tiletop                            = theme.dir .. "/tiletop.png"
theme.layout_spiral                             = theme.dir .. "/spiral.png"
theme.layout_dwindle                            = theme.dir .. "/dwindle.png"
theme.layout_max                                = theme.dir .. "/max.png"
theme.layout_fullscreen                         = theme.dir .. "/fullscreen.png"
theme.layout_magnifier                          = theme.dir .. "/magnifier.png"

-- lxaudio
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
theme.lxaudio_bar_fg = orange

-- lxnotify
theme.lxnotify_icon_suspended = "󰂛  "
theme.lxnotify_icon_notifications = "󰂚  "
theme.lxnotify_icon_idle = "󰂚 "

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

--
-- widgets
--

-- textclock
local mytextclock = wibox.widget.textclock(markup(gray," %H:%M "))
mytextclock.font  = theme.font
local clock_icon = wibox.widget.imagebox(theme.icon_clock)
local myclock = wibox.widget {
    {
        mytextclock,
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
    },
    widget     = wibox.container.background,
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
}

-- textdate
local mytextdate = wibox.widget.textclock(markup(gray," %a, %d %b %y "))
mytextdate.font  = theme.font
local date_icon = wibox.widget.imagebox(theme.icon_date)
local mydate = wibox.widget {
    {
        mytextdate,
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

-- calendar
lain.widget.cal({
    attach_to = { myclock, mydate },
    followtag = true,
    week_number = "left",
    notification_preset = {
        font = theme.font,
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

local mail_icon = wibox.widget.imagebox(theme.icon_mail)
mail_icon.forced_width = 0
mail_icon.forced_height = 0
local mail = lain.widget.imap({
    timeout  = 60,
    server   = "lynxcore.org",
    mail     = "anthrax@lynxcore.org",
    password = "REDACTED_SECRET",
    is_plain = true,
    settings = function()
        count = ""

        if mailcount > 0 then
            count = markup.font(theme.font, theme.space .. mailcount .. theme.space)
            mail_icon.forced_width = nil
            mail_icon.forced_height = nil
        else
            mail_icon.forced_width = 0
            mail_icon.forced_height = 0
        end

        widget:set_markup(count)
    end
})
local mailwidget = wibox.widget {
    {
        {
            mail_icon,
            mail.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

-- CPU
local cpu_icon = wibox.widget.imagebox(theme.icon_cpu)
cpu_icon.forced_width = 0
cpu_icon.forced_height = 0
local cpu = lain.widget.cpu({
    settings = function()
        cpu_p = ""

        if cpu_now.usage >= 75 then
            cpu_p = theme.space .. cpu_now.usage .. markup(gray, "%" .. theme.space)
            cpu_icon.forced_width = nil
            cpu_icon.forced_height = nil
        else
            cpu_icon.forced_width = 0
            cpu_icon.forced_height = 0
        end

        widget:set_markup(cpu_p)
    end
})
local cpuwidget = wibox.widget {
    {
        {
            cpu_icon,
            cpu.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
    draw_empty = false,
}

-- LOAD
local sysload_icon = wibox.widget.imagebox(theme.icon_sysload)
sysload_icon.forced_width = 0
sysload_icon.forced_height = 0
local sysload = lain.widget.sysload({
    settings = function()
        load_p = ""

        if tonumber(load_1) >= 8 then
            load_p = markup.font(theme.font, theme.space .. load_1 .. theme.space)
            sysload_icon.forced_width = nil
            sysload_icon.forced_height = nil
        else
            sysload_icon.forced_width = 0
            sysload_icon.forced_height = 0
        end

        widget:set_markup(load_p)
    end
})
local sysloadwidget = wibox.widget {
    {
        {
            sysload_icon,
            sysload.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

-- MEM
local mem_icon = wibox.widget.imagebox(theme.icon_mem)
mem_icon.forced_width = 0
mem_icon.forced_height = 0
local mem = lain.widget.mem({
    settings = function()
        mem_p = ""

        if mem_now.perc >= 75 then
            mem_p = markup.font(theme.font, theme.space .. mem_now.perc .. markup(gray, "%" .. theme.space))
            mem_icon.forced_width = nil
            mem_icon.forced_height = nil
        else
            mem_icon.forced_width = 0
            mem_icon.forced_height = 0
        end

        widget:set_markup(mem_p)
    end
})
local memwidget = wibox.widget {
    {
        {
            mem_icon,
            mem.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

-- TEMP
--[[
local coretemp_icon = wibox.widget.imagebox(theme.icon_coretemp)
coretemp_icon.forced_width = 0
coretemp_icon.forced_height = 0
local coretemp = lain.widget.temp({
    settings = function()
        temp_p      = ""

        if tonumber(coretemp_now) >= 80 then
            temp_p      = markup.font(theme.font, theme.space .. math.floor(coretemp_now+0.5) .. markup(gray, "°C" .. theme.space))
            coretemp_icon.forced_width = nil
            coretemp_icon.forced_height = nil
        else
            coretemp_icon.forced_width = 0
            coretemp_icon.forced_height = 0
        end

        widget:set_markup(temp_p)
    end
})
local coretempwidget = wibox.widget {
    {
        {
            coretemp_icon,
            coretemp.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}
]]--

-- FS
local fs_root_icon = wibox.widget.imagebox(theme.icon_fs)
fs_root_icon.forced_width = 0
fs_root_icon.forced_height = 0
local fs_root = lain.widget.fs({
    partition = "/",
    threshold = 95,
    followtag = true,
    settings  = function()
        fs_p = ""

        if fs_now["/"].percentage >= 90 then
            fs_p = markup.font(theme.font, theme.space .. markup(gray, "root ") .. fs_now["/"].percentage .. markup(gray, "%" .. theme.space))
            fs_root_icon.forced_width = nil
            fs_root_icon.forced_height = nil
        else
            fs_root_icon.forced_width = 0
            fs_root_icon.forced_height = 0
        end

        widget:set_markup(fs_p)
    end
})
local fs_rootwidget = wibox.widget {
    {
        {
            fs_root_icon,
            fs_root.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

-- Battery
--[[
local battery_icon = wibox.widget.imagebox(theme.icon_battery)
battery_icon.forced_width = 0
battery_icon.forced_height = 0
local mybattery = lain.widget.bat({
    timeout = 10,
	settings = function()
		local perc = ""

		if bat_now.ac_status ~= 1 then
            perc = markup.font(theme.font, theme.space .. bat_now.perc .. markup(gray, "%" .. theme.space))
            battery_icon.forced_width = nil
            battery_icon.forced_height = nil
        else
            battery_icon.forced_width = 0
            battery_icon.forced_height = 0
        end

		widget:set_markup(perc)
	end
})
local batterywidget = wibox.widget {
    {
        {
            battery_icon,
            mybattery.widget,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left   = theme.widget_padding_left,
        top    = theme.widget_padding_top,
        bottom = theme.widget_padding_bottom,
        right  = theme.widget_padding_right,
        widget = wibox.container.margin,
        color = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}
]]--

-- playerctl control buttons
local prev_icon = wibox.widget.imagebox(theme.icon_playerctl_prev)
prev_icon:buttons(awful.util.table.join(
    awful.button({}, 1, function()
        os.execute(string.format("playerctl previos"))
    end)
))
local play_icon = wibox.widget.imagebox(theme.icon_playerctl_play)
play_icon:buttons(awful.util.table.join(
    awful.button({}, 1, function()
        os.execute(string.format("playerctl play"))
    end)
))
local pause_icon = wibox.widget.imagebox(theme.icon_playerctl_pause)
pause_icon:buttons(awful.util.table.join(
    awful.button({}, 1, function()
        os.execute(string.format("playerctl pause"))
    end)
))
local next_icon = wibox.widget.imagebox(theme.icon_playerctl_next)
next_icon:buttons(awful.util.table.join(
    awful.button({}, 1, function()
        os.execute(string.format("playerctl next"))
    end)
))

-- ALSA volume
--[[
local volume_icon = wibox.widget.imagebox(theme.icon_volume)
local volume = lain.widget.alsa({
    settings = function()
        vlevel = volume_now.level

        if volume_now.status == "off" then
            vlevel = markup(gray, vlevel .. " M" .. theme.space)
        else
            vlevel = vlevel .. markup(gray, theme.space)
        end

        widget:set_markup(markup.font(theme.font, " " .. vlevel))
    end
})
volume.widget:buttons(awful.util.table.join(
    awful.button({}, 2, function() -- right click
        os.execute(string.format("amixer -q -D pulse set Master toggle", volume.device))
        volume.update()
    end),
    awful.button({}, 3, function() -- middle click
        awful.spawn("pavucontrol")
    end),
    awful.button({}, 4, function() -- scroll up
        os.execute(string.format("amixer -q -D pulse set Master 1%%+"))
        volume.update()
    end),
    awful.button({}, 5, function() -- scroll down
        os.execute(string.format("amixer -q -D pulse set Master 1%%-"))
        volume.update()
    end)
))
local volumewidget = wibox.widget {
    {
        {
            volume_icon,
            volume.widget,
            prev_icon,
            play_icon,
            pause_icon,
            next_icon,
            left   = 0,
            top    = 0,
            bottom = 0,
            right  = 0,
            widget = wibox.container.margin,
            layout = wibox.layout.fixed.horizontal,
            draw_empty = false,
        },
        left       = theme.widget_padding_left,
        top        = theme.widget_padding_top,
        bottom     = theme.widget_padding_bottom,
        right      = theme.widget_padding_right,
        widget     = wibox.container.margin,
        color      = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_focus,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}
]]--

-- power menu
local powermenu_widget = wibox.widget {
    {
        image = theme.icon_powermenu,
        resize = true,
        widget = wibox.widget.imagebox,
    },
    margins = 4,
    widget = wibox.container.margin
}

local menu_items = {
    { name = 'Run Program', icon_name = '/icons/cpu.png', type = 'shell', command = 'gmrun' },
    { name = 'Shutdown', icon_name = '/icons/cpu.png', type = 'shell', command = 'sudo systemctl poweroff' },
    { name = 'Reboot', icon_name = '/icons/cpu.png', type = 'shell', command = 'sudo systemctl reboot' },
    { name = 'Lock Screen', icon_name = '/icons/cpu.png', type = 'shell', command = 'i3lock -c 000000 -e -t -i ~/.wallpaper' },
    { name = 'Log Out', icon_name = '/icons/cpu.png', type = 'builtin', command = 'quit' },
    --[[
    { name = 'Restart awesome', icon_name = '/icons/cpu.png', type = 'builtin', command = 'restart' },
    { name = 'Suspend', icon_name = '/icons/cpu.png', type = 'shell', command = 'sudo systemctl suspend' },
    { name = 'Hibernate', icon_name = '/icons/cpu.png', type = 'shell', command = 'sudo systemctl hibernate' },
    { name = 'Reload awesome', icon_name = '/icons/cpu.png', type = 'builtin', command = 'reload' },
    ]]--
}
local popup = awful.popup {
    ontop = true,
    visible = false, -- should be hidden when created
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    border_width = 1,
    border_color = theme.border_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}
popup:connect_signal("mouse::leave", function(c)
    popup.visible = not popup.visible
end)
local rows = { layout = wibox.layout.fixed.vertical }
for _, item in ipairs(menu_items) do

    local row = wibox.widget {
        {
            {
                {
                    image = theme.dir .. item.icon_name,
                    forced_width = 12,
                    forced_height = 12,
                    widget = wibox.widget.imagebox
                },
                {
                    text = item.name,
                    widget = wibox.widget.textbox
                },
                spacing = 5,
                layout = wibox.layout.fixed.horizontal
            },
            margins = 5,
            widget = wibox.container.margin
        },
        bg = black,
        widget = wibox.container.background
    }
    row:connect_signal("mouse::enter", function(c)
        c:set_bg(theme.bg_focus)
    end)
    row:connect_signal("mouse::leave", function(c)
        c:set_bg(black)
    end)
    row:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                popup.visible = not popup.visible
                if item.type == 'shell' then
                    awful.spawn.with_shell(item.command)
                elseif item.type == 'builtin' then
                    if item.command == 'reload' then awesome.reload() end
                    if item.command == 'restart' then awesome.restart() end
                    if item.command == 'quit' then awesome.quit() end
                end
            end)
        )
    )
    table.insert(rows, row)
end
popup:setup(rows)
powermenu_widget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function()
            if popup.visible then
                popup.visible = not popup.visible
            else
                 popup:move_next_to(mouse.current_widget_geometry)
            end
    end))
)

-- spacer
local spacer = wibox.widget {
    {
        wibox.widget.textbox(theme.space .. theme.space),
        left       = theme.widget_padding_left,
        top        = theme.widget_padding_top,
        bottom     = theme.widget_padding_bottom,
        right      = theme.widget_padding_right,
        widget     = wibox.container.margin,
        color      = theme.tasklist_bg_normal,
        draw_empty = false,
    },
    bg         = theme.tasklist_bg_normal,
    shape      = gears.shape.rectangle,
    shape_clip = true,
    widget     = wibox.container.background,
}

--
-- setup widget container
--

-- tiling mode
local function update_txt_layoutbox(s)
    -- Writes a string representation of the current layout in a textbox widget
    local txt_l = " " .. theme["layout_txt_" .. awful.layout.getname(awful.layout.get(s))] .. " " or ""
    s.mytxtlayoutbox:set_text(txt_l)
end

-- build the widget container
function theme.at_screen_connect(s)
    -- wallpaper
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- workspace list
    awful.tag(awful.util.tagnames, s, awful.layout.layouts)

    -- Create a promptbox for each screen
    --s.mypromptbox = awful.widget.prompt()

    -- tiling modes
    s.mytxtlayoutbox = wibox.widget.textbox(theme.space .. theme["layout_txt_" .. awful.layout.getname(awful.layout.get(s))] .. theme.space)
    awful.tag.attached_connect_signal(s, "property::selected", function () update_txt_layoutbox(s) end)
    awful.tag.attached_connect_signal(s, "property::layout", function () update_txt_layoutbox(s) end)
    s.mytxtlayoutbox:buttons(
        my_table.join(
           awful.button({}, 1, function() awful.layout.inc(1) end),
           awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
           awful.button({}, 3, function() awful.layout.inc(-1) end),
           awful.button({}, 4, function() awful.layout.inc(1) end),
           awful.button({}, 5, function() awful.layout.inc(-1) end)
       )
    )

    s.mylayoutswitcher = wibox.widget {
        {
            s.mytxtlayoutbox,
            -- s.mylayoutbox,
            left   = theme.widget_padding_left,
            top    = theme.widget_padding_top,
            bottom = theme.widget_padding_bottom,
            right  = theme.widget_padding_right,
            widget = wibox.container.margin,
            color = theme.tasklist_bg_normal,
            draw_empty = false,
        },
        bg         = theme.tasklist_bg_focus,
        shape      = gears.shape.rectangle,
        shape_clip = true,
        widget     = wibox.container.background,
    }

    -- systray
    beautiful.bg_systray = theme.tasklist_bg_focus
    beautiful.systray_icon_spacing = theme.widget_padding_left
    local mysystray = wibox.widget {
        {
            wibox.widget.systray(),
            left       = theme.widget_padding_left,
            top        = theme.widget_padding_top,
            bottom     = theme.widget_padding_bottom,
            right      = theme.widget_padding_right,
            widget     = wibox.container.margin,
            draw_empty = false,
        },
        bg         = tasklist_bg_normal,
        shape      = gears.shape.rectangle,
        shape_clip = true,
        widget     = wibox.container.background,
    }

    -- clock


    -- Create a workspace list widget
    s.mytaglist = awful.widget.taglist(
        s,
        awful.widget.taglist.filter.all,
        awful.util.taglist_buttons,
        {
            bg_normal          = theme.taglist_bg_focus,
            bg_focus           = theme.taglist_bg_focus,
            bg_occupied        = theme.taglist_bg_focus,
            bg_empty           = theme.taglist_bg_focus,
            fg_normal          = theme.taglist_fg_normal,
            fg_focus           = theme.taglist_fg_focus,
            shape              = gears.shape.rectangle,
            shape_border_width = theme.widget_padding_top,
            shape_border_color = theme.tasklist_bg_focus,
            align              = "center",
        }
    )
    s.mytags = wibox.widget {
        {
            s.mytaglist,
            left   = theme.widget_padding_left,
            top    = theme.widget_padding_top,
            bottom = theme.widget_padding_bottom,
            right  = theme.widget_padding_right,
            widget = wibox.container.margin,
            color = theme.tasklist_bg_normal,
        },
        bg         = theme.tasklist_bg_focus,
        shape      = gears.shape.rectangle,
        shape_clip = true,
        widget     = wibox.container.background,
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(
        s,
        awful.widget.tasklist.filter.currenttags,
        awful.util.tasklist_buttons,
        {
            bg_normal          = theme.tasklist_bg_focus,
            bg_focus           = theme.tasklist_bg_focus,
            fg_normal          = theme.tasklist_fg_normal,
            fg_focus           = theme.tasklist_fg_focus,
            shape              = gears.shape.rectangle,
            shape_border_width = theme.widget_padding_top,
            shape_border_color = theme.tasklist_bg_normal,
            align              = "center",
        }
    )

    -- Create the menubar
    s.mywibox = awful.wibar(
        {
            position = theme.wibar_position,
            screen = s,
            height = theme.wibar_height,
            bg = theme.tasklist_bg_normal,
        }
    )

    -- Add widgets to the menubar
    -- layout: [ left ][ middle ][ right ]
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        -- Left widgets
        {
            layout = wibox.layout.fixed.horizontal,
            s.mytags,
            s.mylayoutswitcher,
            spacer,
        },

        -- Middle widget
        s.mytasklist,

        -- Right widgets
        {
            layout = wibox.layout.fixed.horizontal,
            spacer,
            _G.lxaudio.widget,
            _G.lxnotify.widget,
            mailwidget,
            sysloadwidget,
            cpuwidget,
            memwidget,
            --coretempwidget,
            --batterywidget,
            fs_rootwidget,
            --volumewidget,
            mysystray,
            myclock,
            mydate,
            powermenu_widget,
        },
    }
end

return theme
