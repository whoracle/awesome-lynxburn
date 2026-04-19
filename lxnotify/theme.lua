local awful = require("awful")
local beautiful = require("beautiful")

local popup = require("lxnotify.popup")
local util = require("lxcommon.util")

local theme = {}

---Attach theme-backed instance helpers to the lxnotify instance method table.
function theme.extend(instance_methods)
    function instance_methods:popup_width()
        return util.theme_value("lxnotify_popup_width", 360)
    end

    function instance_methods:popup_placement()
        return require("lxcommon.popup_placement").normalize(
            util.theme_value("lxnotify_popup_placement", "side"),
            "side"
        )
    end

    function instance_methods:popup_bg()
        return util.theme_value("lxnotify_popup_bg", beautiful.bg_normal or "#333333")
    end

    function instance_methods:notification_card_bg()
        return util.theme_value("lxnotify_notification_card_bg", beautiful.bg_minimize or "#222222")
    end

    function instance_methods:notification_meta_fg()
        return util.theme_value("lxnotify_notification_meta_fg", beautiful.fg_minimize or beautiful.fg_normal or "#999999")
    end

    function instance_methods:notification_hover_bg()
        return util.theme_value("lxnotify_card_hover_bg", beautiful.bg_focus or beautiful.bg_minimize or "#333333")
    end

    function instance_methods:notification_selected_bg()
        return util.theme_value("lxnotify_selected_bg", beautiful.border_focus or beautiful.fg_focus or beautiful.fg_normal or "#ffffff")
    end

    function instance_methods:button_bg()
        return util.theme_value("lxnotify_button_bg", beautiful.bg_minimize or "#222222")
    end

    function instance_methods:button_hover_bg()
        return util.theme_value("lxnotify_button_hover", beautiful.bg_focus or beautiful.bg_minimize or "#333333")
    end

    function instance_methods:hover_close_timeout()
        return util.theme_value("lxnotify_hover_close_timeout", 1.5)
    end

    function instance_methods:hover_close_poll_interval()
        return util.theme_value("lxnotify_hover_close_poll_interval", 0.25)
    end

    function instance_methods:notification_title_max_length()
        if self.notification_title_limit ~= nil then
            return self.notification_title_limit
        end

        return util.theme_value("lxnotify_notification_title_max_length", 72)
    end

    function instance_methods:notification_body_max_length()
        if self.notification_body_limit ~= nil then
            return self.notification_body_limit
        end

        return util.theme_value("lxnotify_notification_body_max_length", 140)
    end

    function instance_methods:notification_source_max_length()
        if self.notification_source_limit ~= nil then
            return self.notification_source_limit
        end

        return util.theme_value("lxnotify_notification_source_max_length", 28)
    end

    function instance_methods:notification_time_format()
        if self.notification_time_format_string ~= nil then
            return self.notification_time_format_string
        end

        return util.theme_value("lxnotify_notification_time_format", "%H:%M")
    end

    function instance_methods:notification_icon_size()
        return util.theme_value("lxnotify_notification_icon_size", beautiful.notification_icon_size or 32)
    end

    function instance_methods:notification_group_icon_size()
        return util.theme_value("lxnotify_group_icon_size", beautiful.notification_icon_size or 20)
    end

    function instance_methods:popup_visible_items()
        if self.popup_visible_item_count ~= nil then
            return self.popup_visible_item_count
        end

        return util.theme_value("lxnotify_popup_visible_items", 7)
    end

    function instance_methods:_widget_text()
        local icon = self.suspended
            and util.theme_value("lxnotify_icon_suspended", "off")
            or util.theme_value("lxnotify_icon_idle", "idle")
        local fg

        if self.unread_count > 0 then
            fg = util.theme_value("lxnotify_urgency_critical_fg", beautiful.fg_urgent or "#d97777")
        elseif self.interception_paused then
            fg = util.theme_value("lxnotify_widget_suspended_fg", beautiful.fg_minimize or beautiful.fg_normal or "#888888")
        else
            fg = util.theme_value("lxnotify_widget_fg", beautiful.fg_normal or "#ffffff")
        end

        return string.format("<span foreground='%s'>%s</span>", fg, icon)
    end

    function instance_methods:refresh()
        self._widget_refs.text.markup = self:_widget_text()
        self:refresh_popup()
    end

    ---Refresh state and re-apply popup geometry if the popup is currently visible.
    function instance_methods:reload()
        self:refresh()

        if self._popup and self._popup.visible then
            popup.show(self, { screen = self._popup.screen or awful.screen.focused() })
        end
    end
end

return theme
