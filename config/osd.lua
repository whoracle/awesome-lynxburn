local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local M = {}

function M.new(beautiful, _options)
    local osd_width = 260
    local osd_height = 18
    local osd_margin = 16
    local osd_timeout = 1

    local text_osd = {
        notification = nil,
        box = nil,
        hide_timer = nil,
    }

    local brightness_osd = {
        notification = nil,
        box = nil,
        hide_timer = nil,
    }

    local display_text = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = osd_width,
        widget = wibox.widget.textbox,
    })

    local osd_icon = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = 32,
        widget = wibox.widget.textbox,
    })

    local brightness_bar = wibox.widget({
        max_value = 100,
        value = 0,
        forced_width = osd_width,
        forced_height = osd_height,
        shape = gears.shape.rounded_bar,
        bar_shape = gears.shape.rounded_bar,
        background_color = beautiful.bg_minimize or "#444444",
        color = beautiful.fg_normal or "#ffffff",
        widget = wibox.widget.progressbar,
    })

    local function destroy_osd(osd)
        if osd.hide_timer then
            osd.hide_timer:stop()
            osd.hide_timer = nil
        end

        if osd.notification then
            osd.notification:destroy()
            osd.notification = nil
        end

        osd.box = nil
    end

    local function build_box(state, widget_template, app_name)
        state.notification = naughty.notification({
            title = "",
            message = "",
            app_name = app_name,
            timeout = 0,
            position = "bottom_middle",
            ontop = true,
            screen = awful.screen.focused(),
        })

        state.box = naughty.layout.box({
            notification = state.notification,
            position = "bottom_middle",
            screen = awful.screen.focused(),
            widget_template = widget_template,
        })

        state.box.width = osd_width + (osd_margin * 2)
        state.box.visible = false

        state.notification:connect_signal("destroyed", function()
            state.notification = nil
            state.box = nil
        end)
    end

    local function ensure_text_osd(app_name)
        if text_osd.box then
            return
        end

        build_box(text_osd, {
            {
                {
                    {
                        {
                            display_text,
                            widget = wibox.container.place,
                        },
                        widget = wibox.container.place,
                    }
                },
                margins = osd_margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.container.background,
        }, app_name)
    end

    local function ensure_brightness_osd(app_name)
        if brightness_osd.box then
            return
        end

        build_box(brightness_osd, {
            {
                {
                    {
                        osd_icon,
                        {
                            brightness_bar,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = osd_margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        }, app_name)
    end

    local function show_text_osd(text, app_name)
        destroy_osd(brightness_osd)
        ensure_text_osd(app_name or "")

        display_text.text = text
        text_osd.box.screen = awful.screen.focused()
        text_osd.box.visible = true

        if text_osd.hide_timer then
            text_osd.hide_timer:stop()
        end

        text_osd.hide_timer = gears.timer.start_new(osd_timeout, function()
            destroy_osd(text_osd)
            return false
        end)
    end

    local function show_brightness_osd(percent, app_name)
        destroy_osd(text_osd)
        ensure_brightness_osd(app_name or "Brightness OSD")

        local value = tonumber(percent) or 0
        if value < 0 then value = 0 end
        if value > 100 then value = 100 end

        osd_icon.text = beautiful.lxaudio_icon_brightness or "󰃠"
        brightness_bar.value = value
        brightness_bar.color = beautiful.fg_normal or "#ffffff"

        brightness_osd.box.screen = awful.screen.focused()
        brightness_osd.box.visible = true

        if brightness_osd.hide_timer then
            brightness_osd.hide_timer:stop()
        end

        brightness_osd.hide_timer = gears.timer.start_new(osd_timeout, function()
            destroy_osd(brightness_osd)
            return false
        end)
    end

    local function refresh_brightness_osd(command)
        awful.spawn.easy_async_with_shell(command, function(stdout)
            local percent = tonumber(stdout:match("(%d+%.?%d*)")) or 0
            show_brightness_osd(percent, "Brightness OSD")
        end)
    end

    return {
        show_notifications_state = function(suspended)
            if suspended then
                show_text_osd("Notifications suspended", "Notification Indicator")
            else
                show_text_osd("Notifications resumed", "Notification Indicator")
            end
        end,
        brightness_up = function(commands)
            awful.spawn.easy_async_with_shell(commands.up, function()
                refresh_brightness_osd(commands.get)
            end)
        end,
        brightness_down = function(commands)
            awful.spawn.easy_async_with_shell(commands.down, function()
                refresh_brightness_osd(commands.get)
            end)
        end,
        brightness_off = function(commands)
            awful.spawn.easy_async_with_shell(commands.off, function() end)
        end,
    }
end

return M
