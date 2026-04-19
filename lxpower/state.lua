local awful = require("awful")

local util = require("lxmedia.util")

local state = {}

local ON_BATTERY_PAIR = { "power-saver", "balanced" }
local ON_AC_PAIR = { "balanced", "performance" }
local ALL_PROFILES = { "power-saver", "balanced", "performance" }

local function first_existing_path(paths)
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            return path
        end
    end

    return nil
end

local function first_existing_battery_path()
    local handle = io.popen("ls -1d /sys/class/power_supply/BAT* 2>/dev/null")
    if not handle then
        return nil
    end

    local path = handle:read("*l")
    handle:close()
    return path
end

local function dgpu_device_paths()
    local handle = io.popen("ls -1d /sys/class/drm/card*/device 2>/dev/null")
    if not handle then
        return {}
    end

    local paths = {}
    for line in handle:lines() do
        paths[#paths + 1] = line
    end
    handle:close()

    return paths
end

local function read_trimmed(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local value = file:read("*a")
    file:close()
    return util.trim(value or "")
end

local function contains(list, target)
    for _, item in ipairs(list) do
        if item == target then
            return true
        end
    end

    return false
end

local function normalize_preferred_profile(profile, fallback)
    if type(profile) == "string" and contains(ALL_PROFILES, profile) then
        return profile
    end

    return fallback
end

local function normalize_preferred_profiles(preferred_profiles)
    preferred_profiles = type(preferred_profiles) == "table" and preferred_profiles or {}

    return {
        battery = normalize_preferred_profile(preferred_profiles.battery, "power-saver"),
        ac = normalize_preferred_profile(preferred_profiles.ac, "balanced"),
    }
end

local function format_duration_hours(hours)
    local numeric = tonumber(hours)
    if not numeric or numeric <= 0 then
        return nil
    end

    local total_minutes = math.floor((numeric * 60) + 0.5)
    local hh = math.floor(total_minutes / 60)
    local mm = total_minutes % 60
    return string.format("%d:%02d", hh, mm)
end

local function trim_lower(value)
    local normalized = util.trim(value or "")
    if not normalized or normalized == "" then
        return nil
    end

    return string.lower(normalized)
end

---Attach power-state and profile-management helpers to the lxpower instance.
function state.extend(instance_methods)
    function instance_methods:all_profiles()
        return ALL_PROFILES
    end

    function instance_methods:normalize_preferred_profiles(preferred_profiles)
        return normalize_preferred_profiles(preferred_profiles)
    end

    function instance_methods:_power_source()
        local ac_path = first_existing_path({
            "/sys/class/power_supply/AC/online",
            "/sys/class/power_supply/ACAD/online",
            "/sys/class/power_supply/AC0/online",
            "/sys/class/power_supply/ADP0/online",
        })

        if ac_path then
            local value = read_trimmed(ac_path)
            if value == "1" then
                return "ac"
            end
        end

        return "battery"
    end

    function instance_methods:_battery_info()
        local battery_path = first_existing_battery_path()
        if not battery_path then
            return nil
        end

        local status = read_trimmed(battery_path .. "/status")
        local power_now = tonumber(read_trimmed(battery_path .. "/power_now") or read_trimmed(battery_path .. "/current_now"))
        local energy_now = tonumber(read_trimmed(battery_path .. "/energy_now") or read_trimmed(battery_path .. "/charge_now"))
        local energy_full = tonumber(read_trimmed(battery_path .. "/energy_full") or read_trimmed(battery_path .. "/charge_full"))
        local percentage = tonumber(read_trimmed(battery_path .. "/capacity"))

        local time_label = nil
        local direct_empty = tonumber(read_trimmed(battery_path .. "/time_to_empty_now"))
        local direct_full = tonumber(read_trimmed(battery_path .. "/time_to_full_now"))

        if status == "Discharging" then
            if direct_empty and direct_empty > 0 then
                time_label = format_duration_hours(direct_empty / 3600)
            elseif power_now and power_now > 0 and energy_now and energy_now > 0 then
                time_label = format_duration_hours(energy_now / power_now)
            end
        elseif status == "Charging" then
            if direct_full and direct_full > 0 then
                time_label = format_duration_hours(direct_full / 3600)
            elseif power_now and power_now > 0 and energy_now and energy_full and energy_full > energy_now then
                time_label = format_duration_hours((energy_full - energy_now) / power_now)
            end
        end

        return {
            status = status,
            percentage = percentage,
            time_label = time_label,
        }
    end

    function instance_methods:_dgpu_info()
        for _, path in ipairs(dgpu_device_paths()) do
            local vendor = trim_lower(read_trimmed(path .. "/vendor"))
            if vendor == "0x10de" then
                local runtime_status = trim_lower(read_trimmed(path .. "/power/runtime_status"))
                local power_state = trim_lower(read_trimmed(path .. "/power_state"))

                if runtime_status == "active" then
                    return { status = "active", active = true }
                end

                if runtime_status == "suspended" then
                    return { status = "idle", active = false }
                end

                if power_state == "d0" then
                    return { status = "active", active = true }
                end

                if power_state == "d3cold" or power_state == "d3hot" then
                    return { status = "off", active = false }
                end

                return {
                    status = runtime_status or power_state or "unknown",
                    active = runtime_status == "active" or power_state == "d0",
                }
            end
        end

        return {
            status = "unknown",
            active = false,
        }
    end

    function instance_methods:_active_pair()
        return self.state.power_source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR
    end

    function instance_methods:_remembered_profile(source)
        local pair = source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR
        local remembered = self._preferred_profiles[source]

        if remembered and contains(pair, remembered) then
            return remembered
        end

        return pair[1]
    end

    function instance_methods:_toggle_target()
        local pair = self:_active_pair()
        local current = self.state.profile

        if current == pair[1] then
            return pair[2]
        end

        return pair[1]
    end

    function instance_methods:set_profile(profile, opts)
        opts = opts or {}

        self.state.profile = profile
        if opts.pin then
            self.state.pinned = true
        end
        self:_refresh_widget()
        if self._popup and self._popup.visible then
            self._popup.widget = self:_build_popup()
        else
            self:_refresh_popup()
        end

        awful.spawn.easy_async_with_shell(
            "powerprofilesctl set " .. util.shell_escape(profile) .. " >/dev/null 2>&1",
            function()
                local source = self:_power_source()
                if contains(source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR, profile) then
                    self._preferred_profiles[source] = profile
                end

                if opts.pin then
                    self.state.pinned = true
                end

                self:refresh()
            end
        )
    end

    function instance_methods:toggle()
        self:set_profile(self:_toggle_target())
    end

    function instance_methods:set_pinned(pinned)
        self.state.pinned = pinned and true or false
        self:_refresh_widget()
        if self._popup and self._popup.visible then
            self._popup.widget = self:_build_popup()
        else
            self:_refresh_popup()
        end
    end

    function instance_methods:toggle_pin()
        self:set_pinned(not self.state.pinned)
    end

    function instance_methods:refresh()
        local source = self:_power_source()
        local battery_info = self:_battery_info() or {}
        local dgpu_info = self:_dgpu_info()

        awful.spawn.easy_async_with_shell("powerprofilesctl get 2>/dev/null", function(stdout)
            self.state.power_source = source
            self.state.profile = util.trim(stdout or "") or self:_remembered_profile(source)
            self.state.battery_status = battery_info.status
            self.state.battery_percentage = battery_info.percentage
            self.state.time_label = battery_info.time_label
            self.state.dgpu_status = dgpu_info.status
            self.state.dgpu_active = dgpu_info.active
            self:_refresh_widget()
            self:_refresh_popup()
        end)
    end
end

return state
