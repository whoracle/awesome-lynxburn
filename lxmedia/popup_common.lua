local awful = require("awful")
local popup_placement = require("lxcommon.popup_placement")
local popup_ui = require("lxcommon.popup_ui")

local M = {}

M.make_card = popup_ui.make_card
M.make_text = popup_ui.make_text
M.make_info_line = popup_ui.make_info_line
M.attach_button_feedback = popup_ui.attach_button_feedback
M.make_click_container = popup_ui.make_click_container
M.make_click_row = popup_ui.make_click_row
M.make_selectable_click_container = popup_ui.make_selectable_click_container
M.make_selectable_click_row = popup_ui.make_selectable_click_row

function M.rebuild_popup(instance, popup_key, builder)
    local popup = instance[popup_key]
    if popup then
        popup.widget = builder(instance)
    end
end

-- Show a popup either next to explicit widget geometry, next to the instance's
-- anchor widget, or centered on the focused screen.
function M.show_popup(instance, popup_key, geo_key, geo, builder, opts)
    opts = opts or {}

    local popup = instance[popup_key]

    if geo and geo.x and geo.y and geo.width and geo.height then
        instance[geo_key] = geo
        instance._last_anchor_geo = geo
    end

    if not popup then
        popup = awful.popup {
            ontop = true,
            visible = false,
            border_width = 0,
            preferred_positions = { "bottom", "top" },
            preferred_anchors = { "middle", "front", "back" },
            offset = { y = 6 },
            widget = builder(instance),
        }
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

-- Toggle a popup and report whether it ended up visible.
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
