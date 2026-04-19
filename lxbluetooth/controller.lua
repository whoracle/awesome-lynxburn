local popup_control = require("lxcommon.popup_control")
local widget_feedback = require("lxcommon.widget_feedback")

local controller = {}

---Attach popup session-control methods to the lxbluetooth instance method table.
function controller.extend(instance_methods)
    function instance_methods:_handle_popup_keygrabber(_, modifiers, key, event)
        local handled = popup_control.dispatch_popup_keypress({
            event = event,
            modifiers = modifiers,
            key = key,
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
                self:close_popup()
            end,
            actions = {
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
        })
    end

    function instance_methods:blur_popup_keyboard_navigation()
        popup_control.blur_popup_keygrabber(self)
    end

    function instance_methods:close_popup()
        self:_stop_hover_close_timer()
        self:_stop_popup_outside_click_dismiss()
        self:blur_popup_keyboard_navigation()
        if self._popup then
            self._popup.visible = false
        end
        widget_feedback.sync(self, self._popup and self._popup.visible or false)
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
                return self._popup and self._popup.visible or false
            end,
            geometry_providers = {
                function()
                    return self._popup and self._popup:geometry() or nil
                end,
            },
            on_timeout = function()
                self:close_popup()
            end,
        })
    end

    function instance_methods:toggle_popup(anchor, opts)
        opts = popup_control.normalize_popup_opts(anchor, opts)

        if self._popup and self._popup.visible then
            self:close_popup()
            return
        end

        self._popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
        self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
        self._popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
        self._popup_on_cycle_prev = opts.on_cycle_prev
        self._popup_on_cycle_next = opts.on_cycle_next

        self:_ensure_popup(anchor)
        self._popup.visible = true
        widget_feedback.sync(self, self._popup and self._popup.visible or false)
        self:_refresh_popup()
        self:_start_popup_outside_click_dismiss()

        if opts.keyboard_navigation then
            self:_stop_hover_close_timer()
            self:focus_popup_keyboard_navigation()
        else
            self:blur_popup_keyboard_navigation()
            self:_start_hover_close_timer()
        end
    end
end

return controller
