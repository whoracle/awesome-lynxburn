local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local keygrabber = require("awful.keygrabber")

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
    self._popup_items = {}

    for _, profile in ipairs(ALL_PROFILES) do
        local selected = self._popup_selected_index == (#self._popup_items + 1)
        list:add(popup_common.make_click_row(profile, function()
            self:set_profile(profile)
        end, {
            idle_bg = selected
                and self:_theme_value("lxpowerprofiles_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666")
                or self:_theme_value("lxpowerprofiles_button_bg", beautiful.bg_minimize or "#222222"),
            hover_bg = self:_theme_value("lxpowerprofiles_button_hover", beautiful.bg_focus or "#444444"),
        }))
        self._popup_items[#self._popup_items + 1] = {
            on_enter = function()
                self:set_profile(profile)
            end,
        }
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

function M:hover_close_timeout()
    return self:_theme_value("lxpowerprofiles_hover_close_timeout", 1.5)
end

function M:hover_close_poll_interval()
    return self:_theme_value("lxpowerprofiles_hover_close_poll_interval", 0.25)
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

function M:_handle_popup_keygrabber(_, modifiers, key, event)
    if event ~= "press" then
        return
    end

    if not (self._popup and self._popup.visible) then
        self:blur_popup_keyboard_navigation()
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
            if point_in_geometry(coords.x, coords.y, popup:geometry()) then
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

    local visible = popup_common.toggle_popup(self, "_popup", "_popup_anchor", anchor, function()
        return self:_build_popup()
    end)

    if visible then
        self:_refresh_popup()
    end
    self:_start_popup_outside_click_dismiss()

    if opts.keyboard_navigation then
        self:_stop_hover_close_timer()
        self:focus_popup_keyboard_navigation()
    else
        self:blur_popup_keyboard_navigation()
        self:_start_hover_close_timer()
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
    self._popup_selected_index = 1
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
