local beautiful = require("beautiful")
local gears = require("gears")

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

local theme = {}

---Attach theme-backed widget helpers to the lxpower instance method table.
function theme.extend(instance_methods)
    function instance_methods:_theme_value(key, fallback)
        local value = beautiful[key]
        if value == nil then
            return fallback
        end

        return value
    end

    function instance_methods:profile_label(profile)
        return PROFILE_LABELS[profile] or tostring(profile or "unknown")
    end

    function instance_methods:_refresh_widget()
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

    function instance_methods:hover_close_timeout()
        return self:_theme_value("lxpower_hover_close_timeout", 1.5)
    end

    function instance_methods:hover_close_poll_interval()
        return self:_theme_value("lxpower_hover_close_poll_interval", 0.25)
    end
end

return theme
