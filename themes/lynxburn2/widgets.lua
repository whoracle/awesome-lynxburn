local os = os
local ipairs = ipairs
local table = table

local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local services = require("config.services")

local my_table = awful.util.table or gears.table
local markup = lain.util.markup

local M = {}

---Wrap a widget in the standard LynxBurn wibar background and padding shell.
local mail_account = "anthrax@lynxcore.org"
local mail_password_lookup =
    "secret-tool lookup service awesomewm-imap account " .. mail_account

local function wrap_widget(theme, widget, background)
    return wibox.widget({
        {
            widget,
            left = theme.widget_padding_left,
            top = theme.widget_padding_top,
            bottom = theme.widget_padding_bottom,
            right = theme.widget_padding_right,
            color = theme.tasklist_bg_normal,
            draw_empty = false,
            widget = wibox.container.margin,
        },
        bg = background or theme.tasklist_bg_focus,
        shape = gears.shape.rectangle,
        shape_clip = true,
        widget = wibox.container.background,
    })
end

local function build_text_widget(theme, text_widget)
    text_widget.font = theme.font
    return wrap_widget(theme, text_widget)
end

local function make_metric_icon(icon_path)
    local icon = wibox.widget.imagebox(icon_path)
    icon.forced_width = 0
    icon.forced_height = 0

    return icon
end

local function build_metric_widget(theme, icon, widget)
    local container = wibox.widget({
        {
            icon,
            widget,
            layout = wibox.layout.fixed.horizontal,
        },
        draw_empty = false,
        widget = wibox.container.margin,
    })

    return wrap_widget(theme, container)
end

local function build_power_menu(theme)
    local powermenu_widget = wibox.widget({
        {
            image = theme.icon_powermenu,
            resize = true,
            widget = wibox.widget.imagebox,
        },
        margins = 4,
        widget = wibox.container.margin,
    })

    local menu_items = {
        { name = "Run Program", icon_name = "/icons/cpu.png", type = "shell", command = "gmrun" },
        { name = "Shutdown", icon_name = "/icons/cpu.png", type = "shell", command = "sudo systemctl poweroff" },
        { name = "Reboot", icon_name = "/icons/cpu.png", type = "shell", command = "sudo systemctl reboot" },
        { name = "Lock Screen", icon_name = "/icons/cpu.png", type = "shell", command = "i3lock -c 000000 -e -t -i ~/.wallpaper" },
        { name = "Log Out", icon_name = "/icons/cpu.png", type = "builtin", command = "quit" },
    }

    local popup = awful.popup({
        ontop = true,
        visible = false,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        border_width = 1,
        border_color = theme.border_focus,
        maximum_width = 400,
        offset = { y = 5 },
        widget = {},
    })

    popup:connect_signal("mouse::leave", function()
        popup.visible = false
    end)

    local rows = { layout = wibox.layout.fixed.vertical }

    for _, item in ipairs(menu_items) do
        local row = wibox.widget({
            {
                {
                    {
                        image = theme.dir .. item.icon_name,
                        forced_width = 12,
                        forced_height = 12,
                        widget = wibox.widget.imagebox,
                    },
                    {
                        text = item.name,
                        widget = wibox.widget.textbox,
                    },
                    spacing = 5,
                    layout = wibox.layout.fixed.horizontal,
                },
                margins = 5,
                widget = wibox.container.margin,
            },
            bg = "#000000",
            widget = wibox.container.background,
        })

        row:connect_signal("mouse::enter", function(c)
            c:set_bg(theme.bg_focus)
        end)

        row:connect_signal("mouse::leave", function(c)
            c:set_bg("#000000")
        end)

        row:buttons(my_table.join(
            awful.button({}, 1, function()
                popup.visible = false

                if item.type == "shell" then
                    awful.spawn.with_shell(item.command)
                elseif item.command == "reload" then
                    awesome.reload()
                elseif item.command == "restart" then
                    awesome.restart()
                elseif item.command == "quit" then
                    awesome.quit()
                end
            end)
        ))

        table.insert(rows, row)
    end

    popup:setup(rows)

    powermenu_widget:buttons(my_table.join(
        awful.button({}, 1, function()
            if popup.visible then
                popup.visible = false
            else
                popup:move_next_to(mouse.current_widget_geometry)
                popup.visible = true
            end
        end)
    ))

    return powermenu_widget
end

local function build_layout_switcher(theme, s)
    local layoutbox = wibox.widget.textbox()

    local function update()
        local layout_name = awful.layout.getname(awful.layout.get(s))
        local text = theme["layout_txt_" .. layout_name] or layout_name or ""
        layoutbox:set_text(" " .. text .. " ")
    end

    update()
    awful.tag.attached_connect_signal(s, "property::selected", update)
    awful.tag.attached_connect_signal(s, "property::layout", update)

    layoutbox:buttons(my_table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 2, function() awful.layout.set(awful.layout.layouts[1]) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(1) end),
        awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))

    return wrap_widget(theme, layoutbox)
end

---Build the full per-screen widget and wibar setup for the LynxBurn theme.
---
---Theme values come from `theme.lua`, while shared module instances are fetched
---from `config.services` inside the returned screen callback so they are
---initialized after `beautiful.init(...)`.
---@param theme table
---@return fun(s: table)
function M.build(theme)
    local mytextclock = wibox.widget.textclock(markup(theme.tasklist_fg_normal, " %H:%M "))
    local myclock = build_text_widget(theme, mytextclock)

    local mytextdate = wibox.widget.textclock(markup(theme.tasklist_fg_normal, " %a, %d %b %y "))
    local mydate = build_text_widget(theme, mytextdate)

    lain.widget.cal({
        attach_to = { myclock, mydate },
        followtag = true,
        week_number = "left",
        notification_preset = {
            font = theme.font,
            fg = theme.fg_normal,
            bg = theme.bg_normal,
        },
    })

    local mail_icon = wibox.widget.imagebox(theme.icon_mail)
    mail_icon.forced_width = 0
    mail_icon.forced_height = 0
    local mail = lain.widget.imap({
        timeout = 60,
        server = "lynxcore.org",
        mail = mail_account,
        password = mail_password_lookup,
        settings = function()
            local count = ""

            if mailcount > 0 then
                count = markup.font(theme.font, theme.space .. mailcount .. theme.space)
                mail_icon.forced_width = nil
                mail_icon.forced_height = nil
            else
                mail_icon.forced_width = 0
                mail_icon.forced_height = 0
            end

            widget:set_markup(count)
        end,
    })
    local mailwidget = wrap_widget(theme, wibox.widget({
        {
            mail_icon,
            mail.widget,
            layout = wibox.layout.fixed.horizontal,
        },
        draw_empty = false,
        widget = wibox.container.margin,
    }))

    local cpu_icon = make_metric_icon(theme.icon_cpu)
    local cpu = lain.widget.cpu({
        settings = function()
            local cpu_p = ""

            if cpu_now.usage >= 75 then
                cpu_p = theme.space .. cpu_now.usage .. markup(theme.tasklist_fg_normal, "%" .. theme.space)
                cpu_icon.forced_width = nil
                cpu_icon.forced_height = nil
            else
                cpu_icon.forced_width = 0
                cpu_icon.forced_height = 0
            end

            widget:set_markup(cpu_p)
        end,
    })
    local cpuwidget = build_metric_widget(theme, cpu_icon, cpu.widget)

    local sysload_icon = make_metric_icon(theme.icon_sysload)
    local sysload = lain.widget.sysload({
        settings = function()
            local load_p = ""

            if tonumber(load_1) >= 8 then
                load_p = markup.font(theme.font, theme.space .. load_1 .. theme.space)
                sysload_icon.forced_width = nil
                sysload_icon.forced_height = nil
            else
                sysload_icon.forced_width = 0
                sysload_icon.forced_height = 0
            end

            widget:set_markup(load_p)
        end,
    })
    local sysloadwidget = build_metric_widget(theme, sysload_icon, sysload.widget)

    local mem_icon = make_metric_icon(theme.icon_mem)
    local mem = lain.widget.mem({
        settings = function()
            local mem_p = ""

            if mem_now.perc >= 75 then
                mem_p = markup.font(theme.font, theme.space .. mem_now.perc .. markup(theme.tasklist_fg_normal, "%" .. theme.space))
                mem_icon.forced_width = nil
                mem_icon.forced_height = nil
            else
                mem_icon.forced_width = 0
                mem_icon.forced_height = 0
            end

            widget:set_markup(mem_p)
        end,
    })
    local memwidget = build_metric_widget(theme, mem_icon, mem.widget)

    local fs_root_icon = make_metric_icon(theme.icon_fs)
    local fs_root = lain.widget.fs({
        partition = "/",
        threshold = 95,
        followtag = true,
        settings = function()
            local fs_p = ""

            if fs_now["/"].percentage >= 90 then
                fs_p = markup.font(
                    theme.font,
                    theme.space .. markup(theme.tasklist_fg_normal, "root ")
                    .. fs_now["/"].percentage .. markup(theme.tasklist_fg_normal, "%" .. theme.space)
                )
                fs_root_icon.forced_width = nil
                fs_root_icon.forced_height = nil
            else
                fs_root_icon.forced_width = 0
                fs_root_icon.forced_height = 0
            end

            widget:set_markup(fs_p)
        end,
    })
    local fs_rootwidget = build_metric_widget(theme, fs_root_icon, fs_root.widget)

    local powermenu_widget = build_power_menu(theme)

    local spacer = wibox.widget({
        {
            wibox.widget.textbox(theme.space .. theme.space),
            left = theme.widget_padding_left,
            top = theme.widget_padding_top,
            bottom = theme.widget_padding_bottom,
            right = theme.widget_padding_right,
            widget = wibox.container.margin,
        },
        bg = theme.tasklist_bg_normal,
        shape = gears.shape.rectangle,
        shape_clip = true,
        widget = wibox.container.background,
    })

    return function(s)
        local lxaudio = services.audio()
        local lxdisplay = services.display()
        local lxnotify = services.notify()

        local wallpaper = theme.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)

        awful.tag(awful.util.tagnames, s, awful.layout.layouts)

        beautiful.bg_systray = theme.tasklist_bg_focus
        beautiful.systray_icon_spacing = theme.widget_padding_left

        local mysystray = wibox.widget({
            {
                wibox.widget.systray(),
                left = theme.widget_padding_left,
                top = theme.widget_padding_top,
                bottom = theme.widget_padding_bottom,
                right = theme.widget_padding_right,
                widget = wibox.container.margin,
            },
            bg = theme.tasklist_bg_normal,
            shape = gears.shape.rectangle,
            shape_clip = true,
            widget = wibox.container.background,
        })

        s.mytaglist = awful.widget.taglist(
            s,
            awful.widget.taglist.filter.all,
            awful.util.taglist_buttons,
            {
                bg_normal = theme.taglist_bg_focus,
                bg_focus = theme.taglist_bg_focus,
                bg_occupied = theme.taglist_bg_focus,
                bg_empty = theme.taglist_bg_focus,
                fg_normal = theme.taglist_fg_normal,
                fg_focus = theme.taglist_fg_focus,
                shape = gears.shape.rectangle,
                shape_border_width = theme.widget_padding_top,
                shape_border_color = theme.tasklist_bg_focus,
                align = "center",
            }
        )

        s.mytags = wrap_widget(theme, s.mytaglist)
        s.mylayoutswitcher = build_layout_switcher(theme, s)

        s.mytasklist = awful.widget.tasklist(
            s,
            awful.widget.tasklist.filter.currenttags,
            awful.util.tasklist_buttons,
            {
                bg_normal = theme.tasklist_bg_focus,
                bg_focus = theme.tasklist_bg_focus,
                fg_normal = theme.tasklist_fg_normal,
                fg_focus = theme.tasklist_fg_focus,
                shape = gears.shape.rectangle,
                shape_border_width = theme.widget_padding_top,
                shape_border_color = theme.tasklist_bg_normal,
                align = "center",
            }
        )

        s.mywibox = awful.wibar({
            position = theme.wibar_position,
            screen = s,
            height = theme.wibar_height,
            bg = theme.tasklist_bg_normal,
        })

        s.mywibox:setup({
            layout = wibox.layout.align.horizontal,
            {
                layout = wibox.layout.fixed.horizontal,
                s.mytags,
                s.mylayoutswitcher,
                spacer,
            },
            s.mytasklist,
            {
                layout = wibox.layout.fixed.horizontal,
                mailwidget,
                sysloadwidget,
                cpuwidget,
                memwidget,
                fs_rootwidget,
                spacer,
                lxaudio.widget,
                lxdisplay.widget,
                lxnotify.widget,
                mysystray,
                myclock,
                mydate,
                powermenu_widget,
            },
        })
    end
end

return M
