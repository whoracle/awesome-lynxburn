local awful = require("awful")

local popup_placement = require("lxcommon.popup_placement")

local M = {}

---Replace the widget tree of an existing popup.
function M.rebuild_popup(instance, popup_key, builder)
    local popup = instance[popup_key]
    if popup then
        popup.widget = builder(instance)
    end
end

---Show a popup either next to explicit widget geometry or using shared placement.
function M.show_popup(instance, popup_key, geo_key, geo, builder, opts)
    opts = opts or {}

    local popup = instance[popup_key]

    if geo and geo.x and geo.y and geo.width and geo.height then
        instance[geo_key] = geo
        instance._last_anchor_geo = geo
    end

    if not popup then
        popup = awful.popup({
            ontop = true,
            visible = false,
            border_width = 0,
            preferred_positions = { "bottom", "top" },
            preferred_anchors = { "middle", "front", "back" },
            offset = { y = 6 },
            widget = builder(instance),
        })
        instance[popup_key] = popup
    else
        popup.widget = builder(instance)
    end

    popup.visible = true

    if opts.placement then
        popup_placement.apply(
            popup,
            opts.screen or awful.screen.focused(),
            opts.placement,
            { width = opts.width or popup.minimum_width or popup.maximum_width or 420 }
        )
        return
    end

    local anchor_mode = opts.anchor or "widget"
    if anchor_mode == "widget" then
        local anchor = geo or instance[geo_key] or instance._last_anchor_geo
        if not anchor and instance._resolve_anchor_geo then
            anchor = instance:_resolve_anchor_geo()
        end
        if anchor and anchor.x and anchor.y and anchor.width and anchor.height then
            popup:move_next_to(anchor)
            return
        end
    end

    popup_placement.apply(
        popup,
        opts.screen or awful.screen.focused(),
        "center",
        { width = opts.width or popup.minimum_width or popup.maximum_width or 420 }
    )
end

---Toggle a popup and report whether it ended up visible.
function M.toggle_popup(instance, popup_key, geo_key, geo, builder, opts)
    local popup = instance[popup_key]

    if popup and popup.visible then
        popup.visible = false
        if instance._stop_hover_close_timer then
            instance:_stop_hover_close_timer()
        end
        return false
    end

    M.show_popup(instance, popup_key, geo_key, geo, builder, opts)
    return true
end

return M
