local beautiful = require("beautiful")

local popup_control = require("lxcommon.popup_control")
local popup_placement = require("lxcommon.popup_placement")
local popup_session = require("lxcommon.popup_session")
local widget_feedback = require("lxcommon.widget_feedback")

local M = {}

local function is_geometry(value)
    return type(value) == "table" and value.x and value.y and value.width and value.height
end

local function normalize_popup_args(anchor_geo, opts)
    if type(anchor_geo) == "table" and not is_geometry(anchor_geo) and opts == nil then
        return nil, anchor_geo
    end

    return anchor_geo, opts or {}
end

---Attach popup show/toggle/close flow helpers to the lxmedia instance.
function M.extend(instance_methods)
    function instance_methods:_start_devices_popup_outside_click_dismiss()
        popup_control.start_outside_click_dismiss(self, {
            binding_key = "_devices_popup_outside_click_binding",
            saved_root_buttons_key = "_devices_popup_saved_root_buttons",
            handler_key = "_devices_popup_outside_click_handler",
            is_open = function()
                return self._devices_popup and self._devices_popup.visible or false
            end,
            geometry_providers = {
                function()
                    return self._devices_popup and self._devices_popup:geometry() or nil
                end,
            },
            on_outside_click = function()
                self:close_popups()
            end,
        })
    end

    function instance_methods:_stop_devices_popup_outside_click_dismiss()
        popup_control.stop_outside_click_dismiss(self, {
            binding_key = "_devices_popup_outside_click_binding",
            saved_root_buttons_key = "_devices_popup_saved_root_buttons",
            handler_key = "_devices_popup_outside_click_handler",
        })
    end

    function instance_methods:_handle_devices_popup_keygrabber(_, modifiers, key, event)
        local handled = self:_handle_devices_popup_navigation_key(modifiers, key, event)

        if handled then
            return
        end
    end

    function instance_methods:focus_devices_popup_keyboard_navigation()
        popup_control.focus_popup_keygrabber(self, {
            grabber_key = "_devices_popup_keygrabber",
            active_key = "_devices_popup_keyboard_navigation_active",
            handler = function(grabber, modifiers, key, event)
                self:_handle_devices_popup_keygrabber(grabber, modifiers, key, event)
            end,
            on_start = function()
                self:_start_devices_popup_outside_click_dismiss()
            end,
        })
    end

    function instance_methods:blur_devices_popup_keyboard_navigation()
        self._devices_popup_keyboard_navigation_active = false
        self._devices_popup_toggle_key = nil
        self._devices_popup_prev_keychain = nil
        self._devices_popup_next_keychain = nil
        self._devices_popup_on_cycle_prev = nil
        self._devices_popup_on_cycle_next = nil
        self:_stop_devices_popup_outside_click_dismiss()
        popup_control.blur_popup_keygrabber(self, {
            grabber_key = "_devices_popup_keygrabber",
            active_key = "_devices_popup_keyboard_navigation_active",
        })
    end

    function instance_methods:_start_media_popup_outside_click_dismiss()
        popup_control.start_outside_click_dismiss(self, {
            binding_key = "_media_popup_outside_click_binding",
            saved_root_buttons_key = "_media_popup_saved_root_buttons",
            handler_key = "_media_popup_outside_click_handler",
            is_open = function()
                return self._media_popup and self._media_popup.visible or false
            end,
            geometry_providers = {
                function()
                    return self._media_popup and self._media_popup:geometry() or nil
                end,
            },
            on_outside_click = function()
                self:close_popups()
            end,
        })
    end

    function instance_methods:_stop_media_popup_outside_click_dismiss()
        popup_control.stop_outside_click_dismiss(self, {
            binding_key = "_media_popup_outside_click_binding",
            saved_root_buttons_key = "_media_popup_saved_root_buttons",
            handler_key = "_media_popup_outside_click_handler",
        })
    end

    function instance_methods:toggle_media_popup(anchor_geo, opts)
        anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
        if opts.hover_close == nil then
            opts.hover_close = false
        end
        if opts.anchor == nil then
            opts.anchor = anchor_geo and "widget" or "center"
        end

        return self:_toggle_popup("media", anchor_geo, opts)
    end

    function instance_methods:toggle_devices_popup(anchor_geo, opts)
        anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
        if opts.hover_close == nil then
            opts.hover_close = false
        end
        if opts.anchor == nil then
            opts.anchor = anchor_geo and "widget" or "center"
        end

        return self:_toggle_popup("devices", anchor_geo, opts)
    end

    function instance_methods:show_media_popup(anchor_geo, opts)
        anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
        if opts.anchor == nil then
            opts.anchor = anchor_geo and "widget" or "center"
        end
        self:_show_popup("media", anchor_geo, opts)
    end

    function instance_methods:show_devices_popup(anchor_geo, opts)
        anchor_geo, opts = normalize_popup_args(anchor_geo, opts)
        if opts.anchor == nil then
            opts.anchor = anchor_geo and "widget" or "center"
        end
        self:_show_popup("devices", anchor_geo, opts)
    end

    function instance_methods:_toggle_popup(kind, anchor_geo, opts)
        opts = opts or {}
        if opts.placement == nil then
            local theme_key = kind == "media" and "lxmedia_popup_placement_media" or "lxmedia_popup_placement_devices"
            opts.placement = popup_placement.normalize(beautiful[theme_key], "center")
        end
        opts.bg = opts.bg or beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222"
        opts.width = opts.width
            or (kind == "media" and beautiful.lxmedia_popup_width_media)
            or beautiful.lxmedia_popup_width_devices
            or 360

        local popup_ref = kind == "media" and "_media_popup" or "_devices_popup"
        if popup_session.is_visible(self, popup_ref) then
            self:close_popups()
            return false
        end

        local popup_module
        if kind == "media" then
            popup_module = require("lxmedia.popup_media")
        else
            popup_module = require("lxmedia.popup_devices")
        end

        popup_session.show(self, popup_ref, anchor_geo, function()
            return popup_module.build(self)
        end, opts)

        local shown = popup_session.is_visible(self, popup_ref)
        if shown then
            if kind == "media" then
                self._media_popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
                self._media_popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
                self._media_popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
                self._media_popup_on_cycle_prev = opts.on_cycle_prev
                self._media_popup_on_cycle_next = opts.on_cycle_next
                self:blur_devices_popup_keyboard_navigation()
                self:focus_media_popup_keyboard_navigation()
            else
                self._devices_popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
                self._devices_popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
                self._devices_popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
                self._devices_popup_on_cycle_prev = opts.on_cycle_prev
                self._devices_popup_on_cycle_next = opts.on_cycle_next
                self:blur_media_popup_keyboard_navigation()
                self:focus_devices_popup_keyboard_navigation()
            end

            if opts.hover_close == false then
                self:_stop_hover_close_timer()
            else
                self:_start_hover_close_timer(kind, is_geometry(anchor_geo) and anchor_geo or nil)
            end
        else
            if kind == "media" then
                self:blur_media_popup_keyboard_navigation()
            else
                self:blur_devices_popup_keyboard_navigation()
            end
            self:_stop_hover_close_timer()
        end

        self:_sync_toplevel_bar_visibility()

        return shown
    end

    function instance_methods:_show_popup(kind, anchor_geo, opts)
        opts = opts or {}
        if opts.placement == nil then
            local theme_key = kind == "media" and "lxmedia_popup_placement_media" or "lxmedia_popup_placement_devices"
            opts.placement = popup_placement.normalize(beautiful[theme_key], "center")
        end
        opts.bg = opts.bg or beautiful.lxmedia_popup_bg or beautiful.bg_normal or "#222222"
        opts.width = opts.width
            or (kind == "media" and beautiful.lxmedia_popup_width_media)
            or beautiful.lxmedia_popup_width_devices
            or 360

        local popup_module
        local popup_ref
        if kind == "media" then
            popup_module = require("lxmedia.popup_media")
            popup_ref = "_media_popup"
        else
            popup_module = require("lxmedia.popup_devices")
            popup_ref = "_devices_popup"
        end

        popup_session.show(self, popup_ref, anchor_geo, function()
            return popup_module.build(self)
        end, opts)

        if kind == "media" then
            self._media_popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
            self._media_popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
            self._media_popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
            self._media_popup_on_cycle_prev = opts.on_cycle_prev
            self._media_popup_on_cycle_next = opts.on_cycle_next
            self:blur_devices_popup_keyboard_navigation()
            self:focus_media_popup_keyboard_navigation()
        else
            self._devices_popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
            self._devices_popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
            self._devices_popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
            self._devices_popup_on_cycle_prev = opts.on_cycle_prev
            self._devices_popup_on_cycle_next = opts.on_cycle_next
            self:blur_media_popup_keyboard_navigation()
            self:focus_devices_popup_keyboard_navigation()
        end

        if opts.hover_close == false then
            self:_stop_hover_close_timer()
        else
            self:_start_hover_close_timer(kind, is_geometry(anchor_geo) and anchor_geo or nil)
        end

        self:_sync_toplevel_bar_visibility()
    end

    function instance_methods:_stop_hover_close_timer()
        popup_control.stop_hover_close_timer(self)
    end

    -- Close a popup only after the pointer leaves both the popup and its anchor
    -- for a configurable amount of time.
    function instance_methods:_start_hover_close_timer(kind, anchor_geo)
        local poll_interval = beautiful.lxmedia_hover_close_poll_interval or 0.25
        local hover_timeout = beautiful.lxmedia_hover_close_timeout or 1.5

        self._hover_close_kind = kind
        self._hover_close_anchor_geo = anchor_geo

        popup_control.start_hover_close_timer(self, {
            poll_interval = poll_interval,
            hover_timeout = hover_timeout,
            is_open = function()
                local popup = nil
                if self._hover_close_kind == "media" then
                    popup = self._media_popup
                elseif self._hover_close_kind == "devices" then
                    popup = self._devices_popup
                end
                return popup and popup.visible or false
            end,
            geometry_providers = {
                function()
                    local popup = nil
                    if self._hover_close_kind == "media" then
                        popup = self._media_popup
                    elseif self._hover_close_kind == "devices" then
                        popup = self._devices_popup
                    end
                    return popup and popup:geometry() or nil
                end,
                function()
                    return self._hover_close_anchor_geo
                end,
            },
            on_timeout = function()
                local popup = nil
                if self._hover_close_kind == "media" then
                    popup = self._media_popup
                elseif self._hover_close_kind == "devices" then
                    popup = self._devices_popup
                end

                if popup then
                    popup.visible = false
                end
                self:_stop_hover_close_timer()
                self:_sync_toplevel_bar_visibility()
            end,
        })
    end

    function instance_methods:close_popups()
        self:_stop_hover_close_timer()
        self:blur_media_popup_keyboard_navigation()
        self:blur_devices_popup_keyboard_navigation()

        popup_session.close(self, "_media_popup")
        popup_session.close(self, "_devices_popup")

        self:_sync_toplevel_bar_visibility()
        widget_feedback.sync(self, function()
            return self:popup_visible()
        end)
    end

    function instance_methods:_deactivate_popup_session()
        self:_stop_hover_close_timer()
        self:blur_media_popup_keyboard_navigation()
        self:blur_devices_popup_keyboard_navigation()
        self:_sync_toplevel_bar_visibility()
        widget_feedback.sync(self, false)
    end

    function instance_methods:popup_visible(field_name)
        if field_name == "_media_popup" then
            return popup_session.is_visible(self, "_media_popup")
        end

        if field_name == "_devices_popup" then
            return popup_session.is_visible(self, "_devices_popup")
        end

        return popup_session.is_visible(self, "_media_popup")
            or popup_session.is_visible(self, "_devices_popup")
    end
end

return M
