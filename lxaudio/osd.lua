local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}

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

local function build_box(state, widget_template, app_name, width, margin)
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

    state.box.width = width + (margin * 2)
    state.box.visible = false

    state.notification:connect_signal("destroyed", function()
        state.notification = nil
        state.box = nil
    end)
end

function M.new(opts)
    local width = opts.osd_width or 260
    local height = opts.osd_height or 18
    local margin = opts.osd_margin or 16
    local timeout = opts.osd_timeout or 1

    local volume_osd = {
        notification = nil,
        box = nil,
        hide_timer = nil,
    }

    local text_osd = {
        notification = nil,
        box = nil,
        hide_timer = nil,
    }

    local osd_icon = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = 32,
        widget = wibox.widget.textbox,
    })

    local volume_bar = wibox.widget({
        max_value = 100,
        value = 0,
        forced_width = width,
        forced_height = height,
        shape = gears.shape.rounded_bar,
        bar_shape = gears.shape.rounded_bar,
        background_color = beautiful.bg_minimize or "#444444",
        color = beautiful.fg_normal or "#ffffff",
        widget = wibox.widget.progressbar,
    })

    local display_text = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = width,
        widget = wibox.widget.textbox,
    })

    local function ensure_volume_osd(app_name)
        if volume_osd.box then
            return
        end

        build_box(volume_osd, {
            {
                {
                    {
                        osd_icon,
                        {
                            volume_bar,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        }, app_name, width, margin)
    end

    local function ensure_text_osd(app_name)
        if text_osd.box then
            return
        end

        build_box(text_osd, {
            {
                {
                    {
                        osd_icon,
                        {
                            display_text,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        }, app_name, width, margin)
    end

    local function arm_hide_timer(osd)
        if osd.hide_timer then
            osd.hide_timer:stop()
        end

        osd.hide_timer = gears.timer.start_new(timeout, function()
            destroy_osd(osd)
            return false
        end)
    end

    return {
        show_volume = function(percent, icon, app_name)
            destroy_osd(text_osd)
            ensure_volume_osd(app_name or "Volume OSD")

            local value = tonumber(percent) or 0
            if value < 0 then value = 0 end
            if value > 100 then value = 100 end

            osd_icon.text = icon or (beautiful.lxaudio_icon_volume or "")
            volume_bar.value = value
            volume_bar.color = beautiful.fg_normal or "#ffffff"

            volume_osd.box.screen = awful.screen.focused()
            volume_osd.box.visible = true
            arm_hide_timer(volume_osd)
        end,
        show_text = function(text, icon, app_name)
            destroy_osd(volume_osd)
            ensure_text_osd(app_name or "Mute Indicator")

            display_text.text = text
            osd_icon.text = icon or (beautiful.lxaudio_icon_muted or "")

            text_osd.box.screen = awful.screen.focused()
            text_osd.box.visible = true
            arm_hide_timer(text_osd)
        end,
    }
end

return M
