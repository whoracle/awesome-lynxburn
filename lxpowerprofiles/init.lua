local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxaudio.popup_common")
local util = require("lxaudio.util")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 20,
}

local ON_BATTERY_PAIR = { "powersave", "balanced" }
local ON_AC_PAIR = { "balanced", "performance" }
local ALL_PROFILES = { "powersave", "balanced", "performance" }

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

function M:_theme_value(key, fallback)
    local value = beautiful[key]
    if value == nil then
        return fallback
    end

    return value
end

function M:_power_source()
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

function M:_active_pair()
    return self.state.power_source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR
end

function M:_remembered_profile(source)
    local pair = source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR
    local remembered = self._preferred_profiles[source]

    if remembered and contains(pair, remembered) then
        return remembered
    end

    return pair[1]
end

function M:_toggle_target()
    local pair = self:_active_pair()
    local current = self.state.profile

    if current == pair[1] then
        return pair[2]
    end

    return pair[1]
end

function M:_refresh_widget()
    local fg = self:_theme_value("lxpowerprofiles_widget_fg", beautiful.fg_normal or "#ffffff")
    local source_icon = self.state.power_source == "ac" and self:_theme_value("lxpowerprofiles_icon_ac", "") or self:_theme_value("lxpowerprofiles_icon_battery", "")

    self._refs.icon.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(source_icon)
    )
    self._refs.label.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(self.state.profile or "unknown")
    )
end

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    self._popup_refs.status.markup = string.format(
        "<span foreground='%s'>Power source: %s  |  fast toggle: %s / %s</span>",
        gears.string.xml_escape(self:_theme_value("lxpowerprofiles_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(self.state.power_source),
        gears.string.xml_escape(self:_active_pair()[1]),
        gears.string.xml_escape(self:_active_pair()[2])
    )
end

function M:_build_popup()
    local status = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local list = wibox.layout.fixed.vertical()

    for _, profile in ipairs(ALL_PROFILES) do
        list:add(popup_common.make_click_row(profile, function()
            self:set_profile(profile)
        end, {
            idle_bg = self:_theme_value("lxpowerprofiles_button_bg", beautiful.bg_minimize or "#222222"),
            hover_bg = self:_theme_value("lxpowerprofiles_button_hover", beautiful.bg_focus or "#444444"),
        }))
    end

    self._popup_refs = {
        status = status,
        list = list,
    }

    self:_refresh_popup()

    return wibox.widget({
        {
            status,
            list,
            spacing = 8,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
    })
end

function M:toggle_popup(anchor)
    local visible = popup_common.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
        return self:_build_popup()
    end)

    if visible then
        self:_refresh_popup()
    end
end

function M:set_profile(profile)
    awful.spawn.easy_async_with_shell(
        "powerprofilesctl set " .. util.shell_escape(profile) .. " >/dev/null 2>&1",
        function()
            local source = self:_power_source()
            if contains(source == "ac" and ON_AC_PAIR or ON_BATTERY_PAIR, profile) then
                self._preferred_profiles[source] = profile
            end

            self:refresh()
        end
    )
end

function M:toggle()
    self:set_profile(self:_toggle_target())
end

function M:refresh()
    local source = self:_power_source()

    awful.spawn.easy_async_with_shell("powerprofilesctl get 2>/dev/null", function(stdout)
        self.state.power_source = source
        self.state.profile = util.trim(stdout or "") or self:_remembered_profile(source)
        self:_refresh_widget()
        self:_refresh_popup()
    end)
end

function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            local previous_source = self.state.power_source
            local current_source = self:_power_source()

            if previous_source and previous_source ~= current_source then
                self:set_profile(self:_remembered_profile(current_source))
                return
            end

            self:refresh()
        end,
    })
end

function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        power_source = "battery",
        profile = "powersave",
    }
    self._preferred_profiles = {
        battery = "powersave",
        ac = "balanced",
    }
    self._refs = {}

    local icon = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local label = wibox.widget({ markup = "", widget = wibox.widget.textbox })
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
            self:toggle()
        end),
        awful.button({}, 3, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
