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

    local text_slot = wibox.widget({
        {
            text_widget,
            halign = "center",
            valign = "center",
            widget = wibox.container.place,
        },
        forced_width = beautiful.lxnotify_icon_width or 20,
        strategy = "exact",
        widget = wibox.container.constraint,
    })

    local container = wibox.widget({
        {
            text_slot,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    require("lxcommon.util").attach_hover_background(
        container,
        nil,
        beautiful.lxnotify_widget_hover_bg or beautiful.lxnotify_card_hover_bg or beautiful.bg_focus or "#444444",
        beautiful.lxnotify_widget_press_bg or beautiful.lxnotify_button_hover or beautiful.bg_focus or "#666666"
    )

    container:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:toggle_notification_popup()
        end),
        awful.button({}, 2, function()
            instance:toggle_daemon_pause()
        end),
        awful.button({}, 3, function()
            instance:close_popups()
            instance:dismiss_all()
        end)
    ))

    return {
        root = container,
        text = text_widget,
    }
end

return widget
