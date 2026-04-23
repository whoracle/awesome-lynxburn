local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local util = require("lxcommon.util")

local M = {}

function M.extend(instance_methods)
    function instance_methods:_theme_value(key, fallback)
        local value = beautiful[key]
        if value == nil then
            return fallback
        end

        return value
    end

    function instance_methods:_widget_state_name()
        if self.state.suspended then
            return "suspended"
        end

        if self:has_attention() then
            return "attention"
        end

        return "healthy"
    end

    function instance_methods:bar_visible()
        local mode = self.opts.top_level or "always"

        if mode == "never" then
            return false
        end

        if mode == "urgent" then
            return self.state.suspended == true or self:has_attention()
        end

        return true
    end

    function instance_methods:_apply_widget_state()
        local state_name = self:_widget_state_name()
        local fg

        if state_name == "suspended" then
            fg = self:_theme_value("lxsecrets_widget_suspended_fg", beautiful.fg_minimize or "#888888")
        elseif state_name == "attention" then
            fg = self:_theme_value("lxsecrets_widget_attention_fg", beautiful.fg_critical or "#d97777")
        else
            fg = self:_theme_value("lxsecrets_widget_fg", beautiful.fg_normal or "#ffffff")
        end

        self._refs.icon.markup = string.format(
            "<span foreground='%s'>%s</span>",
            gears.string.xml_escape(fg),
            gears.string.xml_escape(self:_theme_value("lxsecrets_icon", ""))
        )

        if self.widget then
            self.widget.visible = self:bar_visible() or self:_popup_visible()
        end
    end

    function instance_methods:_popup_visible()
        return self._popup and self._popup.visible or false
    end

    function instance_methods:_build_widget()
        local icon = wibox.widget({
            markup = "",
            font = self:_theme_value("lxsecrets_icon_font", beautiful.font),
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        })
        self._refs.icon = icon

        self.widget = wibox.widget({
            {
                {
                    {
                        icon,
                        halign = "center",
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    forced_width = self:_theme_value("lxsecrets_icon_width", 22),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            widget = wibox.container.margin,
        })
        self.widget = wibox.widget({
            self.widget,
            bg = nil,
            widget = wibox.container.background,
        })

        util.attach_hover_background(
            self.widget,
            nil,
            self:_theme_value("lxsecrets_widget_hover_bg", beautiful.bg_focus or "#444444"),
            self:_theme_value("lxsecrets_widget_press_bg", beautiful.bg_focus or "#666666")
        )

        self.widget:buttons(gears.table.join(
            awful.button({}, 1, function()
                self:toggle_popup(mouse.current_widget_geometry)
            end),
            awful.button({}, 2, function()
                self:toggle_suspended()
            end),
            awful.button({}, 3, function()
                self:refresh_all()
            end)
        ))

        self:_apply_widget_state()
    end

    function instance_methods:hover_close_timeout()
        return self:_theme_value("lxsecrets_hover_close_timeout", 1.5)
    end

    function instance_methods:hover_close_poll_interval()
        return self:_theme_value("lxsecrets_hover_close_poll_interval", 0.25)
    end
end

return M
