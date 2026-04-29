local popup_control = require("lxcommon.popup_control")
local popup_session = require("lxcommon.popup_session")
local widget_feedback = require("lxcommon.widget_feedback")

local M = {}

local function is_geometry(value)
    return type(value) == "table"
        and type(value.x) == "number"
        and type(value.y) == "number"
        and type(value.width) == "number"
        and type(value.height) == "number"
end

local DEFAULT_ACTIONS = {
    Up = function(self)
        self:move_popup_selection(-1)
    end,
    Down = function(self)
        self:move_popup_selection(1)
    end,
    Return = function(self)
        self:activate_selected_popup_item()
    end,
    KP_Enter = function(self)
        self:activate_selected_popup_item()
    end,
}

local function default_geometry_providers(self, popup_key)
    return {
        function()
            return popup_session.geometry(self, popup_key)
        end,
    }
end

local function normalize_descriptors(opts)
    if opts.popups then
        return opts.popups, opts.default_popup or "main"
    end

    return {
        main = {
            popup_key = opts.popup_key,
            build = opts.build,
            open = opts.open,
            close = opts.close,
            actions = opts.actions,
            prepare_opts = opts.prepare_opts,
            geometry_providers = opts.geometry_providers,
            close_extras = opts.close_extras,
        },
    }, opts.default_popup or "main"
end

local function resolve_descriptor(descriptors, name)
    local descriptor = descriptors[name]
    if not descriptor then
        error("unknown popup descriptor: " .. tostring(name))
    end

    return descriptor
end

local function popup_key_for(descriptor)
    return descriptor.popup_key or "_popup"
end

local function call_or_value(value, self, ...)
    if type(value) == "function" then
        return value(self, ...)
    end

    return value
end

local function resolve_actions(self, descriptor)
    local actions = {}

    if descriptor.default_actions ~= false then
        for key, action in pairs(DEFAULT_ACTIONS) do
            actions[key] = function()
                action(self)
            end
        end
    end

    local extra_actions = call_or_value(descriptor.actions, self) or {}
    for key, action in pairs(extra_actions) do
        if type(action) == "function" then
            actions[key] = function()
                action(self)
            end
        end
    end

    return actions
end

local function blocked_keys_for(actions)
    local keys = {}
    for key in pairs(actions) do
        keys[#keys + 1] = key
    end
    keys[#keys + 1] = "Escape"
    return keys
end

local function build_popup(self, descriptor)
    if descriptor.build then
        return descriptor.build(self)
    end

    return self:_build_popup()
end

local function prepare_popup_opts(self, descriptor, popup_opts, anchor)
    popup_opts = popup_opts or {}
    if descriptor.prepare_opts then
        return descriptor.prepare_opts(self, popup_opts, anchor) or popup_opts
    end

    return popup_opts
end

local function geometry_providers_for(self, descriptor)
    if descriptor.geometry_providers then
        return descriptor.geometry_providers(self)
    end

    return default_geometry_providers(self, popup_key_for(descriptor))
end

local function active_state(self)
    local name = self._popup_active_name
    return name and self._popup_descriptor_state and self._popup_descriptor_state[name] or nil
end

function M.extend(instance_methods, opts)
    opts = opts or {}

    local descriptors, default_popup = normalize_descriptors(opts)
    local ignored_modifiers = opts.ignored_modifiers

    local function is_open(self, name)
        local descriptor = resolve_descriptor(descriptors, name)
        return popup_session.is_visible(self, popup_key_for(descriptor))
    end

    local function any_open(self)
        for name in pairs(descriptors) do
            if is_open(self, name) then
                return true
            end
        end

        return false
    end

    local function close_descriptor(self, name)
        local descriptor = resolve_descriptor(descriptors, name)
        if descriptor.close then
            descriptor.close(self)
        else
            popup_session.close(self, popup_key_for(descriptor))
        end
    end

    local function close_extras(self, descriptor)
        if type(opts.close_extras) == "function" then
            opts.close_extras(self)
        end

        if type(descriptor.close_extras) == "function" then
            descriptor.close_extras(self)
        end
    end

    local function open_descriptor(self, name, anchor, popup_opts)
        local descriptor = resolve_descriptor(descriptors, name)
        if descriptor.open then
            return descriptor.open(self, anchor, popup_opts)
        end

        popup_session.show(self, popup_key_for(descriptor), anchor, function()
            return build_popup(self, descriptor)
        end, popup_opts)

        if descriptor.refresh_after_open ~= false and self._refresh_popup then
            self:_refresh_popup()
        end

        return is_open(self, name)
    end

    local function sync_feedback(self)
        widget_feedback.sync(self, any_open(self))
    end

    function instance_methods:_active_popup_descriptor()
        local name = self._popup_active_name or default_popup
        return name, resolve_descriptor(descriptors, name)
    end

    function instance_methods:_handle_popup_keygrabber(_, modifiers, key, event)
        local name, descriptor = self:_active_popup_descriptor()
        local state = active_state(self) or {}
        local actions = resolve_actions(self, descriptor)
        local blocked_keys = blocked_keys_for(actions)

        local handled = popup_control.dispatch_popup_keypress({
            event = event,
            modifiers = modifiers,
            key = key,
            ignored_modifiers = ignored_modifiers,
            is_open = function()
                return is_open(self, name)
            end,
            on_not_open = function()
                self:blur_popup_keyboard_navigation()
            end,
            prev_keychain = state.prev_keychain,
            next_keychain = state.next_keychain,
            toggle_key = state.toggle_key,
            on_cycle_prev = state.on_cycle_prev,
            on_cycle_next = state.on_cycle_next,
            on_close = function()
                self:close_popup()
            end,
            actions = actions,
            blocked_global_keys = blocked_keys,
            on_global_fallback = function()
                self:close_popup()
            end,
        })

        if handled then
            return
        end
    end

    function instance_methods:focus_popup_keyboard_navigation()
        local _, descriptor = self:_active_popup_descriptor()
        local blocked_keys = blocked_keys_for(resolve_actions(self, descriptor))

        popup_control.focus_popup_keygrabber(self, {
            global_fallback = {
                blocked_keys = blocked_keys,
                before_dispatch = function()
                    self:close_popup()
                end,
            },
            handler = function(grabber, modifiers, key, event)
                self:_handle_popup_keygrabber(grabber, modifiers, key, event)
            end,
        })
    end

    function instance_methods:blur_popup_keyboard_navigation()
        popup_control.blur_popup_keygrabber(self)
    end

    function instance_methods:popup_visible(field_name)
        if field_name then
            for _, descriptor in pairs(descriptors) do
                if popup_key_for(descriptor) == field_name then
                    return popup_session.is_visible(self, field_name)
                end
            end
            return false
        end

        return any_open(self)
    end

    function instance_methods:_deactivate_popup_session()
        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()

        local _, descriptor = self:_active_popup_descriptor()
        close_extras(self, descriptor)

        self._popup_active_name = nil
        sync_feedback(self)
    end

    function instance_methods:close_named_popup(name)
        name = name or self._popup_active_name or default_popup
        local descriptor = resolve_descriptor(descriptors, name)

        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()
        close_extras(self, descriptor)
        close_descriptor(self, name)

        if self._popup_active_name == name then
            self._popup_active_name = nil
        end
        self._popup_hover_anchor_geo = nil

        sync_feedback(self)
    end

    function instance_methods:close_popup()
        self:close_named_popup(self._popup_active_name or default_popup)
    end

    function instance_methods:close_all_popups()
        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()

        for name, descriptor in pairs(descriptors) do
            close_extras(self, descriptor)
            close_descriptor(self, name)
        end

        self._popup_active_name = nil
        self._popup_hover_anchor_geo = nil
        sync_feedback(self)
    end

    function instance_methods:show_named_popup(name, anchor, popup_opts)
        local descriptor = resolve_descriptor(descriptors, name)
        popup_opts = popup_control.normalize_popup_opts(anchor, popup_opts)
        popup_opts = prepare_popup_opts(self, descriptor, popup_opts, anchor)

        self._popup_descriptor_state = self._popup_descriptor_state or {}
        self._popup_descriptor_state[name] = {
            opts = popup_opts,
            toggle_key = popup_control.normalize_popup_toggle_key(popup_opts.toggle_key, {
                ignored_modifiers = ignored_modifiers,
            }),
            prev_keychain = popup_control.normalize_popup_toggle_key(popup_opts.prev_keychain, {
                ignored_modifiers = ignored_modifiers,
            }),
            next_keychain = popup_control.normalize_popup_toggle_key(popup_opts.next_keychain, {
                ignored_modifiers = ignored_modifiers,
            }),
            on_cycle_prev = popup_opts.on_cycle_prev,
            on_cycle_next = popup_opts.on_cycle_next,
        }
        self._popup_session_opts = popup_opts
        self[descriptor.opts_key or "_popup_session_opts"] = popup_opts
        self._popup_hover_anchor_geo = is_geometry(anchor) and anchor or nil

        local visible = open_descriptor(self, name, anchor, popup_opts)
        self._popup_active_name = visible and name or nil
        sync_feedback(self)

        if not visible then
            return false
        end

        self:_start_popup_outside_click_dismiss()
        self:focus_popup_keyboard_navigation()

        if popup_opts.hover_close == true then
            self:_start_hover_close_timer(anchor)
        else
            self:_stop_hover_close_timer()
        end

        return true
    end

    function instance_methods:show_popup(anchor, popup_opts)
        self:show_named_popup(default_popup, anchor, popup_opts)
    end

    function instance_methods:_start_popup_outside_click_dismiss()
        local _, descriptor = self:_active_popup_descriptor()
        popup_control.start_outside_click_dismiss(self, {
            is_open = function()
                return any_open(self)
            end,
            geometry_providers = geometry_providers_for(self, descriptor),
            on_outside_click = function()
                self:close_popup()
            end,
        })
    end

    function instance_methods:_stop_popup_outside_click_dismiss()
        popup_control.stop_outside_click_dismiss(self)
    end

    function instance_methods:_stop_hover_close_timer()
        popup_control.stop_hover_close_timer(self)
    end

    function instance_methods:_start_hover_close_timer(anchor_geo)
        local _, descriptor = self:_active_popup_descriptor()
        local geometry_providers = geometry_providers_for(self, descriptor)
        geometry_providers[#geometry_providers + 1] = function()
            return self._popup_hover_anchor_geo
        end

        popup_control.start_hover_close_timer(self, {
            poll_interval = self.hover_close_poll_interval and self:hover_close_poll_interval() or 0.25,
            hover_timeout = self.hover_close_timeout and self:hover_close_timeout() or 1.5,
            is_open = function()
                return any_open(self)
            end,
            geometry_providers = geometry_providers,
            on_timeout = function()
                self:close_popup()
            end,
        })
    end

    function instance_methods:toggle_named_popup(name, anchor, popup_opts)
        local descriptor = resolve_descriptor(descriptors, name)
        popup_opts = popup_control.normalize_popup_opts(anchor, popup_opts)
        popup_opts = prepare_popup_opts(self, descriptor, popup_opts, anchor)

        if is_open(self, name) then
            self:close_named_popup(name)
            return false
        end

        return self:show_named_popup(name, anchor, popup_opts)
    end

    function instance_methods:toggle_popup(anchor, popup_opts)
        self:toggle_named_popup(default_popup, anchor, popup_opts)
    end
end

return M
