local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}
M.__index = M

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function parse_percent(stdout)
    return tonumber(tostring(stdout or ""):match("(%d+%.?%d*)")) or 0
end

function M:_show_brightness_osd(percent)
    if self._osd.hide_timer then
        self._osd.hide_timer:stop()
        self._osd.hide_timer = nil
    end

    local value = clamp(percent, 0, 100)
    self._osd.icon.text = beautiful.lxdisplay_icon_brightness
        or beautiful.lxaudio_icon_brightness
        or "󰃠"
    self._osd.bar.value = value
    self._osd.bar.color = beautiful.lxdisplay_osd_bar_fg
        or beautiful.lxdisplay_bar_fg
        or beautiful.fg_normal
        or "#ffffff"
    self._osd.popup.screen = awful.screen.focused()
    self._osd.popup.visible = true

    self._osd.hide_timer = gears.timer.start_new(self._osd.timeout, function()
        self._osd.popup.visible = false
        self._osd.hide_timer = nil
        return false
    end)
end

function M:_update_widget(percent)
    local value = clamp(percent, 0, 100)

    self._brightness_value = value
    self._icon.text = beautiful.lxdisplay_icon or beautiful.lxdisplay_icon_brightness or "󰃟"

    if self._bar then
        self._bar.value = value
        self._bar.color = beautiful.lxdisplay_bar_fg or beautiful.fg_normal or "#ffffff"
    end
end

function M:_refresh_from_command(callback)
    awful.spawn.easy_async_with_shell(self._commands.get, function(stdout)
        local value = parse_percent(stdout)
        self:_update_widget(value)

        if callback then
            callback(value)
        end
    end)
end

function M:brightness_refresh(options)
    options = options or {}

    self:_refresh_from_command(function(value)
        if options.show_osd then
            self:_show_brightness_osd(value)
        end
    end)
end

function M:_set_brightness(value, options)
    options = options or {}

    local target = clamp(
        value,
        self._commands.min or 0,
        self._commands.max or 100
    )
    local command = string.format(self._commands.set, target)

    awful.spawn.easy_async_with_shell(command, function()
        self:brightness_refresh({ show_osd = options.show_osd })
    end)
end

function M:_step_brightness(delta, options)
    options = options or {}

    self:_refresh_from_command(function(current)
        self:_set_brightness(current + delta, options)
    end)
end

function M:brightness_up(_, options)
    self:_step_brightness(self._commands.step, options)
end

function M:brightness_down(_, options)
    self:_step_brightness(-self._commands.step, options)
end

function M:brightness_off()
    awful.spawn.easy_async_with_shell(self._commands.off, function() end)
end

function M:_attach_mouse_controls(widget)
    widget:buttons(gears.table.join(
        awful.button({}, 2, function()
            if self.redshift_toggle then
                self:redshift_toggle()
            end
        end),
        awful.button({}, 4, function()
            self:brightness_up(nil, { show_osd = false })
        end),
        awful.button({}, 5, function()
            self:brightness_down(nil, { show_osd = false })
        end)
    ))
end

function M:_build_widget()
    self._icon = wibox.widget({
        text = beautiful.lxdisplay_icon or beautiful.lxdisplay_icon_brightness or "󰃟",
        fg = beautiful.lxdisplay_widget_fg or beautiful.fg_normal or "#ffffff",
        font = beautiful.lxdisplay_icon_font or beautiful.font,
        widget = wibox.widget.textbox,
    })

    local content = {
        self._icon,
        layout = wibox.layout.fixed.horizontal,
    }

    if beautiful.lxdisplay_show_bar ~= false then
        self._bar = wibox.widget({
            max_value = 100,
            value = 0,
            forced_width = beautiful.lxdisplay_bar_width or 40,
            forced_height = beautiful.lxdisplay_bar_height or 8,
            paddings = 0,
            border_width = 0,
            background_color = beautiful.lxdisplay_bar_bg or beautiful.bg_minimize or "#444444",
            color = beautiful.lxdisplay_bar_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.widget.progressbar,
        })

        table.insert(content, 2, {
            {
                self._bar,
                valign = "center",
                widget = wibox.container.place,
            },
            left = beautiful.lxdisplay_bar_spacing or 8,
            widget = wibox.container.margin,
        })
    else
        self._bar = nil
    end

    local row = wibox.widget(content)
    self:_attach_mouse_controls(row)

    self._row = row
    self.widget:set_widget(row)
end

function M:_build_osd()
    local width = beautiful.lxdisplay_osd_width or 260
    local height = beautiful.lxdisplay_osd_height or 18
    local margin = beautiful.lxdisplay_osd_margin or 16

    self._osd = {
        timeout = beautiful.lxdisplay_osd_timeout or 1,
        hide_timer = nil,
        icon = wibox.widget({
            align = "center",
            valign = "center",
            forced_width = 32,
            widget = wibox.widget.textbox,
        }),
        bar = wibox.widget({
            max_value = 100,
            value = 0,
            forced_width = width,
            forced_height = height,
            shape = gears.shape.rounded_bar,
            bar_shape = gears.shape.rounded_bar,
            background_color = beautiful.lxdisplay_osd_bar_bg or beautiful.bg_minimize or "#444444",
            color = beautiful.lxdisplay_osd_bar_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.widget.progressbar,
        }),
    }

    self._osd.popup = awful.popup({
        ontop = true,
        visible = false,
        type = "notification",
        placement = function(c)
            awful.placement.bottom(c, {
                honor_workarea = true,
                margins = { bottom = beautiful.lxdisplay_osd_screen_margin or 60 },
            })
        end,
        bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
        border_width = beautiful.notification_border_width or beautiful.border_width or 1,
        border_color = beautiful.notification_border_color or beautiful.border_focus or "#666666",
        widget = {
            {
                {
                    self._osd.icon,
                    {
                        self._osd.bar,
                        widget = wibox.container.place,
                    },
                    spacing = 12,
                    layout = wibox.layout.fixed.horizontal,
                },
                margins = margin,
                widget = wibox.container.margin,
            },
            bg = beautiful.notification_bg or beautiful.bg_normal or "#111111",
            fg = beautiful.notification_fg or beautiful.fg_normal or "#ffffff",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        },
    })
end

function M:_start_refresh_timer()
    self._refresh_timer = gears.timer({
        timeout = beautiful.lxdisplay_refresh_interval or 15,
        autostart = true,
        call_now = true,
        callback = function()
            self:brightness_refresh({ show_osd = false })
        end,
    })
end

function M.new(commands)
    local self = setmetatable({}, M)

    self._commands = {
        get = commands.get,
        set = commands.set,
        step = commands.step or 5,
        min = commands.min or 10,
        max = commands.max or 100,
        off = commands.off,
    }

    self.widget = wibox.container.place()
    self:_build_widget()
    self:_build_osd()
    self:_start_refresh_timer()

    return self
end

return M
