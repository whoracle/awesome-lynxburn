local awful = require("awful")
local gears = require("gears")
local popup_control = require("lxcommon.popup_control")
local widget_feedback = require("lxcommon.widget_feedback")

local popup = require("lxnotify.popup")

local controller = {}

local IGNORED_POPUP_MODIFIERS = {
    Lock = true,
    Mod2 = true,
    Mod3 = true,
    Mod5 = true,
}

---Pick the screen context that should own a newly opened lxnotify popup.
local function current_target_screen_context()
    if mouse and mouse.current_widget_geometry then
        local geometry = mouse.current_widget_geometry
        if geometry then
            return geometry
        end
    end

    return { screen = awful.screen.focused() }
end

---Attach popup session-control methods to the lxnotify instance method table.
function controller.extend(instance_methods)
    function instance_methods:_handle_popup_keygrabber(_, modifiers, key, event)
        local handled = popup_control.dispatch_popup_keypress({
            event = event,
            modifiers = modifiers,
            key = key,
            ignored_modifiers = IGNORED_POPUP_MODIFIERS,
            is_open = function()
                return self._popup and self._popup.visible or false
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
                self:close_popups()
            end,
            actions = {
                Up = function()
                    self:move_popup_selection(-1)
                end,
                Down = function()
                    self:move_popup_selection(1)
                end,
                Right = function()
                    self:activate_selected_popup_right()
                end,
                Return = function()
                    self:activate_selected_popup_enter()
                end,
                KP_Enter = function()
                    self:activate_selected_popup_enter()
                end,
                Left = function()
                    if self.active_group_key then
                        self:leave_group_detail()
                    else
                        self:close_popups()
                    end
                end,
            },
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
            on_start = function()
                self:_start_popup_outside_click_dismiss()
            end,
        })
    end

    function instance_methods:set_popup_toggle_key(toggle_key)
        self._popup_toggle_key = popup_control.normalize_popup_toggle_key(toggle_key, {
            ignored_modifiers = IGNORED_POPUP_MODIFIERS,
        })
    end

    function instance_methods:blur_popup_keyboard_navigation()
        self._popup_keyboard_navigation_active = false
        self._popup_prev_keychain = nil
        self._popup_next_keychain = nil
        self._popup_on_cycle_prev = nil
        self._popup_on_cycle_next = nil
        self:_stop_popup_outside_click_dismiss()
        popup_control.blur_popup_keygrabber(self)
    end

    function instance_methods:_start_popup_outside_click_dismiss()
        popup_control.start_outside_click_dismiss(self, {
            is_open = function()
                return self._popup and self._popup.visible or false
            end,
            geometry_providers = {
                function()
                    return self._popup and self._popup:geometry() or nil
                end,
            },
            on_outside_click = function()
                self:close_popups()
            end,
        })
    end

    function instance_methods:_stop_popup_outside_click_dismiss()
        popup_control.stop_outside_click_dismiss(self)
    end

    function instance_methods:_apply_popup_keyboard_opts(opts)
        self:set_popup_toggle_key(opts.toggle_key)
        self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain, {
            ignored_modifiers = IGNORED_POPUP_MODIFIERS,
        })
        self._popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain, {
            ignored_modifiers = IGNORED_POPUP_MODIFIERS,
        })
        self._popup_on_cycle_prev = opts.on_cycle_prev
        self._popup_on_cycle_next = opts.on_cycle_next

        if opts.hover_close == false then
            self:_stop_hover_close_timer()
            self:focus_popup_keyboard_navigation()
        else
            self:focus_popup_keyboard_navigation()
            self:_start_hover_close_timer()
        end
    end

    function instance_methods:_stop_hover_close_timer()
        if self._hover_close_timer then
            self._hover_close_timer:stop()
            self._hover_close_timer = nil
        end
    end

    ---Start the grace-period hover-close timer used for mouse-driven popup sessions.
    function instance_methods:_start_hover_close_timer()
        self:_stop_hover_close_timer()

        local outside_ticks = 0
        local poll_interval = self:hover_close_poll_interval()
        local hover_timeout = self:hover_close_timeout()
        local max_outside_ticks = math.max(1, math.floor((hover_timeout / poll_interval) + 0.5))

        self._hover_close_timer = gears.timer({
            timeout = poll_interval,
            autostart = true,
            call_now = false,
            callback = function()
                local popup_widget = self._popup
                if not (popup_widget and popup_widget.visible) then
                    self:_stop_hover_close_timer()
                    return
                end

                local mouse_coords = mouse.coords()
                local geometry = popup_widget:geometry()
                local inside_popup =
                    mouse_coords.x >= geometry.x and mouse_coords.x < (geometry.x + geometry.width) and
                    mouse_coords.y >= geometry.y and mouse_coords.y < (geometry.y + geometry.height)

                if inside_popup then
                    outside_ticks = 0
                    return
                end

                outside_ticks = outside_ticks + 1
                if outside_ticks >= max_outside_ticks then
                    popup.hide(self)
                    self:_stop_hover_close_timer()
                    widget_feedback.sync(self, self._popup and self._popup.visible or false)
                end
            end,
        })
    end

    ---Hide the lxnotify popup and stop any hover-close timer.
    function instance_methods:close_popups()
        self:_stop_hover_close_timer()
        self:blur_popup_keyboard_navigation()
        popup.hide(self)
        widget_feedback.sync(self, self._popup and self._popup.visible or false)
    end

    ---Open the popup explicitly, optionally disabling hover-close for keyboard use.
    function instance_methods:show_notification_popup(arg1, arg2)
        local opts = popup_control.normalize_popup_opts(arg1, arg2)
        if opts.hover_close == nil then
            opts.hover_close = true
        end

        popup.show(self, current_target_screen_context())
        self:_apply_popup_keyboard_opts(opts)
        widget_feedback.sync(self, self._popup and self._popup.visible or false)
    end

    ---Toggle the popup, with keyboard-friendly control over hover-close behavior.
    function instance_methods:toggle_notification_popup(arg1, arg2)
        local opts = popup_control.normalize_popup_opts(arg1, arg2)
        if opts.hover_close == nil then
            opts.hover_close = true
        end

        local was_visible = self._popup and self._popup.visible
        popup.toggle(self, current_target_screen_context())

        if self._popup and self._popup.visible and not was_visible then
            self:_apply_popup_keyboard_opts(opts)
        else
            self:_stop_hover_close_timer()
            self:blur_popup_keyboard_navigation()
        end

        widget_feedback.sync(self, self._popup and self._popup.visible or false)
    end
end

return controller
