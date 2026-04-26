local popup_control = require("lxcommon.popup_control")
local popup_session = require("lxcommon.popup_session")
local widget_feedback = require("lxcommon.widget_feedback")

local M = {}

local function default_is_open(self, popup_key)
    return popup_session.is_visible(self, popup_key)
end

local function default_geometry_providers(self, popup_key)
    return {
        function()
            return popup_session.geometry(self, popup_key)
        end,
    }
end

local function resolve_actions(self, opts)
    local actions = {
        Up = function()
            self:move_popup_selection(-1)
        end,
        Down = function()
            self:move_popup_selection(1)
        end,
        Return = function()
            self:activate_selected_popup_item()
        end,
        KP_Enter = function()
            self:activate_selected_popup_item()
        end,
    }

    local extra_actions = opts.actions or {}
    for key, action in pairs(extra_actions) do
        if type(action) == "function" then
            actions[key] = function()
                action(self)
            end
        end
    end

    return actions
end

function M.extend(instance_methods, opts)
    opts = opts or {}
    local popup_key = opts.popup_key or "_popup"

    local is_open = opts.is_open or function(self)
        return default_is_open(self, popup_key)
    end

    local geometry_providers = opts.geometry_providers or function(self)
        return default_geometry_providers(self, popup_key)
    end

    local close_impl = opts.close or function(self)
        popup_session.close(self, popup_key)
    end

    local open_impl = opts.open or function(self, anchor)
        popup_session.show(self, popup_key, anchor, function()
            return self:_build_popup()
        end, self._popup_session_opts or {})
        if self._refresh_popup then
            self:_refresh_popup()
        end
        return is_open(self)
    end

    local prepare_opts = opts.prepare_opts or function(_, popup_opts)
        return popup_opts
    end
    local blocked_global_keys = {}

    for key_name in pairs(resolve_actions({}, opts)) do
        blocked_global_keys[#blocked_global_keys + 1] = key_name
    end

    function instance_methods:_handle_popup_keygrabber(_, modifiers, key, event)
        local handled = popup_control.dispatch_popup_keypress({
            event = event,
            modifiers = modifiers,
            key = key,
            is_open = function()
                return is_open(self)
            end,
            on_not_open = function()
                self:blur_popup_keyboard_navigation()
            end,
            prev_keychain = self._popup_prev_keychain,
            next_keychain = self._popup_next_keychain,
            toggle_key = self._popup_toggle_key,
            on_cycle_prev = self._popup_on_cycle_prev,
            on_cycle_next = self._popup_on_cycle_next,
            on_close = function()
                self:close_popup()
            end,
            actions = resolve_actions(self, opts),
            blocked_global_keys = blocked_global_keys,
            on_global_fallback = function()
                self:close_popup()
            end,
        })

        if handled then
            return
        end
    end

    function instance_methods:focus_popup_keyboard_navigation()
        popup_control.focus_popup_keygrabber(self, {
            handler = function(grabber, modifiers, key, event)
                self:_handle_popup_keygrabber(grabber, modifiers, key, event)
            end,
        })
    end

    function instance_methods:blur_popup_keyboard_navigation()
        popup_control.blur_popup_keygrabber(self)
    end

    function instance_methods:popup_visible()
        return is_open(self)
    end

    function instance_methods:_deactivate_popup_session()
        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()
        if type(opts.close_extras) == "function" then
            opts.close_extras(self)
        end
        widget_feedback.sync(self, false)
    end

    function instance_methods:close_popup()
        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()
        if type(opts.close_extras) == "function" then
            opts.close_extras(self)
        end
        close_impl(self)
        widget_feedback.sync(self, is_open(self))
    end

    function instance_methods:_start_popup_outside_click_dismiss()
        popup_control.start_outside_click_dismiss(self, {
            is_open = function()
                return is_open(self)
            end,
            geometry_providers = geometry_providers(self),
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

    function instance_methods:_start_hover_close_timer()
        popup_control.start_hover_close_timer(self, {
            poll_interval = self:hover_close_poll_interval(),
            hover_timeout = self:hover_close_timeout(),
            is_open = function()
                return is_open(self)
            end,
            geometry_providers = geometry_providers(self),
            on_timeout = function()
                self:close_popup()
            end,
        })
    end

    function instance_methods:toggle_popup(anchor, popup_opts)
        popup_opts = popup_control.normalize_popup_opts(anchor, popup_opts)
        popup_opts = prepare_opts(self, popup_opts) or popup_opts
        self._popup_session_opts = popup_opts

        if is_open(self) then
            self:close_popup()
            return
        end

        self._popup_toggle_key = popup_control.normalize_popup_toggle_key(popup_opts.toggle_key)
        self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(popup_opts.prev_keychain)
        self._popup_next_keychain = popup_control.normalize_popup_toggle_key(popup_opts.next_keychain)
        self._popup_on_cycle_prev = popup_opts.on_cycle_prev
        self._popup_on_cycle_next = popup_opts.on_cycle_next

        local visible = open_impl(self, anchor, popup_opts)
        widget_feedback.sync(self, is_open(self))

        if not visible then
            return
        end

        self:_start_popup_outside_click_dismiss()

        self:focus_popup_keyboard_navigation()

        if popup_opts.hover_close == true then
            self:_start_hover_close_timer()
        else
            self:_stop_hover_close_timer()
        end
    end
end

return M
