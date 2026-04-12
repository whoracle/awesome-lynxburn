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

function util.normalize_edge(edge)
    if edge == "left" or edge == "right" then
        return edge
    end

    return "right"
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

function util.attach_hover_background(widget, normal_bg, hover_bg)
    if not widget or not hover_bg or hover_bg == normal_bg then
        return
    end

    widget:connect_signal("mouse::enter", function()
        widget.bg = hover_bg
    end)

    widget:connect_signal("mouse::leave", function()
        widget.bg = normal_bg
    end)
end

return util
