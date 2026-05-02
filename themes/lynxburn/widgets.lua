local os = os
local ipairs = ipairs
local table = table

local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local lxmodules = require("config.lxmodules")
local services = require("config.services")
local tags = require("config.tags")
local layouts = require("config.layouts")
local metric = require("widgets.lain_metric")
local calendar = require("widgets.calendar")
local markup = require("widgets.markup")

local my_table = awful.util.table or gears.table

local M = {}

---Wrap a widget in the standard LynxBurn wibar background and padding shell.
local function wallpaper_exists(path)
    if type(path) ~= "string" or path == "" then
        return false
    end

    local handle = io.open(path, "rb")
    if handle then
        handle:close()
        return true
    end

    return false
end

local function fallback_wallpaper_color(theme)
    return theme.bg_normal or beautiful.bg_normal or "#333333"
end

local function notify_wallpaper_fallback(theme, configured)
    if beautiful._lynxburn_wallpaper_fallback_notified then
        return
    end

    beautiful._lynxburn_wallpaper_fallback_notified = true
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Wallpaper not found",
        text = string.format(
            "Configured wallpaper: %s\nFalling back to flat color %s.",
            tostring(configured or "<nil>"),
            fallback_wallpaper_color(theme)
        ),
    })
end

local function apply_wallpaper(theme, screen_obj)
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(screen_obj)
    end

    if not wallpaper_exists(wallpaper) then
        notify_wallpaper_fallback(theme, wallpaper)
        gears.wallpaper.set(fallback_wallpaper_color(theme))
        return
    end

    local ok = pcall(gears.wallpaper.maximized, wallpaper, screen_obj, true)
    if not ok then
        notify_wallpaper_fallback(theme, wallpaper)
        gears.wallpaper.set(fallback_wallpaper_color(theme))
    end
end

local function wrap_widget(theme, widget, background, opts)
    opts = opts or {}

    return wibox.widget({
        {
            widget,
            left = opts.left ~= nil and opts.left or theme.widget_padding_left,
            top = opts.top ~= nil and opts.top or theme.widget_padding_top,
            bottom = opts.bottom ~= nil and opts.bottom or theme.widget_padding_bottom,
            right = opts.right ~= nil and opts.right or theme.widget_padding_right,
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

local function build_power_menu(theme)
    local powermenu_icon = metric.icon(theme.icon_powermenu)
    metric.show(powermenu_icon)

    local powermenu_widget = wibox.widget({
        {
            powermenu_icon,
            layout = wibox.layout.fixed.horizontal,
        },
        margins = 4,
        widget = wibox.container.margin,
    })

    local menu_items = {
        { name = "Run Program", icon = { glyph = "", font = theme.font, width = 12 }, type = "shell", command = "gmrun" },
        { name = "Shutdown", icon = { glyph = "⏻", font = theme.font, width = 12 }, type = "shell", command = "sudo systemctl poweroff" },
        { name = "Reboot", icon = { glyph = "", font = theme.font, width = 12 }, type = "shell", command = "sudo systemctl reboot" },
        { name = "Lock Screen", icon = { glyph = "", font = theme.font, width = 12 }, type = "shell", command = "i3lock -c 000000 -e -t -i ~/.wallpaper" },
        { name = "Log Out", icon = { glyph = "󰍃", font = theme.font, width = 12 }, type = "builtin", command = "quit" },
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
        local item_icon = metric.icon(item.icon)
        metric.show(item_icon)

        local row = wibox.widget({
            {
                {
                    {
                        item_icon,
                        layout = wibox.layout.fixed.horizontal,
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
        awful.button({}, 1, function() layouts.cycle_selected_tag(1) end),
        awful.button({}, 2, function() layouts.reset_selected_tag_layout() end),
        awful.button({}, 3, function() layouts.cycle_selected_tag(-1) end),
        awful.button({}, 4, function() layouts.cycle_selected_tag(1) end),
        awful.button({}, 5, function() layouts.cycle_selected_tag(-1) end)
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

    calendar.attach({ myclock, mydate }, {
        followtag = true,
        week_number = "left",
        notification_preset = {
            font = theme.font,
            fg = theme.fg_normal,
            bg = theme.bg_normal,
        },
    })

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
        local right_widgets = {
            layout = wibox.layout.fixed.horizontal,
        }

        if lxmodules.screen_enabled(s) then
            local lxbar = services.bar()
            table.insert(right_widgets, wrap_widget(theme, lxbar.widget))
        end

        apply_wallpaper(theme, s)

        tags.create_for_screen(s)

        beautiful.bg_systray = theme.tasklist_bg_focus
        beautiful.systray_icon_spacing = theme.widget_padding_left

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
        (function()
                table.insert(right_widgets, myclock)
                table.insert(right_widgets, mydate)
                table.insert(right_widgets, powermenu_widget)
                return right_widgets
            end)(),
        })
    end
end

return M
