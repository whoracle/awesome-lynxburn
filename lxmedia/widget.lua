local awful = require("awful")
local gears = require("gears")
local matrix = require("gears.matrix")
local wibox = require("wibox")
local beautiful = require("beautiful")
local mouse = mouse

local M = {}

local function sync_bar_visibility(instance)
    if type(instance._sync_toplevel_bar_visibility) == "function" then
        instance:_sync_toplevel_bar_visibility()
    end
end

local function hover_open_delay()
    return tonumber(beautiful.lxmedia_bar_hover_open_delay) or 1
end

local function capture_anchor(instance, hit)
    if not (hit and hit.x and hit.y and hit.width and hit.height) then
        return
    end

    instance._last_anchor_geo = {
        x = hit.x,
        y = hit.y,
        width = hit.width,
        height = hit.height,
        drawable = hit.drawable,
    }
end

local function current_anchor(instance)
    local geo = mouse.current_widget_geometry
    if not (geo and geo.x and geo.y and geo.width and geo.height) then
        return instance._last_anchor_geo
    end

    return {
        x = geo.x,
        y = geo.y,
        width = geo.width,
        height = geo.height,
        drawable = mouse.current_wibox,
    }
end

local function find_widget_hierarchy(hierarchy, target)
    if not hierarchy then
        return nil
    end

    if hierarchy:get_widget() == target then
        return hierarchy
    end

    for _, child in ipairs(hierarchy:get_children()) do
        local result = find_widget_hierarchy(child, target)
        if result then
            return result
        end
    end

    return nil
end

local function resolve_anchor_from_wibox(widget, wb)
    if not (wb and wb.visible and wb._drawable and wb._drawable._widget_hierarchy) then
        return nil
    end

    local hierarchy = find_widget_hierarchy(wb._drawable._widget_hierarchy, widget)
    if not hierarchy then
        return nil
    end

    local width, height = hierarchy:get_size()
    local x, y, w, h = matrix.transform_rectangle(
        hierarchy:get_matrix_to_device(),
        0,
        0,
        width,
        height
    )

    return {
        x = x,
        y = y,
        width = w,
        height = h,
        drawable = wb._drawable,
        widget = widget,
        hierarchy = hierarchy,
    }
end

local function resolve_anchor(instance)
    local ok, drawins = pcall(function()
        return drawin.get()
    end)
    if not ok or type(drawins) ~= "table" then
        return instance._last_anchor_geo
    end

    for _, d in ipairs(drawins) do
        if d.valid and d.visible and d.get_wibox then
            local wb = d:get_wibox()
            local anchor = resolve_anchor_from_wibox(instance._anchor, wb)
            if anchor then
                instance._last_anchor_geo = anchor
                return anchor
            end
        end
    end

    return instance._last_anchor_geo
end

-- Build the compact bar widget and connect its mouse bindings to the shared
-- instance-level control API.
function M.build(instance)
    local mic_visible = instance.opts.show_mic_activity and instance.state.mic_active or false
    local output_fg = instance.state.muted
        and (beautiful.lxmedia_widget_muted_fg or beautiful.fg_minimize or "#888888")
        or (beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0")
    local mic_fg = instance.state.mic_muted
        and (beautiful.lxmedia_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
        or (beautiful.lxmedia_mic_bar_fg or beautiful.lxmedia_bar_fg or beautiful.fg_normal or "#e2ccb0")

    local icon = wibox.widget {
        text = instance.state.muted and instance.opts.icon_muted or instance.opts.icon_unmuted,
        fg = instance.state.muted
            and (beautiful.lxmedia_widget_muted_fg or beautiful.fg_minimize or "#888888")
            or (beautiful.lxmedia_widget_fg or beautiful.fg_normal or "#ffffff"),
        font = beautiful.lxmedia_icon_font or beautiful.font,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    }

    local bar = wibox.widget {
        max_value        = 1,
        value            = instance.state.volume or 0,
        forced_width     = instance.opts.width,
        forced_height    = 8,
        paddings         = beautiful.lxmedia_bar_padding or 2,
        border_width     = 0,
        background_color = beautiful.lxmedia_bar_bg or beautiful.bg_minimize or "#140c0b",
        color            = output_fg,
        widget           = wibox.widget.progressbar,
    }

    local mic = wibox.widget {
        text = instance.state.mic_muted and instance.opts.icon_mic_muted or instance.opts.icon_mic_active,
        fg = instance.state.mic_muted
            and (beautiful.lxmedia_widget_mic_muted_fg or beautiful.fg_minimize or "#888888")
            or (beautiful.lxmedia_widget_mic_fg or beautiful.fg_urgent or "#ff6666"),
        font = beautiful.lxmedia_icon_font or beautiful.font,
        visible = mic_visible,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    }

    local mic_bar = wibox.widget {
        max_value        = 1,
        value            = instance.state.mic_volume or 0,
        forced_width     = instance.opts.width,
        forced_height    = 8,
        paddings         = beautiful.lxmedia_bar_padding or 2,
        border_width     = 0,
        background_color = beautiful.lxmedia_mic_bar_bg or beautiful.lxmedia_bar_bg or beautiful.bg_minimize or "#140c0b",
        color            = mic_fg,
        visible          = mic_visible,
        widget           = wibox.widget.progressbar,
    }

    instance._refs.icon = icon
    instance._refs.bar = bar
    instance._refs.mic = mic
    instance._refs.mic_bar = mic_bar

    local output_bar_slot = wibox.widget {
        {
            bar,
            right = 1,
            widget = wibox.container.margin,
        },
        valign = "center",
        widget = wibox.container.place,
    }

    local output_bar_margin = wibox.widget {
        output_bar_slot,
        left = 6,
        widget = wibox.container.margin,
    }

    local output_cluster = wibox.widget {
        {
            {
                icon,
                halign = "center",
                valign = "center",
                widget = wibox.container.place,
            },
            forced_width = beautiful.lxmedia_icon_width or 20,
            strategy = "exact",
            widget = wibox.container.constraint,
        },
        output_bar_margin,
        layout = wibox.layout.fixed.horizontal,
    }

    local mic_bar_slot = wibox.widget {
        {
            mic_bar,
            right = 1,
            widget = wibox.container.margin,
        },
        valign = "center",
        widget = wibox.container.place,
    }

    local mic_bar_margin = wibox.widget {
        mic_bar_slot,
        left = 6,
        widget = wibox.container.margin,
    }

    local mic_cluster = wibox.widget {
        {
            {
                mic,
                halign = "center",
                valign = "center",
                widget = wibox.container.place,
            },
            forced_width = beautiful.lxmedia_icon_width or 20,
            strategy = "exact",
            widget = wibox.container.constraint,
        },
        mic_bar_margin,
        visible = mic_visible,
        layout = wibox.layout.fixed.horizontal,
    }

    instance._refs.mic_cluster = mic_cluster
    instance._refs.output_bar_slot = output_bar_slot
    instance._refs.output_bar_margin = output_bar_margin
    instance._refs.mic_bar_slot = mic_bar_slot
    instance._refs.mic_bar_margin = mic_bar_margin

    local row = wibox.widget {
        {
            mic_cluster,
            output_cluster,
            spacing = 6,
            layout = wibox.layout.fixed.horizontal,
        },
        widget = wibox.container.margin,
    }
    local shell = wibox.widget({
        row,
        widget = wibox.container.background,
    })
    instance._feedback_widget = shell

    require("lxcommon.popup_ui").attach_button_feedback(shell, {
        idle_bg = nil,
        hover_bg = beautiful.lxmedia_bg_hover or beautiful.bg_focus or "#444444",
        press_bg = beautiful.lxmedia_button_hover or beautiful.bg_focus or "#666666",
    })

    instance._anchor = shell
    instance._resolve_anchor_geo = function()
        return resolve_anchor(instance)
    end

    shell:connect_signal("mouse::enter", function(_, hit)
        capture_anchor(instance, hit)
        require("lxcommon.util").start_delayed_hover(instance, {
            delay = hover_open_delay(),
            on_change = function()
                sync_bar_visibility(instance)
            end,
        })
    end)

    shell:connect_signal("mouse::leave", function()
        require("lxcommon.util").stop_delayed_hover(instance, {
            on_change = function()
                sync_bar_visibility(instance)
            end,
        })
    end)

    shell:buttons(gears.table.join(
        awful.button({}, 1, function()
            instance:toggle_media_popup(current_anchor(instance))
        end),
        awful.button({}, 3, function()
            instance:toggle_devices_popup(current_anchor(instance))
        end)
    ))

    output_cluster:buttons(gears.table.join(
        awful.button({}, 2, function()
            instance:toggle_mute()
        end),
        awful.button({}, 4, function()
            instance:volume_up()
        end),
        awful.button({}, 5, function()
            instance:volume_down()
        end)
    ))

    mic_cluster:buttons(gears.table.join(
        awful.button({}, 2, function()
            instance:toggle_input_mute()
        end),
        awful.button({}, 4, function()
            instance:input_volume_up()
        end),
        awful.button({}, 5, function()
            instance:input_volume_down()
        end)
    ))

    sync_bar_visibility(instance)

    return shell
end

return M
