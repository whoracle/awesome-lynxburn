local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local M = {}

-- Shared popup card primitive used by both popup modules.
function M.make_card(child, opts)
    opts = opts or {}

    return wibox.widget {
        {
            child,
            margins = opts.margins or 0,
            widget = wibox.container.margin,
        },
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, opts.radius or 0)
        end,
        widget = wibox.container.background,
    }
end

function M.make_text(text, opts)
    opts = opts or {}

    return wibox.widget {
        markup = text or "",
        ellipsize = opts.ellipsize,
        valign = opts.valign,
        widget = wibox.widget.textbox,
    }
end

-- Shared text row primitive with padding and optional fixed height.
function M.make_info_line(text, opts)
    opts = opts or {}

    local row = wibox.widget {
        {
            M.make_text(text, opts.text_opts),
            left = opts.left or 12,
            right = opts.right or 8,
            top = opts.top or 2,
            bottom = opts.bottom or 2,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    }

    row.forced_height = opts.forced_height or row.forced_height
    return row
end

-- Shared clickable row/container primitive that supports left click, middle
-- click, and scroll actions.
function M.make_click_container(child, onclick, opts)
    opts = opts or {}

    local bg = wibox.widget {
        {
            child,
            left = opts.left or 8,
            right = opts.right or 8,
            top = opts.top or 6,
            bottom = opts.bottom or 6,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    }

    bg.forced_height = opts.forced_height or bg.forced_height

    if not (onclick or opts.on_middle_click or opts.on_scroll_up or opts.on_scroll_down) then
        return bg
    end

    local buttons = {}
    local hover_bg = opts.hover_bg
    local idle_bg = opts.idle_bg

    bg:connect_signal("mouse::enter", function()
        bg.bg = hover_bg
    end)

    bg:connect_signal("mouse::leave", function()
        bg.bg = idle_bg
    end)

    if onclick then
        buttons[#buttons + 1] = awful.button({}, 1, onclick)
    end

    if opts.on_middle_click then
        buttons[#buttons + 1] = awful.button({}, 2, opts.on_middle_click)
    end

    if opts.on_scroll_up then
        buttons[#buttons + 1] = awful.button({}, 4, opts.on_scroll_up)
    end

    if opts.on_scroll_down then
        buttons[#buttons + 1] = awful.button({}, 5, opts.on_scroll_down)
    end

    bg:buttons(gears.table.join(table.unpack(buttons)))
    return bg
end

function M.make_click_row(text, onclick, opts)
    opts = opts or {}
    return M.make_click_container(M.make_text(text, opts.text_opts), onclick, opts)
end

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

    popup.screen = opts.screen or awful.screen.focused()
    awful.placement.centered(popup, {
        honor_workarea = true,
        honor_padding = true,
    })
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
