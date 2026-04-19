local awful = require("awful")

local util = require("lxmedia.util")

local state = {}

local function split_nmcli_fields(line)
    local fields = {}
    local current = {}
    local escaped = false

    for index = 1, #line do
        local char = line:sub(index, index)

        if escaped then
            current[#current + 1] = char
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif char == ":" then
            fields[#fields + 1] = table.concat(current)
            current = {}
        else
            current[#current + 1] = char
        end
    end

    fields[#fields + 1] = table.concat(current)
    return fields
end

local function parse_wifi_list(stdout)
    local networks = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local active = fields[1]
        local ssid = fields[2]
        local bssid = fields[3]
        local security = fields[4]
        local signal = fields[5]
        local rate = fields[6]

        if bssid then
            networks[#networks + 1] = {
                active = active == "*",
                ssid = ssid ~= "" and ssid or "<hidden>",
                bssid = bssid,
                security = security,
                signal = tonumber(signal) or 0,
                rate = rate,
            }
        end
    end

    return networks
end

local function infer_wifi_standard(rate_text)
    local mbps = tonumber(tostring(rate_text or ""):match("([%d%.]+)%s*Mbit/s"))
    if not mbps then
        return nil
    end

    if mbps >= 1000 then
        return "WiFi 6"
    end

    if mbps >= 400 then
        return "WiFi 5"
    end

    if mbps >= 100 then
        return "WiFi 4"
    end

    return nil
end

local function parse_known_connections(stdout)
    local known = {}

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local name = fields[1]
        local kind = fields[2]
        if name and kind == "802-11-wireless" then
            known[name] = true
        end
    end

    return known
end

local function parse_active_connection(stdout)
    local current = {
        ssid = nil,
        uuid = nil,
    }

    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local name = fields[1]
        local kind = fields[2]
        if name and kind == "802-11-wireless" then
            current.ssid = name
            break
        end
    end

    return current
end

local function has_active_vpn(stdout)
    for _, line in ipairs(util.split_lines(stdout)) do
        local fields = split_nmcli_fields(line)
        local kind = fields[2]
        if kind == "vpn" then
            return true
        end
    end

    return false
end

local function sort_networks(a, b)
    if a.known ~= b.known then
        return a.known
    end

    if a.active ~= b.active then
        return a.active
    end

    if a.signal ~= b.signal then
        return a.signal > b.signal
    end

    return a.ssid < b.ssid
end

local function current_network_entry(instance)
    local current_ssid = instance.state.current_ssid
    if not current_ssid or current_ssid == "" then
        return nil
    end

    local best_match = nil

    for _, network in ipairs(instance.state.networks or {}) do
        if network.ssid == current_ssid then
            if not best_match or network.signal > best_match.signal then
                best_match = network
            end
        end
    end

    if best_match then
        local current = {}
        for key, value in pairs(best_match) do
            current[key] = value
        end
        current.active = false
        return current
    end

    return {
        ssid = current_ssid,
        signal = 0,
        standard = nil,
    }
end

---Attach nmcli parsing and connection-state methods to the lxnetwork instance.
function state.extend(instance_methods)
    function instance_methods:current_network_entry()
        return current_network_entry(self)
    end

    function instance_methods:_refresh_connection_state(callback)
        awful.spawn.easy_async_with_shell("nmcli radio wifi 2>/dev/null", function(radio_stdout)
            local enabled = tostring(radio_stdout or ""):match("enabled") ~= nil

            awful.spawn.easy_async_with_shell(
                "nmcli -t -e yes -f NAME,TYPE connection show --active 2>/dev/null",
                function(active_stdout)
                    local active = parse_active_connection(active_stdout)
                    local vpn_active = has_active_vpn(active_stdout)

                    awful.spawn.easy_async_with_shell(
                        "nmcli -t -e yes -f NAME,TYPE connection show 2>/dev/null",
                        function(known_stdout)
                            local known = parse_known_connections(known_stdout)

                            self.state.enabled = enabled
                            self.state.current_ssid = active.ssid
                            self.state.vpn_active = vpn_active

                            if callback then
                                callback(known)
                            else
                                self:_refresh_widget()
                                self:_refresh_popup()
                            end
                        end
                    )
                end
            )
        end)
    end

    function instance_methods:_connect_network(network)
        if network.known or network.security == "" or network.security == "--" then
            local target = network.bssid ~= "" and network.bssid or network.ssid
            local command = string.format(
                "nmcli device wifi connect %s >/dev/null 2>&1",
                util.shell_escape(target)
            )

            awful.spawn.easy_async_with_shell(command, function()
                self:refresh()
            end)
            return
        end

        self:_show_password_prompt(network)
    end

    function instance_methods:set_wifi_enabled(enabled)
        local desired = enabled and "on" or "off"

        awful.spawn.easy_async_with_shell("nmcli radio wifi " .. desired .. " >/dev/null 2>&1", function()
            if not enabled then
                self.state.networks = {}
                self.state.current_ssid = nil
                self.state.scan_in_progress = false
            end

            self:refresh()
        end)
    end

    function instance_methods:toggle_wifi_enabled()
        self:set_wifi_enabled(not self.state.enabled)
    end

    function instance_methods:scan()
        self.state.scan_in_progress = true
        self.state.networks = {}
        self:_refresh_popup()

        self:_refresh_connection_state(function(known)
            awful.spawn.easy_async_with_shell(
                "nmcli -t -e yes -f IN-USE,SSID,BSSID,SECURITY,SIGNAL,RATE device wifi list --rescan yes 2>/dev/null",
                function(list_stdout)
                    local networks = parse_wifi_list(list_stdout)
                    local deduped = {}

                    for _, network in ipairs(networks) do
                        network.known = known[network.ssid] == true
                        network.standard = infer_wifi_standard(network.rate)

                        local key = network.ssid .. "\0" .. (network.standard or "")
                        local existing = deduped[key]

                        if not existing or network.signal > existing.signal then
                            deduped[key] = network
                        end
                    end

                    local ordered = {}
                    for _, network in pairs(deduped) do
                        ordered[#ordered + 1] = network
                    end

                    table.sort(ordered, sort_networks)

                    self.state.networks = ordered
                    self.state.scan_in_progress = false
                    self:_refresh_widget()
                    self:_refresh_popup()
                end
            )
        end)
    end

    function instance_methods:refresh()
        self:_refresh_connection_state()
    end
end

return state
