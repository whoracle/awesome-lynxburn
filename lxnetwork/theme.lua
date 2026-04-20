local beautiful = require("beautiful")
local gears = require("gears")

local theme = {}

---Attach theme-backed widget helpers to the lxnetwork instance method table.
function theme.extend(instance_methods)
    function instance_methods:_theme_value(key, fallback)
        local value = beautiful[key]
        if value == nil then
            return fallback
        end

        return value
    end

    function instance_methods:_refresh_widget()
        local fg = self.state.enabled
            and self:_theme_value("lxnetwork_widget_fg", beautiful.fg_normal or "#ffffff")
            or self:_theme_value("lxnetwork_widget_disabled_fg", beautiful.fg_minimize or "#888888")

        if self.state.vpn_active then
            fg = self:_theme_value("lxnetwork_widget_vpn_fg", beautiful.fg_urgent or "#d97777")
        end

        self._refs.icon.markup = string.format(
            "<span foreground='%s'>%s</span>",
            gears.string.xml_escape(fg),
            gears.string.xml_escape(self:_theme_value("lxnetwork_icon", ""))
        )

        if self._refs.label then
            self._refs.label.markup = ""
        end
    end

    function instance_methods:hover_close_timeout()
        return self:_theme_value("lxnetwork_hover_close_timeout", 1.5)
    end

    function instance_methods:hover_close_poll_interval()
        return self:_theme_value("lxnetwork_hover_close_poll_interval", 0.25)
    end
end

return theme
