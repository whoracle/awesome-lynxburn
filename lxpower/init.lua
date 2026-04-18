local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")

local popup_control = require("lxcommon.popup_control")
local popup_common = require("lxcommon.popup_ui")
local widget_feedback = require("lxcommon.widget_feedback")
local util = require("lxmedia.util")
local popup_placement = require("lxcommon.popup_placement")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 20,
}

local ON_BATTERY_PAIR = { "power-saver", "balanced" }
local ON_AC_PAIR = { "balanced", "performance" }
local ALL_PROFILES = { "power-saver", "balanced", "performance" }

local PROFILE_LABELS = {
    ["power-saver"] = "powersave",
    balanced = "balanced",
    performance = "performance",
}

local PROFILE_THEME_KEYS = {
    ["power-saver"] = "lxpower_profile_fg_powersave",
    balanced = "lxpower_profile_fg_balanced",
    performance = "lxpower_profile_fg_performance",
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

local function profile_label(profile)
    return PROFILE_LABELS[profile] or tostring(profile or "unknown")
end

local function trim_lower(value)
    local normalized = util.trim(value or "")
    if not normalized or normalized == "" then
        return nil
    end

    return string.lower(normalized)
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

function M:_battery_info()
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

function M:_dgpu_info()
    for _, path in ipairs(dgpu_device_paths()) do
        local vendor = trim_lower(read_trimmed(path .. "/vendor"))
        if vendor == "0x10de" then
            local runtime_status = trim_lower(read_trimmed(path .. "/power/runtime_status"))
            local power_state = trim_lower(read_trimmed(path .. "/power_state"))

            if runtime_status == "active" then
                return {
                    status = "active",
                    active = true,
                }
            end

            if runtime_status == "suspended" then
                return {
                    status = "idle",
                    active = false,
                }
            end

            if power_state == "d0" then
                return {
                    status = "active",
                    active = true,
                }
            end

            if power_state == "d3cold" or power_state == "d3hot" then
                return {
                    status = "off",
                    active = false,
                }
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
    local source_icon = self.state.power_source == "ac"
        and self:_theme_value("lxpower_icon_ac", "")
        or self:_theme_value("lxpower_icon_battery", "")
    local profile_key = PROFILE_THEME_KEYS[self.state.profile]
    local fg = profile_key and self:_theme_value(profile_key, nil)
        or self:_theme_value("lxpower_widget_fg", beautiful.fg_normal or "#ffffff")

    self._refs.icon.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(source_icon)
    )
    local compact_text = ""
    if self.state.power_source ~= "ac" and self.state.battery_status == "Discharging" then
        compact_text = self.state.time_label or ""
    end
    if self.state.pinned then
        local pin = self:_theme_value("lxpower_icon_pinned", "")
        if compact_text ~= "" then
            compact_text = pin .. " " .. compact_text
        else
            compact_text = pin
        end
    end

    self._refs.label.markup = string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(fg),
        gears.string.xml_escape(compact_text)
    )
end

function M:_refresh_popup()
    if not self._popup_refs then
        return
    end

    local meta_fg = gears.string.xml_escape(self:_theme_value("lxpower_meta_fg", beautiful.fg_minimize or "#999999"))
    local label

    if self.state.power_source == "battery" then
        label = self.state.time_label and ("Time to empty: " .. self.state.time_label) or "Time to empty: -"
    elseif self.state.battery_status == "Charging" then
        label = self.state.time_label and ("Time to full: " .. self.state.time_label) or "Time to full: -"
    else
        label = "Time to full: -"
    end

    self._popup_refs.source.markup = string.format(
        "<span foreground='%s'>Source: %s</span>",
        meta_fg,
        gears.string.xml_escape(self.state.power_source == "ac" and "AC" or "battery")
    )
    self._popup_refs.profile.markup = string.format(
        "<span foreground='%s'>Current Profile: %s</span>",
        meta_fg,
        gears.string.xml_escape(profile_label(self.state.profile))
    )
    self._popup_refs.gpu.markup = string.format(
        "<span foreground='%s'>dGPU: %s</span>",
        meta_fg,
        gears.string.xml_escape(self.state.dgpu_status or "unknown")
    )
    self._popup_refs.time.markup = string.format(
        "<span foreground='%s'>%s</span>",
        meta_fg,
        gears.string.xml_escape(label)
    )
end

function M:_build_popup()
    local source = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local profile = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local gpu = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local time = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    local status = wibox.widget({
        source,
        profile,
        gpu,
        time,
        spacing = 2,
        layout = wibox.layout.fixed.vertical,
    })
    local list = wibox.layout.fixed.vertical()
    self._popup_items = {}

    for _, profile_name in ipairs(ALL_PROFILES) do
        local selected = self._popup_selected_index == (#self._popup_items + 1)
        local label = profile_label(profile_name)
        if self.state.pinned and self.state.profile == profile_name then
            label = self:_theme_value("lxpower_icon_pinned", "") .. " " .. label
        end

        list:add(popup_common.make_selectable_click_row(label, function()
            self:set_profile(profile_name)
        end, {
            selected = selected,
            inner_bg = self:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
            hover_bg = self:_theme_value("lxpower_button_hover", beautiful.bg_focus or "#444444"),
            outer_bg = self:_theme_value("lxpower_popup_bg", beautiful.bg_normal or "#222222"),
            selected_bg = self:_theme_value("lxpower_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        }))
        self._popup_items[#self._popup_items + 1] = {
            profile = profile_name,
            on_enter = function()
                self:set_profile(profile_name)
            end,
        }
    end

    self._popup_refs = {
        status = status,
        source = source,
        profile = profile,
        gpu = gpu,
        time = time,
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

function M:hover_close_timeout()
    return self:_theme_value("lxpower_hover_close_timeout", 1.5)
end

function M:hover_close_poll_interval()
    return self:_theme_value("lxpower_hover_close_poll_interval", 0.25)
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
    end
end

function M:activate_selected_popup_item()
    self:_ensure_popup_selection()
    local item = (self._popup_items or {})[self._popup_selected_index or 1]
    if item and type(item.on_enter) == "function" then
        item.on_enter()
    end
end

function M:pin_selected_profile()
    self:_ensure_popup_selection()
    local item = (self._popup_items or {})[self._popup_selected_index or 1]
    if not (item and item.profile) then
        return
    end

    if self.state.profile == item.profile then
        self:set_pinned(true)
        return
    end

    self:set_profile(item.profile, { pin = true })
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
            Right = function()
                self:pin_selected_profile()
            end,
            Left = function()
                self:set_pinned(false)
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
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
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
    if opts.placement == nil then
        opts.placement = popup_placement.normalize(self:_theme_value("lxpower_popup_placement", "center"), "center")
    end
    opts.width = opts.width or self:_theme_value("lxpower_popup_width", 360)

    if self._popup and self._popup.visible then
        self:close_popup()
        return
    end

    self._popup_toggle_key = popup_control.normalize_popup_toggle_key(opts.toggle_key)
    self._popup_prev_keychain = popup_control.normalize_popup_toggle_key(opts.prev_keychain)
    self._popup_next_keychain = popup_control.normalize_popup_toggle_key(opts.next_keychain)
    self._popup_on_cycle_prev = opts.on_cycle_prev
    self._popup_on_cycle_next = opts.on_cycle_next

    local visible = popup_common.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
        return self:_build_popup()
    end)

    if visible then
        self:_refresh_popup()
    end
    widget_feedback.sync(self, self._popup and self._popup.visible or false)
    self:_start_popup_outside_click_dismiss()

    if opts.keyboard_navigation then
        self:_stop_hover_close_timer()
        self:focus_popup_keyboard_navigation()
    else
        self:blur_popup_keyboard_navigation()
        self:_start_hover_close_timer()
    end
end

function M:set_profile(profile, opts)
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

function M:toggle()
    self:set_profile(self:_toggle_target())
end

function M:set_pinned(pinned)
    self.state.pinned = pinned and true or false
    self:_refresh_widget()
    if self._popup and self._popup.visible then
        self._popup.widget = self:_build_popup()
    else
        self:_refresh_popup()
    end
end

function M:toggle_pin()
    self:set_pinned(not self.state.pinned)
end

function M:refresh()
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

function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            local previous_source = self.state.power_source
            local current_source = self:_power_source()

            if previous_source and previous_source ~= current_source then
                if self.state.pinned then
                    self:refresh()
                    return
                end

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
        profile = "power-saver",
        dgpu_status = "unknown",
        dgpu_active = false,
        pinned = false,
    }
    self._preferred_profiles = {
        battery = "power-saver",
        ac = "balanced",
    }
    self._preferred_profiles = normalize_preferred_profiles(opts.preferred_profiles)
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    icon.align = "center"
    icon.valign = "center"
    icon.font = self:_theme_value("lxpower_icon_font", beautiful.font)
    local label = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    label.align = "center"
    label.valign = "center"
    self._refs.icon = icon
    self._refs.label = label

    self.widget = wibox.widget({
        {
            {
                {
                    icon,
                    forced_width = self:_theme_value("lxpower_icon_width", 16),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                label,
                spacing = 8,
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
        hover_bg = self:_theme_value("lxpower_bg_hover", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxpower_bg_press", self:_theme_value("lxpower_button_hover", beautiful.bg_focus or "#666666")),
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
