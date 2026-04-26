local awful = require("awful")
local gears = require("gears")
local keygrabber = require("awful.keygrabber")
local awful_key = require("awful.key")

local M = {}

local function looks_like_geometry(value)
    return type(value) == "table"
        and type(value.x) == "number"
        and type(value.y) == "number"
        and type(value.width) == "number"
        and type(value.height) == "number"
end

local function filtered_modifiers(modifiers)
    local filtered = {}
    local ignored = {}

    for _, modifier in ipairs(awful_key.ignore_modifiers or {}) do
        ignored[modifier] = true
    end

    for _, modifier in ipairs(modifiers or {}) do
        if not ignored[modifier] then
            filtered[#filtered + 1] = modifier
        end
    end

    return filtered
end

local function has_modifiers(modifiers)
    return #filtered_modifiers(modifiers) > 0
end

local function modifiers_match(binding_modifiers, pressed_modifiers)
    local wanted = filtered_modifiers(binding_modifiers)
    local active = filtered_modifiers(pressed_modifiers)

    for _, modifier in ipairs(wanted) do
        if modifier == "Any" then
            return true
        end
    end

    if #wanted ~= #active then
        return false
    end

    local active_set = {}
    for _, modifier in ipairs(active) do
        active_set[modifier] = true
    end

    for _, modifier in ipairs(wanted) do
        if not active_set[modifier] then
            return false
        end
    end

    return true
end

local function keybinding_matches(keybinding, pressed_modifiers, key)
    if not keybinding then
        return false, nil
    end

    if type(keybinding.match) == "function" and keybinding:match(pressed_modifiers, key) then
        return true, keybinding
    end

    if keybinding.key == key and modifiers_match(keybinding.modifiers, pressed_modifiers) then
        return true, keybinding
    end

    for _, sub_key in ipairs(keybinding) do
        if sub_key.key == key and modifiers_match(sub_key.modifiers, pressed_modifiers) then
            return true, sub_key
        end
    end

    return false, nil
end

local function keybinding_entries(keybinding)
    if type(keybinding) ~= "table" then
        return {}
    end

    if type(keybinding.key) == "string" then
        return {
            {
                key = keybinding.key,
                modifiers = filtered_modifiers(keybinding.modifiers),
                matched_binding = keybinding,
            },
        }
    end

    local entries = {}
    for _, sub_key in ipairs(keybinding) do
        if type(sub_key) == "table" and type(sub_key.key) == "string" then
            entries[#entries + 1] = {
                key = sub_key.key,
                modifiers = filtered_modifiers(sub_key.modifiers),
                matched_binding = sub_key,
            }
        end
    end

    return entries
end

local function keybinding_owner(keybinding)
    if type(keybinding) ~= "table" then
        return keybinding
    end

    local private = rawget(keybinding, "_private")
    if type(private) == "table" and private._legacy_convert_to then
        return private._legacy_convert_to
    end

    return keybinding
end

local function trigger_callback(keybinding, matched_binding)
    local owner = keybinding_owner(matched_binding or keybinding)

    if type(owner) == "table" and type(owner.trigger) == "function" then
        return function()
            owner:trigger()
        end
    end

    if type(keybinding) == "table" and type(keybinding.trigger) == "function" then
        return function()
            keybinding:trigger()
        end
    end

    if type(owner) == "table" and type(owner.on_press) == "function" then
        return function()
            owner.on_press()
        end
    end

    if type(keybinding) == "table" and type(keybinding.on_press) == "function" then
        return function()
            keybinding.on_press()
        end
    end

    return nil
end

local function blocked_global_key(blocked, key, modifiers)
    return blocked[key] and not has_modifiers(modifiers)
end

---Try to execute a matching root/global keybinding for a popup-owned key event.
function M.dispatch_global_keybinding(modifiers, key, opts)
    opts = opts or {}

    local root_keys = root.keys and root.keys() or {}
    local pressed_modifiers = filtered_modifiers(modifiers)
    local blocked = {}

    for _, blocked_key in ipairs(opts.blocked_keys or {}) do
        blocked[blocked_key] = true
    end

    if blocked_global_key(blocked, key, modifiers) then
        return false
    end

    for _, keybinding in ipairs(root_keys) do
        local matches, matched_binding = keybinding_matches(keybinding, pressed_modifiers, key)
        local trigger = matches and trigger_callback(keybinding, matched_binding) or nil

        if trigger then
            if type(opts.before_dispatch) == "function" then
                opts.before_dispatch()
            end

            gears.timer.delayed_call(trigger)
            return true
        end
    end

    return false
end

function M.build_global_fallback_keybindings(opts)
    opts = opts or {}

    local blocked = {}
    for _, blocked_key in ipairs(opts.blocked_keys or {}) do
        blocked[blocked_key] = true
    end

    local bindings = {}
    for _, keybinding in ipairs(root.keys and root.keys() or {}) do
        for _, entry in ipairs(keybinding_entries(keybinding)) do
            if entry.key and not blocked_global_key(blocked, entry.key, entry.modifiers) then
                bindings[#bindings + 1] = awful_key(entry.modifiers, entry.key, function()
                    local trigger = trigger_callback(keybinding, entry.matched_binding)
                    if not trigger then
                        return
                    end

                    if type(opts.before_dispatch) == "function" then
                        opts.before_dispatch()
                    end

                    gears.timer.delayed_call(trigger)
                end)
            end
        end
    end

    return bindings
end

---Normalize the supported popup-helper call styles into one opts table.
function M.normalize_popup_opts(arg1, arg2)
    if type(arg2) == "table" then
        return arg2
    end

    if type(arg1) == "table" and not looks_like_geometry(arg1) then
        return arg1
    end

    return {}
end

---Normalize a popup toggle key description for equality-style matching.
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

---Return true when the active modifier set exactly matches a popup toggle key.
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

---Return true when a point falls inside a geometry table.
function M.point_in_geometry(x, y, geo)
    return geo
        and x >= geo.x and x < (geo.x + geo.width)
        and y >= geo.y and y < (geo.y + geo.height)
end

---Shallow-copy Awesome button objects into a fresh array.
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

---Disconnect and restore all outside-click-dismiss plumbing for one popup.
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

---Install outside-click dismissal hooks for the currently visible popup.
---This augments root/client/drawin button handling so the popup can dismiss
---when the user clicks outside any provided popup geometry.
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

---Stop and clear a hover-close timer stored on an instance.
function M.stop_hover_close_timer(instance, opts)
    opts = opts or {}
    local timer_key = opts.timer_key or "_hover_close_timer"

    if instance[timer_key] then
        instance[timer_key]:stop()
        instance[timer_key] = nil
    end
end

---Start a hover-close timer that dismisses once the pointer stays outside.
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

---Dispatch one popup keypress against cycle, close, and module-local actions.
function M.dispatch_popup_keypress(opts)
    opts = opts or {}

    if opts.event ~= "press" then
        return true
    end

    local is_open = opts.is_open or function()
        return false
    end

    if not is_open() then
        if type(opts.on_not_open) == "function" then
            opts.on_not_open()
        end
        return true
    end

    local match_opts = {
        ignored_modifiers = opts.ignored_modifiers,
    }

    if M.popup_toggle_key_matches(opts.prev_keychain, opts.modifiers, opts.key, match_opts)
        and type(opts.on_cycle_prev) == "function" then
        opts.on_cycle_prev()
        return true
    end

    if M.popup_toggle_key_matches(opts.next_keychain, opts.modifiers, opts.key, match_opts)
        and type(opts.on_cycle_next) == "function" then
        opts.on_cycle_next()
        return true
    end

    if M.popup_toggle_key_matches(opts.toggle_key, opts.modifiers, opts.key, match_opts)
        or opts.key == "Escape" then
        if type(opts.on_close) == "function" then
            opts.on_close()
        end
        return true
    end

    local actions = opts.actions or {}
    local action = actions[opts.key]
    if type(action) == "function" then
        action()
        return true
    end

    if opts.allow_global_fallback ~= false
        and M.dispatch_global_keybinding(opts.modifiers, opts.key, {
            blocked_keys = opts.blocked_global_keys,
            before_dispatch = opts.on_global_fallback,
        }) then
        return true
    end

    return false
end

---Create or reuse a keygrabber stored on the popup-owning instance.
function M.ensure_popup_keygrabber(instance, opts)
    opts = opts or {}
    local grabber_key = opts.grabber_key or "_popup_keygrabber"
    local active_key = opts.active_key or "_popup_keyboard_navigation_active"
    local handler = opts.handler

    if not instance[grabber_key] then
        instance[grabber_key] = keygrabber({
            keybindings = M.build_global_fallback_keybindings(opts.global_fallback),
            stop_callback = function()
                instance[active_key] = false
                if type(opts.on_stop) == "function" then
                    opts.on_stop()
                end
            end,
            keypressed_callback = function(grabber, modifiers, key, event)
                handler(grabber, modifiers, key, event)
            end,
        })
    else
        instance[grabber_key]._private.keybindings = {}
        for _, keybinding in ipairs(M.build_global_fallback_keybindings(opts.global_fallback)) do
            instance[grabber_key]:add_keybinding(keybinding)
        end
    end

    return instance[grabber_key]
end

---Focus the popup keygrabber and start keyboard navigation if needed.
function M.focus_popup_keygrabber(instance, opts)
    opts = opts or {}
    local grabber_key = opts.grabber_key or "_popup_keygrabber"
    local active_key = opts.active_key or "_popup_keyboard_navigation_active"
    local grabber = M.ensure_popup_keygrabber(instance, opts)

    instance[active_key] = true

    if grabber.grabber then
        return grabber
    end

    grabber:start()
    if type(opts.on_start) == "function" then
        opts.on_start()
    end

    return grabber
end

---Blur the popup keygrabber and stop keyboard navigation if active.
function M.blur_popup_keygrabber(instance, opts)
    opts = opts or {}
    local grabber_key = opts.grabber_key or "_popup_keygrabber"
    local active_key = opts.active_key or "_popup_keyboard_navigation_active"

    instance[active_key] = false

    local grabber = instance[grabber_key]
    if grabber and grabber.grabber then
        grabber:stop()
    end
end

return M
