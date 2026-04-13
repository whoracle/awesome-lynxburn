local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxaudio.popup_common")
local util = require("lxaudio.util")

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

    for _, line in ipairs(util.split_lines(stdout)) do
        local address, name = line:match("^Device%s+(%S+)%s+(.+)$")
        if address then
            devices[#devices + 1] = {
                address = address,
                name = name,
            }
        end
    end

    return devices
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

    local label = "BT off"
    if self.state.powered then
        local connected = self.state.connected_count or 0
        if connected > 0 then
            label = string.format("BT %d", connected)
        else
            label = "BT on"
        end
    end

    self._refs.label.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(icon_fg),
        gears.string.xml_escape(label)
    )
end

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    local refs = self._popup_refs
    refs.list:reset()

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
        if device.trusted then
            suffix[#suffix + 1] = "trusted"
        end

        local summary = device.name or device.address
        if #suffix > 0 then
            summary = string.format("%s  [%s]", summary, table.concat(suffix, ", "))
        end

        local row = popup_common.make_click_row(prefix .. summary, function()
            if device.connected then
                self:_device_action("disconnect", device.address)
            else
                self:_device_action("connect", device.address)
            end
        end, {
            idle_bg = self:_theme_value("lxbluetooth_button_bg", beautiful.bg_minimize or "#222222"),
            hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
        })

        refs.list:add(row)
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
            popup_common.make_click_row("Open blueman-manager", function()
                local programs = require("config.programs")
                awful.spawn.with_shell(programs.blueman_manager)
            end, {
                idle_bg = self:_theme_value("lxbluetooth_button_bg", beautiful.bg_minimize or "#222222"),
                hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
            }),
            popup_common.make_click_row("Toggle controller power", function()
                self:toggle_power()
            end, {
                idle_bg = self:_theme_value("lxbluetooth_button_bg", beautiful.bg_minimize or "#222222"),
                hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
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

function M:toggle_popup(anchor)
    local visible = popup_common.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
        return self:_build_popup()
    end)

    if visible then
        self:_refresh_popup()
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
                        resolved[#resolved + 1] = {
                            address = device.address,
                            name = info.alias or device.name,
                            connected = info.connected,
                            paired = info.paired,
                            trusted = info.trusted,
                            blocked = info.blocked,
                            battery = info.battery,
                        }

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
    self._refs = {}

    local icon = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })
    local label = wibox.widget({
        markup = "",
        widget = wibox.widget.textbox,
    })

    self._refs.icon = icon
    self._refs.label = label

    self.widget = wibox.widget({
        {
            icon,
            label,
            spacing = 6,
            layout = wibox.layout.fixed.horizontal,
        },
        left = 8,
        right = 8,
        widget = wibox.container.margin,
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end),
        awful.button({}, 2, function()
            self:toggle_power()
        end),
        awful.button({}, 3, function()
            local programs = require("config.programs")
            awful.spawn.with_shell(programs.blueman_manager)
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
