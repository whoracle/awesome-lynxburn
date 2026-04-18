local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")
local config_data = require("config.config_data")

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

local function normalize_popup_opts(arg1, arg2)
    if type(arg2) == "table" then
        return arg2
    end

    if type(arg1) == "table" then
        return arg1
    end

    return {}
end

local function normalize_popup_toggle_key(toggle_key)
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
            if type(modifier) == "string" and modifier ~= "" then
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

local function popup_toggle_key_matches(toggle_key, modifiers, key)
    if not toggle_key or key ~= toggle_key.key then
        return false
    end

    local active_modifiers = {}
    for _, modifier in ipairs(modifiers or {}) do
        active_modifiers[modifier] = true
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

local function point_in_geometry(x, y, geo)
    return geo
        and x >= geo.x and x < (geo.x + geo.width)
        and y >= geo.y and y < (geo.y + geo.height)
end

local function copy_button_list(buttons)
    local copied = {}

    if not buttons then
        return copied
    end

    for _, button in ipairs(buttons) do
        copied[#copied + 1] = button
    end

    return copied
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
    if event ~= "press" then
        return
    end

    if not (self._popup and self._popup.visible) then
        self:blur_popup_keyboard_navigation()
        return
    end

    if popup_toggle_key_matches(self._popup_prev_keychain, modifiers, key) and type(self._popup_on_cycle_prev) == "function" then
        self._popup_on_cycle_prev()
        return
    end

    if popup_toggle_key_matches(self._popup_next_keychain, modifiers, key) and type(self._popup_on_cycle_next) == "function" then
        self._popup_on_cycle_next()
        return
    end

    if popup_toggle_key_matches(self._popup_toggle_key, modifiers, key) or key == "Escape" then
        self:close_popup()
        return
    end

    if key == "Up" then
        self:move_popup_selection(-1)
    elseif key == "Down" then
        self:move_popup_selection(1)
    elseif key == "Return" or key == "KP_Enter" then
        self:activate_selected_popup_item()
    end
end

function M:focus_popup_keyboard_navigation()
    if not self._popup_keygrabber then
        self._popup_keygrabber = keygrabber({
            stop_callback = function()
                self._popup_keyboard_navigation_active = false
            end,
            keypressed_callback = function(grabber, modifiers, key, event)
                self:_handle_popup_keygrabber(grabber, modifiers, key, event)
            end,
        })
    end

    self._popup_keyboard_navigation_active = true

    if not self._popup_keygrabber.grabber then
        self._popup_keygrabber:start()
    end
end

function M:blur_popup_keyboard_navigation()
    self._popup_keyboard_navigation_active = false

    if self._popup_keygrabber and self._popup_keygrabber.grabber then
        self._popup_keygrabber:stop()
    end
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
    self:_stop_popup_outside_click_dismiss()

    local handler = function()
        local popup = self._popup
        if not (popup and popup.visible) then
            return
        end

        local coords = mouse.coords()
        if point_in_geometry(coords.x, coords.y, popup:geometry()) then
            return
        end

        self:close_popup()
    end

    self._popup_outside_click_handler = handler
    self._popup_outside_click_binding = awful.button({}, 1, handler)
    self._popup_saved_root_buttons = copy_button_list(root.buttons())
    local merged_root_buttons = copy_button_list(self._popup_saved_root_buttons)
    merged_root_buttons[#merged_root_buttons + 1] = self._popup_outside_click_binding
    root.buttons(merged_root_buttons)

    if client and client.connect_signal then
        client.connect_signal("button::press", self._popup_outside_click_handler)
    end

    if drawin and drawin.connect_signal then
        drawin.connect_signal("button::press", self._popup_outside_click_handler)
    end
end

function M:_stop_popup_outside_click_dismiss()
    if self._popup_outside_click_binding then
        self._popup_outside_click_binding = nil
    end

    if self._popup_saved_root_buttons then
        root.buttons(self._popup_saved_root_buttons)
        self._popup_saved_root_buttons = nil
    end

    if self._popup_outside_click_handler then
        if client and client.disconnect_signal then
            client.disconnect_signal("button::press", self._popup_outside_click_handler)
        end

        if drawin and drawin.disconnect_signal then
            drawin.disconnect_signal("button::press", self._popup_outside_click_handler)
        end

        self._popup_outside_click_handler = nil
    end
end

function M:_stop_hover_close_timer()
    if self._hover_close_timer then
        self._hover_close_timer:stop()
        self._hover_close_timer = nil
    end
end

function M:_start_hover_close_timer()
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
            local popup = self._popup
            if not (popup and popup.visible) then
                self:_stop_hover_close_timer()
                return
            end

            local coords = mouse.coords()
            local geometry = popup:geometry()
            local inside = point_in_geometry(coords.x, coords.y, geometry)

            if inside then
                outside_ticks = 0
                return
            end

            outside_ticks = outside_ticks + 1
            if outside_ticks >= max_outside_ticks then
                self:close_popup()
            end
        end,
    })
end

function M:toggle_popup(anchor, opts)
    opts = normalize_popup_opts(anchor, opts)

    if self._popup and self._popup.visible then
        self:close_popup()
        return
    end

    self._popup_toggle_key = normalize_popup_toggle_key(opts.toggle_key)
    self._popup_prev_keychain = normalize_popup_toggle_key(opts.prev_keychain)
    self._popup_next_keychain = normalize_popup_toggle_key(opts.next_keychain)
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
