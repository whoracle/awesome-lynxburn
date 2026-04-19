local awful = require("awful")
local config_data = require("config.config_data")

local util = require("lxcommon.util")

local state = {}

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

---Attach bluetooth state and command helpers to the lxbluetooth instance.
function state.extend(instance_methods)
    function instance_methods:open_manager()
        local programs = config_data.commands()
        awful.spawn.with_shell(programs.blueman_manager)
    end

    function instance_methods:_device_action(action, address)
        awful.spawn.easy_async_with_shell(
            string.format("bluetoothctl %s %s >/dev/null 2>&1", action, util.shell_escape(address)),
            function()
                self:refresh()
            end
        )
    end

    function instance_methods:toggle_power()
        local command = self.state.powered and "bluetoothctl power off" or "bluetoothctl power on"
        awful.spawn.easy_async_with_shell(command .. " >/dev/null 2>&1", function()
            self:refresh()
        end)
    end

    function instance_methods:refresh()
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
end

return state
