local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local beautiful = require("beautiful")

local widget = {}

function widget.new(instance)
    local text_widget = wibox.widget({
        align = "center",
        valign = "center",
        font = beautiful.lxnotify_widget_font or beautiful.font,
        widget = wibox.widget.textbox,
    })

    local container = wibox.widget({
        {
            text_widget,
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    require("lxnotify.util").attach_hover_background(
        container,
        nil,
        beautiful.lxnotify_bg_hover or beautiful.bg_focus or "#444444",
        beautiful.lxnotify_button_hover or beautiful.bg_focus or "#666666"
    )

    container:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:toggle_notification_popup()
        end),
        awful.button({}, 2, function()
            instance:toggle_daemon_pause()
        end),
        awful.button({}, 3, function()
            instance:dismiss_all()
        end)
    ))

    return {
        root = container,
        text = text_widget,
    }
end

return widget
