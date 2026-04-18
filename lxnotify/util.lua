local awful = require("awful")
local beautiful = require("beautiful")

local util = {}

function util.theme_value(theme_key, fallback)
    local theme_value = beautiful[theme_key]
    if theme_value ~= nil then
        return theme_value
    end

    return fallback
end

function util.resolve_screen(anchor)
    if type(anchor) == "table" then
        if anchor.screen then
            return anchor.screen
        end

        if anchor.x and anchor.y then
            local screen_index = awful.screen.getbycoord(anchor.x, anchor.y)
            if screen_index then
                return screen[screen_index]
            end
        end
    end

    return awful.screen.focused()
end

function util.attach_hover_background(widget, normal_bg, hover_bg, press_bg)
    if not widget or not hover_bg or hover_bg == normal_bg then
        return
    end

    local pointer_inside = false
    local pressed = false
    local active = false

    local function sync_bg()
        if pressed then
            widget.bg = press_bg or hover_bg
        elseif pointer_inside or active then
            widget.bg = hover_bg
        else
            widget.bg = normal_bg
        end
    end

    widget:connect_signal("mouse::enter", function()
        pointer_inside = true
        sync_bg()
    end)

    widget:connect_signal("mouse::leave", function()
        pointer_inside = false
        pressed = false
        sync_bg()
    end)

    widget:connect_signal("button::press", function()
        pressed = true
        sync_bg()
    end)

    widget:connect_signal("button::release", function()
        pressed = false
        sync_bg()
    end)

    widget._lx_set_feedback_active = function(_, value)
        active = value and true or false
        sync_bg()
    end
end

return util
