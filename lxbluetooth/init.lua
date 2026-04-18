local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")
local config_data = require("config.config_data")

local popup_control = require("lxcommon.popup_control")
local popup_common = require("lxcommon.popup_ui")
local util = require("lxmedia.util")
local notify_util = require("lxnotify.util")
local popup_placement = require("lxcommon.popup_placement")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 15,
}

local function merge_defaults(opts)
    opts = opts or {}
    local merged = {}

    for key, value in pairs(DEFAULTS) do
        merged[key] = value
    end

    for key, value in pairs(opts) do
        merged[key] = value
    end

    return merged
end

local function bool_from_info(value)
    return value == "yes"
end

local function parse_devices(stdout)
    local devices = {}
    local seen = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local address, name = line:match("^Device%s+(%S+)%s+(.+)$")
        if address and not seen[address] then
            seen[address] = true
            devices[#devices + 1] = {
                address = address,
                name = name,
            }
        end
    end

    return devices
end

local function looks_like_mac_address(value)
    return tostring(value or ""):match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$")
end

local function parse_info(stdout)
    local info = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local key, value = line:match("^%s*([%a ]+):%s+(.+)$")
        if key and value then
            info[key] = value
        end
    end

    return {
        connected = bool_from_info(info.Connected),
        paired = bool_from_info(info.Paired),
        trusted = bool_from_info(info.Trusted),
        blocked = bool_from_info(info.Blocked),
        battery = tonumber((info.BatteryPercentage or ""):match("%((%d+)%)") or (info.BatteryPercentage or ""):match("(%d+)$")),
        icon = info.Icon,
        alias = info.Alias,
    }
end

local function sort_devices(a, b)
    if a.connected ~= b.connected then
        return a.connected
    end

    return (a.name or a.address) < (b.name or b.address)
end

local function sync_feedback_highlight(instance)
    if instance.widget and instance.widget._lx_set_feedback_active then
        instance.widget:_lx_set_feedback_active(instance._popup and instance._popup.visible or false)
    end
end

local function apply_popup_geometry(instance, popup_widget, anchor)
    local target_screen = notify_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        instance:_theme_value("lxbluetooth_popup_placement", "right"),
        { width = math.min(instance:_theme_value("lxbluetooth_popup_width", 360), target_screen.workarea.width) }
    )
end

function M:_theme_value(key, fallback)
    local value = beautiful[key]
    if value == nil then
        return fallback
    end

    return value
end

function M:_refresh_widget()
    local icon_fg = self.state.powered
        and self:_theme_value("lxbluetooth_widget_fg", beautiful.fg_normal or "#ffffff")
        or self:_theme_value("lxbluetooth_widget_disabled_fg", beautiful.fg_minimize or "#888888")

    self._refs.icon.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(icon_fg),
        gears.string.xml_escape(self:_theme_value("lxbluetooth_icon", ""))
    )

    if self._refs.label then
        self._refs.label.markup = ""
    end
end

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    local refs = self._popup_refs
    refs.list:reset()
    self._popup_items = {
        {
            on_enter = function()
                self:close_popup()
                local programs = config_data.commands()
                awful.spawn.with_shell(programs.blueman_manager)
            end,
        },
        {
            on_enter = function()
                self:toggle_power()
            end,
        },
    }

    local status = self.state.powered and "Powered" or "Disabled"
    refs.status.markup = string.format(
        "<span foreground='%s'>Bluetooth %s</span>",
        gears.string.xml_escape(self:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(status)
    )

    for _, device in ipairs(self.state.devices) do
        local prefix = device.connected and "● " or "○ "
        local suffix = {}
        if device.battery then
            suffix[#suffix + 1] = string.format("%d%%", device.battery)
        end
        local summary = device.name or device.address
        if #suffix > 0 then
            summary = string.format("%s  [%s]", summary, table.concat(suffix, ", "))
        end

        local next_index = #self._popup_items + 1
        local selected = self._popup_selected_index == next_index
        local row = popup_common.make_selectable_click_row(prefix .. summary, function()
            if device.connected then
                self:_device_action("disconnect", device.address)
            else
                self:_device_action("connect", device.address)
            end
        end, {
            selected = selected,
            inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
            hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
            outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
            selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        })

        refs.list:add(row)
        self._popup_items[#self._popup_items + 1] = {
            on_enter = function()
                if device.connected then
                    self:_device_action("disconnect", device.address)
                else
                    self:_device_action("connect", device.address)
                end
            end,
        }
    end

    if #self.state.devices == 0 then
        refs.list:add(popup_common.make_info_line(string.format(
            "<span foreground='%s'>No paired devices found.</span>",
            gears.string.xml_escape(self:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999"))
        )))
    end
end

function M:_build_popup()
    local status = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })
    local list = wibox.layout.fixed.vertical()

    self._popup_refs = {
        status = status,
        list = list,
    }

    local popup_widget = wibox.widget({
        {
            popup_common.make_selectable_click_row("Open blueman-manager", function()
                self:close_popup()
                local programs = config_data.commands()
                awful.spawn.with_shell(programs.blueman_manager)
            end, {
                selected = self._popup_selected_index == 1,
                inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            }),
            popup_common.make_selectable_click_row("Toggle controller power", function()
                self:toggle_power()
            end, {
                selected = self._popup_selected_index == 2,
                inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            }),
            status,
            list,
            spacing = 8,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    })

    self:_refresh_popup()
    return popup_widget
end

function M:hover_close_timeout()
    return self:_theme_value("lxbluetooth_hover_close_timeout", 1.5)
end

function M:hover_close_poll_interval()
    return self:_theme_value("lxbluetooth_hover_close_poll_interval", 0.25)
end

function M:_ensure_popup_selection()
    local count = #(self._popup_items or {})
    if count < 1 then
        self._popup_selected_index = 1
        return
    end

    self._popup_selected_index = math.max(1, math.min(self._popup_selected_index or 1, count))
end

function M:move_popup_selection(delta)
    self:_ensure_popup_selection()
    local count = #(self._popup_items or {})
    if count < 1 then
        return
    end

    self._popup_selected_index = math.max(1, math.min((self._popup_selected_index or 1) + delta, count))
    if self._popup and self._popup.visible then
        self._popup.widget = self:_build_popup()
    else
        self:_refresh_popup()
    end
end

function M:activate_selected_popup_item()
    self:_ensure_popup_selection()
    local item = (self._popup_items or {})[self._popup_selected_index or 1]
    if item and type(item.on_enter) == "function" then
        item.on_enter()
    end
end

function M:_handle_popup_keygrabber(_, modifiers, key, event)
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

function M:focus_popup_keyboard_navigation()
    popup_control.focus_popup_keygrabber(self, {
        handler = function(grabber, modifiers, key, event)
            self:_handle_popup_keygrabber(grabber, modifiers, key, event)
        end,
    })
end

function M:blur_popup_keyboard_navigation()
    popup_control.blur_popup_keygrabber(self)
end

function M:close_popup()
    self:_stop_hover_close_timer()
    self:_stop_popup_outside_click_dismiss()
    self:blur_popup_keyboard_navigation()
    if self._popup then
        self._popup.visible = false
    end
    sync_feedback_highlight(self)
end

function M:_start_popup_outside_click_dismiss()
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

function M:_stop_popup_outside_click_dismiss()
    popup_control.stop_outside_click_dismiss(self)
end

function M:_stop_hover_close_timer()
    popup_control.stop_hover_close_timer(self)
end

function M:_start_hover_close_timer()
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

function M:toggle_popup(anchor, opts)
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

    if not self._popup then
        self._popup = awful.popup({
            visible = false,
            ontop = true,
            type = "dock",
            bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
            widget = self:_build_popup(),
        })
    else
        self._popup.widget = self:_build_popup()
    end

    apply_popup_geometry(self, self._popup, anchor)
    self._popup.visible = true
    sync_feedback_highlight(self)
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

function M:_device_action(action, address)
    awful.spawn.easy_async_with_shell(
        string.format("bluetoothctl %s %s >/dev/null 2>&1", action, util.shell_escape(address)),
        function()
            self:refresh()
        end
    )
end

function M:toggle_power()
    local command = self.state.powered and "bluetoothctl power off" or "bluetoothctl power on"
    awful.spawn.easy_async_with_shell(command .. " >/dev/null 2>&1", function()
        self:refresh()
    end)
end

function M:refresh()
    awful.spawn.easy_async_with_shell("bluetoothctl show 2>/dev/null", function(show_stdout)
        local powered = tostring(show_stdout or ""):match("Powered:%s+(%a+)")
        local discoverable = tostring(show_stdout or ""):match("Discoverable:%s+(%a+)")

        awful.spawn.easy_async_with_shell("bluetoothctl devices Paired 2>/dev/null", function(devices_stdout)
            local devices = parse_devices(devices_stdout)
            local remaining = #devices
            local resolved = {}

            local function finalize()
                table.sort(resolved, sort_devices)
                local connected_count = 0

                for _, device in ipairs(resolved) do
                    if device.connected then
                        connected_count = connected_count + 1
                    end
                end

                self.state.powered = powered == "yes"
                self.state.discoverable = discoverable == "yes"
                self.state.devices = resolved
                self.state.connected_count = connected_count
                self:_refresh_widget()
                self:_refresh_popup()
            end

            if remaining == 0 then
                finalize()
                return
            end

            for _, device in ipairs(devices) do
                awful.spawn.easy_async_with_shell(
                    "bluetoothctl info " .. util.shell_escape(device.address) .. " 2>/dev/null",
                    function(info_stdout)
                        local info = parse_info(info_stdout)
                        local display_name = info.alias or device.name

                        if info.paired and not looks_like_mac_address(display_name) then
                            resolved[#resolved + 1] = {
                                address = device.address,
                                name = display_name,
                                connected = info.connected,
                                paired = info.paired,
                                trusted = info.trusted,
                                blocked = info.blocked,
                                battery = info.battery,
                            }
                        end

                        remaining = remaining - 1
                        if remaining == 0 then
                            finalize()
                        end
                    end
                )
            end
        end)
    end)
end

function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            self:refresh()
        end,
    })
end

function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        powered = false,
        devices = {},
        connected_count = 0,
    }
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({
        markup = "",
        font = self:_theme_value("lxbluetooth_icon_font", beautiful.font),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })
    self._refs.icon = icon

    self.widget = wibox.widget({
        {
            {
                {
                    {
                        icon,
                        halign = "center",
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    forced_width = self:_theme_value("lxbluetooth_icon_width", 16),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 2,
            right = 2,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    popup_common.attach_button_feedback(self.widget, {
        idle_bg = nil,
        hover_bg = self:_theme_value("lxbluetooth_bg_hover", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxbluetooth_bg_press", self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#666666")),
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end),
        awful.button({}, 2, function()
            self:toggle_power()
        end),
        awful.button({}, 3, function()
            local programs = config_data.commands()
            awful.spawn.with_shell(programs.blueman_manager)
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
