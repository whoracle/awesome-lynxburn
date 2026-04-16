local awful = require("awful")

local M = {}

function M.normalize(value, default)
    if value == "left" or value == "right" or value == "center" then
        return value
    end

    return default or "center"
end

function M.apply(popup_widget, target_screen, placement, opts)
    opts = opts or {}
    placement = M.normalize(placement, opts.default)

    local workarea = target_screen.workarea
    local width = math.min(opts.width or workarea.width, workarea.width)

    popup_widget.screen = target_screen

    if placement == "left" or placement == "right" then
        popup_widget.type = "dock"
        popup_widget.minimum_width = width
        popup_widget.maximum_width = width
        popup_widget.minimum_height = workarea.height
        popup_widget.maximum_height = workarea.height
        popup_widget:geometry({
            x = placement == "left" and workarea.x or (workarea.x + workarea.width - width),
            y = workarea.y,
            width = width,
            height = workarea.height,
        })
        return
    end

    popup_widget.type = opts.center_type or "utility"
    popup_widget.minimum_width = width
    popup_widget.maximum_width = width
    popup_widget.minimum_height = nil
    popup_widget.maximum_height = nil
    popup_widget:geometry({ width = width })
    awful.placement.centered(popup_widget, {
        honor_workarea = true,
        honor_padding = true,
    })
end

return M
