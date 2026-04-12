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

local function shell_join(parts)
    local filtered = {}

    for _, part in ipairs(parts) do
        if part and part ~= "" then
            filtered[#filtered + 1] = part
        end
    end

    return table.concat(filtered, " ")
end

local function shell_chain(parts)
    local filtered = {}

    for _, part in ipairs(parts) do
        if part and part ~= "" then
            filtered[#filtered + 1] = part
        end
    end

    return table.concat(filtered, " ; ")
end

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function parse_redshift_temperature(output)
    return tonumber(tostring(output or ""):match("Color temperature:%s*(%d+)K"))
end

local function theme_flag(value, default)
    if value == nil then
        return default
    end

    if value == false or value == 0 or value == "0" or value == "false" then
        return false
    end

    return true
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
    self._icon.fg = self._redshift_suspended
        and (beautiful.lxdisplay_widget_suspended_fg or beautiful.fg_minimize or "#888888")
        or (beautiful.lxdisplay_widget_fg or beautiful.fg_normal or "#ffffff")

    if self._bar then
        self._bar.value = value
        self._bar.color = beautiful.lxdisplay_bar_fg or beautiful.fg_normal or "#ffffff"
    end
end

function M:_redshift_base_command()
    local cfg = self._redshift
    local args = { cfg.command or "redshift" }

    if cfg.method and cfg.method ~= "" then
        args[#args + 1] = string.format("-m %s", tostring(cfg.method))
    end

    if cfg.latitude and cfg.longitude then
        args[#args + 1] = string.format("-l %s:%s", tostring(cfg.latitude), tostring(cfg.longitude))
    end

    if cfg.temperature_day and cfg.temperature_night then
        args[#args + 1] = string.format("-t %s:%s", tostring(cfg.temperature_day), tostring(cfg.temperature_night))
    end

    return shell_join(args)
end

function M:_redshift_print_command()
    return shell_join({
        self:_redshift_base_command(),
        "-p",
    })
end

function M:_redshift_kill_command()
    local name = self._redshift.command_name or self._redshift.command or "redshift"
    return string.format("pkill -x %s 2>/dev/null || true", name)
end

function M:_redshift_reset_command()
    return shell_join({
        self._redshift.command or "redshift",
        self._redshift.method and self._redshift.method ~= "" and string.format("-m %s", tostring(self._redshift.method)) or nil,
        "-x >/dev/null 2>&1 || true",
    })
end

function M:_redshift_override_command(temperature)
    return shell_join({
        self._redshift.command or "redshift",
        self._redshift.method and self._redshift.method ~= "" and string.format("-m %s", tostring(self._redshift.method)) or nil,
        string.format("-O %d >/dev/null 2>&1 || true", temperature),
    })
end

function M:_redshift_start_command()
    return self:_redshift_base_command()
end

function M:_spawn_redshift_process()
    awful.spawn.with_shell(self:_redshift_start_command())
end

function M:_set_redshift_suspended(suspended)
    self._redshift_suspended = suspended and true or false
    self:_update_widget(self._brightness_value or 0)
end

function M:_default_redshift_temperature()
    return self._redshift.temperature_day or 6500
end

function M:_query_redshift_target_temperature(callback)
    awful.spawn.easy_async_with_shell(self:_redshift_print_command(), function(stdout)
        local temperature = parse_redshift_temperature(stdout) or self._redshift_temperature or self:_default_redshift_temperature()
        callback(temperature)
    end)
end

function M:_stop_redshift_transition()
    if self._redshift_transition_timer then
        self._redshift_transition_timer:stop()
        self._redshift_transition_timer = nil
    end
end

function M:_run_redshift_transition(from_temp, to_temp, on_done)
    self:_stop_redshift_transition()

    local steps = math.max(1, tonumber(self._redshift.transition_steps) or 8)
    local interval = tonumber(self._redshift.transition_interval) or 0.05
    local step_index = 0

    local function apply_step()
        step_index = step_index + 1

        local progress = step_index / steps
        local temperature = math.floor(lerp(from_temp, to_temp, progress) + 0.5)

        awful.spawn.with_shell(self:_redshift_override_command(temperature))
        self._redshift_temperature = temperature

        if step_index >= steps then
            self:_stop_redshift_transition()
            if on_done then
                on_done()
            end
        end
    end

    apply_step()

    if steps == 1 then
        return
    end

    self._redshift_transition_timer = gears.timer({
        timeout = interval,
        autostart = true,
        callback = apply_step,
    })
end

function M:redshift_resume()
    if not self._redshift.enabled then
        return
    end

    self:_stop_redshift_transition()
    self:_query_redshift_target_temperature(function(target)
        local start = self:_default_redshift_temperature()

        awful.spawn.easy_async_with_shell(shell_chain({
            self:_redshift_kill_command(),
            self:_redshift_reset_command(),
        }), function()
            self:_run_redshift_transition(start, target, function()
                self:_spawn_redshift_process()
                self._redshift_temperature = target
                self:_set_redshift_suspended(false)
            end)
        end)
    end)
end

function M:redshift_suspend()
    local start = self._redshift_temperature or self:_default_redshift_temperature()
    local target = self:_default_redshift_temperature()

    self:_stop_redshift_transition()
    awful.spawn.easy_async_with_shell(self:_redshift_kill_command(), function()
        self:_run_redshift_transition(start, target, function()
            awful.spawn.easy_async_with_shell(self:_redshift_reset_command(), function()
                self._redshift_temperature = target
                self:_set_redshift_suspended(true)
            end)
        end)
    end)
end

function M:redshift_toggle()
    if self._redshift_suspended then
        self:redshift_resume()
    else
        self:redshift_suspend()
    end
end

function M:_initialize_redshift()
    self._redshift_temperature = self:_default_redshift_temperature()

    if self._redshift.autostart and self._redshift.enabled then
        self:_query_redshift_target_temperature(function(target)
            awful.spawn.easy_async_with_shell(shell_chain({
                self:_redshift_kill_command(),
                self:_redshift_reset_command(),
            }), function()
                self:_spawn_redshift_process()
                self._redshift_temperature = target
                self:_set_redshift_suspended(false)
            end)
        end)
    else
        awful.spawn.easy_async_with_shell(shell_chain({
            self:_redshift_kill_command(),
            self:_redshift_reset_command(),
        }), function()
            self:_set_redshift_suspended(true)
        end)
    end
end

function M:redshift_suspend_immediate()
    self:_stop_redshift_transition()
    awful.spawn.easy_async_with_shell(shell_chain({
        self:_redshift_kill_command(),
        self:_redshift_reset_command(),
    }), function()
        self._redshift_temperature = self:_default_redshift_temperature()
        self:_set_redshift_suspended(true)
    end)
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

    if theme_flag(beautiful.lxdisplay_show_bar, true) then
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
        get = commands.brightness.get,
        set = commands.brightness.set,
        step = commands.brightness.step or 5,
        min = commands.brightness.min or 10,
        max = commands.brightness.max or 100,
        off = commands.brightness.off,
    }
    self._redshift = {
        command = commands.redshift.command or "redshift",
        command_name = commands.redshift.command_name,
        method = commands.redshift.method or "randr",
        enabled = commands.redshift.enabled ~= false,
        autostart = commands.redshift.autostart ~= false,
        latitude = commands.redshift.latitude,
        longitude = commands.redshift.longitude,
        temperature_day = commands.redshift.temperature_day,
        temperature_night = commands.redshift.temperature_night,
        transition_steps = commands.redshift.transition_steps or 8,
        transition_interval = commands.redshift.transition_interval or 0.05,
    }
    self._redshift_suspended = not self._redshift.autostart

    self.widget = wibox.container.place()
    self:_build_widget()
    self:_build_osd()
    self:_start_refresh_timer()
    self:_initialize_redshift()

    return self
end

return M
