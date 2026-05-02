local beautiful = require("beautiful")
local lain = require("lain")
local wibox = require("wibox")

local markup = lain.util.markup

local M = {}

local function metric_icon(icon_spec)
    local icon

    if type(icon_spec) == "table" and icon_spec.glyph then
        icon = wibox.widget.textbox(icon_spec.glyph)
        icon.font = icon_spec.font or beautiful.font
        icon.align = icon_spec.align or "center"
        icon.valign = icon_spec.valign or "center"
        icon._lx_visible_width = icon_spec.width
        icon._lx_visible_height = icon_spec.height
    else
        icon = wibox.widget.imagebox(icon_spec)
    end

    M.hide(icon)
    return icon
end

function M.icon(icon_path)
    return metric_icon(icon_path)
end

function M.wrap(context, icon, widget)
    local theme = context and context.beautiful or beautiful

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
    icon.forced_width = icon._lx_visible_width
    icon.forced_height = icon._lx_visible_height
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
