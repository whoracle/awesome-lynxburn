local beautiful = require("beautiful")
local lain = require("lain")
local wibox = require("wibox")

local markup = lain.util.markup

local M = {}

local function metric_icon(icon_path)
    local icon = wibox.widget.imagebox(icon_path)
    icon.forced_width = 0
    icon.forced_height = 0
    return icon
end

function M.build(context, icon_path, widget)
    local theme = context and context.beautiful or beautiful
    local icon = metric_icon(icon_path)

    return {
        icon = icon,
        metric = {
            widget = wibox.widget({
                {
                    icon,
                    widget,
                    layout = wibox.layout.fixed.horizontal,
                },
                draw_empty = false,
                widget = wibox.container.margin,
            }),
            style = "lxbar",
        },
        theme = theme,
    }
end

function M.show(icon)
    icon.forced_width = nil
    icon.forced_height = nil
end

function M.hide(icon)
    icon.forced_width = 0
    icon.forced_height = 0
end

function M.font(theme, text)
    return markup.font(theme.font, text)
end

function M.color(theme, text)
    return markup(theme.tasklist_fg_normal, text)
end

return M
