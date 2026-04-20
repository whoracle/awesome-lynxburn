local beautiful = require("beautiful")
local wibox = require("wibox")

local common = require("lxcommon")
local helpers = require("lxdisplay.helpers")

local theme = {}

local function hover_open_delay()
    return tonumber(beautiful.lxdisplay_bar_hover_open_delay) or 1
end

---Attach widget and OSD helpers to the lxdisplay instance method table.
function theme.extend(instance_methods)
    ---Show the shared OSD widget with the current brightness percentage.
    function instance_methods:_show_brightness_osd(percent)
        local value = helpers.clamp(percent, 0, 100)
        self._osd:show_progress({
            value = value,
            icon = beautiful.lxdisplay_icon_brightness
                or beautiful.lxmedia_icon_brightness
                or "󰃠",
            app_name = "Brightness OSD",
            color = beautiful.lxdisplay_osd_bar_fg
                or beautiful.lxdisplay_bar_fg
                or beautiful.lxmedia_bar_fg
                or beautiful.fg_normal
                or "#ffffff",
        })
    end

    ---Refresh the top-level widget icon, tint, and compact bar state.
    function instance_methods:_update_widget(percent)
        local value = helpers.clamp(percent, 0, 100)
        local scheduled_temperature = self:_scheduled_redshift_temperature()
        local is_night = scheduled_temperature < self:_default_redshift_temperature()
        local active_icon = is_night
            and (beautiful.lxdisplay_icon_night or "󰖔 ")
            or (beautiful.lxdisplay_icon or beautiful.lxdisplay_icon_brightness or "󰃟")
        local active_fg = beautiful.lxdisplay_widget_fg or beautiful.fg_normal or "#ffffff"
        local suspended_fg = beautiful.lxdisplay_widget_suspended_fg
            or beautiful.fg_minimize
            or "#888888"

        self._brightness_value = value
        self._icon_text.text = active_icon
        self._icon_role.fg = self._redshift_suspended and suspended_fg or active_fg

        if self._bar then
            self._bar.value = value
            self._bar.color = beautiful.lxdisplay_bar_fg
                or beautiful.lxmedia_bar_fg
                or beautiful.fg_normal
                or "#ffffff"
        end

        self:_sync_toplevel_bar_visibility()
    end

    ---Keep the interface aligned with the shared popup API even though lxdisplay has none.
    function instance_methods:_has_visible_popup()
        return false
    end

    ---Only reveal the compact bar while hovered.
    function instance_methods:_sync_toplevel_bar_visibility()
        if not self._bar_slot then
            return
        end

        local visible = (self._widget_hovered == true) or self:_has_visible_popup()
        self._bar_slot.visible = visible
        if self._bar_margin then
            self._bar_margin.visible = visible
        end
    end

    ---Update suspended state and repaint widget colors immediately.
    function instance_methods:_set_redshift_suspended(suspended)
        self._redshift_suspended = suspended and true or false
        self:_update_widget(self._brightness_value or 0)
    end

    ---Build the top-level widget shown in the bar.
    function instance_methods:_build_widget()
        self._icon_text = wibox.widget({
            text = beautiful.lxdisplay_icon or beautiful.lxdisplay_icon_brightness or "󰃟",
            font = beautiful.lxdisplay_icon_font or beautiful.font,
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        })
        local icon_slot = wibox.widget({
            {
                self._icon_text,
                halign = "center",
                valign = "center",
                widget = wibox.container.place,
            },
            forced_width = beautiful.lxdisplay_icon_width or 20,
            strategy = "exact",
            widget = wibox.container.constraint,
        })
        self._icon_role = wibox.widget({
            icon_slot,
            fg = beautiful.lxdisplay_widget_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.container.background,
        })

        local content = {
            self._icon_role,
            layout = wibox.layout.fixed.horizontal,
        }

        self._bar = wibox.widget({
            max_value = 100,
            value = 0,
            forced_width = beautiful.lxdisplay_bar_width or 40,
            forced_height = beautiful.lxdisplay_bar_height or 8,
            paddings = 0,
            border_width = 0,
            background_color = beautiful.lxdisplay_bar_bg
                or beautiful.lxmedia_bar_bg
                or beautiful.bg_minimize
                or "#444444",
            color = beautiful.lxdisplay_bar_fg
                or beautiful.lxmedia_bar_fg
                or beautiful.fg_normal
                or "#ffffff",
            widget = wibox.widget.progressbar,
        })

        self._bar_slot = wibox.widget({
            self._bar,
            valign = "center",
            widget = wibox.container.place,
        })

        self._bar_margin = wibox.widget({
            self._bar_slot,
            left = beautiful.lxdisplay_bar_spacing or 8,
            widget = wibox.container.margin,
        })
        table.insert(content, 2, self._bar_margin)

        local row = wibox.widget({
            content,
            widget = wibox.container.margin,
        })
        local shell = wibox.widget({
            row,
            widget = wibox.container.background,
        })
        common.util.attach_hover_background(
            shell,
            nil,
            beautiful.lxdisplay_widget_hover_bg or beautiful.bg_focus or "#444444",
            beautiful.lxdisplay_widget_press_bg or beautiful.lxmedia_button_hover or beautiful.bg_focus or "#666666"
        )
        self:_attach_mouse_controls(shell)

        shell:connect_signal("mouse::enter", function()
            common.util.start_delayed_hover(self, {
                delay = hover_open_delay(),
                on_change = function()
                    self:_sync_toplevel_bar_visibility()
                end,
            })
        end)

        shell:connect_signal("mouse::leave", function()
            common.util.stop_delayed_hover(self, {
                on_change = function()
                    self:_sync_toplevel_bar_visibility()
                end,
            })
        end)

        self._row = shell
        self.widget:set_widget(shell)
        self:_sync_toplevel_bar_visibility()
    end

    ---Build the shared OSD instance unless the module config disables it.
    function instance_methods:_build_osd()
        if self._opts.enable_osd == false then
            self._osd = nil
            return
        end

        self._osd = common.osd.new({
            width = self._opts.osd_width or beautiful.lxdisplay_osd_width or 260,
            height = self._opts.osd_height or beautiful.lxdisplay_osd_height or 18,
            margin = self._opts.osd_margin or beautiful.lxdisplay_osd_margin or 16,
            timeout = beautiful.lxdisplay_osd_timeout or 1,
            bar_bg = beautiful.lxdisplay_osd_bar_bg
                or beautiful.lxdisplay_bar_bg
                or beautiful.lxmedia_bar_bg
                or beautiful.bg_minimize
                or "#444444",
            bar_fg = beautiful.lxdisplay_osd_bar_fg
                or beautiful.lxdisplay_bar_fg
                or beautiful.lxmedia_bar_fg
                or beautiful.fg_normal
                or "#ffffff",
        })
    end
end

return theme
