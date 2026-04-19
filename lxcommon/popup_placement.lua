local awful = require("awful")
local lxmodules = require("config.lxmodules")

local M = {}

---Normalize legacy placement aliases into the current center/side model.
function M.normalize(value, default)
    if value == "side" or value == "center" then
        return value
    end

    if value == "left" or value == "right" then
        return "side"
    end

    return default or "center"
end

---Resolve the concrete side only when the placement model is side-based.
function M.resolve_side(placement)
    if M.normalize(placement, "center") ~= "side" then
        return nil
    end

    return lxmodules.popup_side()
end

---Apply shared popup geometry for either centered or side-docked popups.
function M.apply(popup_widget, target_screen, placement, opts)
    opts = opts or {}
    placement = M.normalize(placement, opts.default)

    local workarea = target_screen.workarea
    local width = math.min(opts.width or workarea.width, workarea.width)
    local side = M.resolve_side(placement)

    popup_widget.screen = target_screen

    if side then
        popup_widget.type = "dock"
        popup_widget.minimum_width = width
        popup_widget.maximum_width = width
        popup_widget.minimum_height = workarea.height
        popup_widget.maximum_height = workarea.height
        popup_widget:geometry({
            x = side == "left" and workarea.x or (workarea.x + workarea.width - width),
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
