local awful = require("awful")
local gears = require("gears")

local M = {}

function M.normalize_popup_opts(arg1, arg2)
    if type(arg2) == "table" then
        return arg2
    end

    if type(arg1) == "table" then
        return arg1
    end

    return {}
end

function M.normalize_popup_toggle_key(toggle_key, opts)
    opts = opts or {}
    local ignored_modifiers = opts.ignored_modifiers or {}

    if type(toggle_key) ~= "table" or type(toggle_key.key) ~= "string" then
        return nil
    end

    local normalized = {
        key = toggle_key.key,
        modifiers = {},
        modifier_set = {},
    }

    if type(toggle_key.modifiers) == "table" then
        for _, modifier in ipairs(toggle_key.modifiers) do
            if type(modifier) == "string" and modifier ~= "" and not ignored_modifiers[modifier] then
                normalized.modifier_set[modifier] = true
            end
        end
    end

    for modifier in pairs(normalized.modifier_set) do
        normalized.modifiers[#normalized.modifiers + 1] = modifier
    end

    table.sort(normalized.modifiers)

    return normalized
end

function M.popup_toggle_key_matches(toggle_key, modifiers, key, opts)
    opts = opts or {}
    local ignored_modifiers = opts.ignored_modifiers or {}

    if not toggle_key or key ~= toggle_key.key then
        return false
    end

    local active_modifiers = {}
    for _, modifier in ipairs(modifiers or {}) do
        if not ignored_modifiers[modifier] then
            active_modifiers[modifier] = true
        end
    end

    for modifier in pairs(active_modifiers) do
        if not toggle_key.modifier_set[modifier] then
            return false
        end
    end

    for modifier in pairs(toggle_key.modifier_set) do
        if not active_modifiers[modifier] then
            return false
        end
    end

    return true
end

function M.point_in_geometry(x, y, geo)
    return geo
        and x >= geo.x and x < (geo.x + geo.width)
        and y >= geo.y and y < (geo.y + geo.height)
end

function M.copy_button_list(buttons)
    local copied = {}

    if not buttons then
        return copied
    end

    for _, button in ipairs(buttons) do
        copied[#copied + 1] = button
    end

    return copied
end

local function inside_any_geometry(x, y, geometry_providers)
    for _, provider in ipairs(geometry_providers or {}) do
        local geo = provider()
        if M.point_in_geometry(x, y, geo) then
            return true
        end
    end

    return false
end

function M.stop_outside_click_dismiss(instance, opts)
    opts = opts or {}

    local binding_key = opts.binding_key or "_popup_outside_click_binding"
    local buttons_key = opts.saved_root_buttons_key or "_popup_saved_root_buttons"
    local handler_key = opts.handler_key or "_popup_outside_click_handler"

    if instance[binding_key] then
        instance[binding_key] = nil
    end

    if instance[buttons_key] then
        root.buttons(instance[buttons_key])
        instance[buttons_key] = nil
    end

    if instance[handler_key] then
        if client and client.disconnect_signal then
            client.disconnect_signal("button::press", instance[handler_key])
        end

        if drawin and drawin.disconnect_signal then
            drawin.disconnect_signal("button::press", instance[handler_key])
        end

        instance[handler_key] = nil
    end
end

function M.start_outside_click_dismiss(instance, opts)
    opts = opts or {}
    M.stop_outside_click_dismiss(instance, opts)

    local binding_key = opts.binding_key or "_popup_outside_click_binding"
    local buttons_key = opts.saved_root_buttons_key or "_popup_saved_root_buttons"
    local handler_key = opts.handler_key or "_popup_outside_click_handler"
    local is_open = opts.is_open or function()
        return false
    end
    local geometry_providers = opts.geometry_providers or {}
    local on_outside_click = opts.on_outside_click or function() end

    local handler = function()
        if not is_open() then
            return
        end

        local coords = mouse.coords()
        if inside_any_geometry(coords.x, coords.y, geometry_providers) then
            return
        end

        on_outside_click()
    end

    instance[handler_key] = handler
    instance[binding_key] = awful.button({}, 1, handler)
    instance[buttons_key] = M.copy_button_list(root.buttons())

    local merged_root_buttons = M.copy_button_list(instance[buttons_key])
    merged_root_buttons[#merged_root_buttons + 1] = instance[binding_key]
    root.buttons(merged_root_buttons)

    if client and client.connect_signal then
        client.connect_signal("button::press", handler)
    end

    if drawin and drawin.connect_signal then
        drawin.connect_signal("button::press", handler)
    end
end

function M.stop_hover_close_timer(instance, opts)
    opts = opts or {}
    local timer_key = opts.timer_key or "_hover_close_timer"

    if instance[timer_key] then
        instance[timer_key]:stop()
        instance[timer_key] = nil
    end
end

function M.start_hover_close_timer(instance, opts)
    opts = opts or {}
    local timer_key = opts.timer_key or "_hover_close_timer"
    local poll_interval = opts.poll_interval or 0.25
    local hover_timeout = opts.hover_timeout or 1.5
    local is_open = opts.is_open or function()
        return false
    end
    local geometry_providers = opts.geometry_providers or {}
    local on_timeout = opts.on_timeout or function() end

    M.stop_hover_close_timer(instance, { timer_key = timer_key })

    local outside_ticks = 0
    local max_outside_ticks = math.max(1, math.floor((hover_timeout / poll_interval) + 0.5))

    instance[timer_key] = gears.timer({
        timeout = poll_interval,
        autostart = true,
        call_now = false,
        callback = function()
            if not is_open() then
                M.stop_hover_close_timer(instance, { timer_key = timer_key })
                return
            end

            local coords = mouse.coords()
            if inside_any_geometry(coords.x, coords.y, geometry_providers) then
                outside_ticks = 0
                return
            end

            outside_ticks = outside_ticks + 1
            if outside_ticks >= max_outside_ticks then
                on_timeout()
            end
        end,
    })
end

return M
