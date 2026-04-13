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

local function lerp(a, b, t)
    return a + ((b - a) * t)
end

local function round(value)
    return math.floor(value + 0.5)
end

local function normalize_degrees(value)
    local normalized = value % 360

    if normalized < 0 then
        normalized = normalized + 360
    end

    return normalized
end

local function parse_connected_outputs(stdout)
    local outputs = {}

    for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
        local output = line:match("^(%S+)%s+connected%s")

        if output then
            outputs[#outputs + 1] = output
        end
    end

    return outputs
end

local function format_gamma(value)
    return string.format("%.4f", clamp(value, 0.0001, 1))
end

local function temperature_to_gamma(temperature)
    local kelvin = clamp(tonumber(temperature) or 6500, 1000, 40000) / 100
    local red
    local green
    local blue

    if kelvin <= 66 then
        red = 255
    else
        red = 329.698727446 * ((kelvin - 60) ^ -0.1332047592)
    end

    if kelvin <= 66 then
        green = 99.4708025861 * math.log(kelvin) - 161.1195681661
    else
        green = 288.1221695283 * ((kelvin - 60) ^ -0.0755148492)
    end

    if kelvin >= 66 then
        blue = 255
    elseif kelvin <= 19 then
        blue = 0
    else
        blue = 138.5177312231 * math.log(kelvin - 10) - 305.0447927307
    end

    return {
        red = clamp(red / 255, 0, 1),
        green = clamp(green / 255, 0, 1),
        blue = clamp(blue / 255, 0, 1),
    }
end

local function current_time_seconds()
    local now = os.date("*t")
    return (now.hour * 3600) + (now.min * 60) + now.sec
end

local function timezone_offset_hours(reference_time)
    local timestamp = reference_time or os.time()
    local offset = os.date("%z", timestamp)
    local sign, hours, minutes = offset:match("^([%+%-])(%d%d)(%d%d)$")

    if not sign then
        return 0
    end

    local value = tonumber(hours) + (tonumber(minutes) / 60)
    if sign == "-" then
        return -value
    end

    return value
end

local function calculate_solar_event_hours(is_sunrise, latitude, longitude)
    local now = os.date("*t")
    local day_of_year = tonumber(os.date("%j")) or 1
    local lng_hour = longitude / 15
    local t = day_of_year + (((is_sunrise and 6 or 18) - lng_hour) / 24)
    local mean_anomaly = (0.9856 * t) - 3.289
    local true_longitude = normalize_degrees(
        mean_anomaly
        + (1.916 * math.sin(math.rad(mean_anomaly)))
        + (0.02 * math.sin(math.rad(2 * mean_anomaly)))
        + 282.634
    )
    local right_ascension = math.deg(math.atan(0.91764 * math.tan(math.rad(true_longitude))))
    local true_longitude_quadrant = math.floor(true_longitude / 90) * 90
    local right_ascension_quadrant = math.floor(right_ascension / 90) * 90

    right_ascension = normalize_degrees(right_ascension + (true_longitude_quadrant - right_ascension_quadrant)) / 15

    local sin_declination = 0.39782 * math.sin(math.rad(true_longitude))
    local cos_declination = math.cos(math.asin(sin_declination))
    local cos_hour_angle = (
        math.cos(math.rad(90.833))
        - (sin_declination * math.sin(math.rad(latitude)))
    ) / (cos_declination * math.cos(math.rad(latitude)))

    if cos_hour_angle > 1 then
        return nil, "polar_night"
    end

    if cos_hour_angle < -1 then
        return nil, "midnight_sun"
    end

    local hour_angle

    if is_sunrise then
        hour_angle = 360 - math.deg(math.acos(cos_hour_angle))
    else
        hour_angle = math.deg(math.acos(cos_hour_angle))
    end

    hour_angle = hour_angle / 15

    local local_mean_time = hour_angle + right_ascension - (0.06571 * t) - 6.622
    local utc_hours = (local_mean_time - lng_hour) % 24
    local local_hours = (utc_hours + timezone_offset_hours(os.time(now))) % 24

    return local_hours
end

local function time_window_contains(now_seconds, start_seconds, finish_seconds)
    return now_seconds >= start_seconds and now_seconds <= finish_seconds
end

local function seconds_from_hours(hours)
    return hours * 3600
end

local function parse_clock_value(value, fallback_hour)
    if type(value) == "number" then
        return clamp(value, 0, 24)
    end

    local hours, minutes = tostring(value or ""):match("^(%d%d?):(%d%d)$")

    if hours and minutes then
        return clamp(tonumber(hours) + (tonumber(minutes) / 60), 0, 24)
    end

    return fallback_hour
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
        or beautiful.lxaudio_bar_fg
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
            or beautiful.lxaudio_bar_fg
            or beautiful.fg_normal
            or "#ffffff"
    end
end

function M:_set_redshift_suspended(suspended)
    self._redshift_suspended = suspended and true or false
    self:_update_widget(self._brightness_value or 0)
end

function M:_default_redshift_temperature()
    return self._redshift.temperature_day or 6500
end

function M:_query_connected_outputs(callback)
    awful.spawn.easy_async({ self._redshift.command or "xrandr", "--query" }, function(stdout)
        callback(parse_connected_outputs(stdout))
    end)
end

function M:_build_xrandr_gamma_argv(gamma, outputs)
    local args = { self._redshift.command or "xrandr" }

    for _, output in ipairs(outputs) do
        args[#args + 1] = "--output"
        args[#args + 1] = output
        args[#args + 1] = "--gamma"
        args[#args + 1] = table.concat({
            format_gamma(gamma.red),
            format_gamma(gamma.green),
            format_gamma(gamma.blue),
        }, ":")
    end

    return args
end

function M:_apply_redshift_temperature(temperature, callback)
    self._redshift_pending_apply = {
        temperature = temperature,
        callback = callback,
    }

    self:_flush_redshift_apply_queue()
end

function M:_flush_redshift_apply_queue()
    if self._redshift_apply_inflight or not self._redshift_pending_apply then
        return
    end

    local apply_request = self._redshift_pending_apply
    self._redshift_pending_apply = nil
    self._redshift_apply_inflight = true

    self:_query_connected_outputs(function(outputs)
        self._redshift_outputs = outputs

        local function finish()
            self._redshift_apply_inflight = false
            self._redshift_temperature = apply_request.temperature

            if apply_request.callback then
                apply_request.callback()
            end

            if self._redshift_pending_apply then
                self:_flush_redshift_apply_queue()
            end
        end

        if #outputs == 0 then
            finish()
            return
        end

        awful.spawn.easy_async(
            self:_build_xrandr_gamma_argv(temperature_to_gamma(apply_request.temperature), outputs),
            finish
        )
    end)
end

function M:_reset_redshift(callback)
    self:_apply_redshift_temperature(self:_default_redshift_temperature(), callback)
end

function M:_scheduled_redshift_temperature()
    local day_temperature = self:_default_redshift_temperature()
    local night_temperature = self._redshift.temperature_night or 4500
    local transition_seconds = math.max(0, tonumber(self._redshift.schedule_transition_seconds) or 3600)
    local half_transition = transition_seconds / 2
    local latitude = tonumber(self._redshift.latitude)
    local longitude = tonumber(self._redshift.longitude)
    local sunrise_hours
    local sunset_hours
    local mode

    if latitude and longitude then
        sunrise_hours, mode = calculate_solar_event_hours(true, latitude, longitude)
        sunset_hours = calculate_solar_event_hours(false, latitude, longitude)

        if mode == "polar_night" then
            return night_temperature
        end

        if mode == "midnight_sun" then
            return day_temperature
        end
    end

    sunrise_hours = sunrise_hours or parse_clock_value(self._redshift.day_start, 7)
    sunset_hours = sunset_hours or parse_clock_value(self._redshift.night_start, 19)

    local now_seconds = current_time_seconds()
    local sunrise_seconds = seconds_from_hours(sunrise_hours)
    local sunset_seconds = seconds_from_hours(sunset_hours)
    local sunrise_start = sunrise_seconds - half_transition
    local sunrise_finish = sunrise_seconds + half_transition
    local sunset_start = sunset_seconds - half_transition
    local sunset_finish = sunset_seconds + half_transition

    if transition_seconds > 0 and time_window_contains(now_seconds, sunrise_start, sunrise_finish) then
        local progress = clamp((now_seconds - sunrise_start) / transition_seconds, 0, 1)
        return round(lerp(night_temperature, day_temperature, progress))
    end

    if transition_seconds > 0 and time_window_contains(now_seconds, sunset_start, sunset_finish) then
        local progress = clamp((now_seconds - sunset_start) / transition_seconds, 0, 1)
        return round(lerp(day_temperature, night_temperature, progress))
    end

    if sunrise_seconds <= sunset_seconds then
        if now_seconds >= sunrise_finish and now_seconds <= sunset_start then
            return day_temperature
        end
    elseif now_seconds >= sunrise_finish or now_seconds <= sunset_start then
        return day_temperature
    end

    return night_temperature
end

function M:_query_redshift_target_temperature(callback)
    callback(self:_scheduled_redshift_temperature())
end

function M:_sync_redshift_temperature(callback)
    if not self._redshift.enabled or self._redshift_suspended or self._redshift_transition_active then
        if callback then
            callback()
        end
        return
    end

    self:_apply_redshift_temperature(self:_scheduled_redshift_temperature(), callback)
end

function M:_stop_redshift_transition()
    if self._redshift_transition_timer then
        self._redshift_transition_timer:stop()
        self._redshift_transition_timer = nil
    end

    self._redshift_transition_id = (self._redshift_transition_id or 0) + 1
    self._redshift_transition_active = false
end

function M:_run_redshift_transition(from_temp, to_temp, on_done)
    self:_stop_redshift_transition()
    self._redshift_transition_active = true
    local transition_id = self._redshift_transition_id

    local steps = math.max(1, tonumber(self._redshift.transition_steps) or 8)
    local interval = tonumber(self._redshift.transition_interval) or 0.05
    local step_index = 0

    local function apply_step()
        if transition_id ~= self._redshift_transition_id then
            return
        end

        step_index = step_index + 1

        local progress = step_index / steps
        local temperature = round(lerp(from_temp, to_temp, progress))

        self:_apply_redshift_temperature(temperature, function()
            if transition_id ~= self._redshift_transition_id then
                return
            end

            if step_index >= steps then
                self:_stop_redshift_transition()
                if on_done then
                    on_done()
                end
                return
            end

            self._redshift_transition_timer = gears.timer.start_new(interval, function()
                self._redshift_transition_timer = nil
                apply_step()
                return false
            end)
        end)
    end

    apply_step()
end

function M:redshift_resume()
    if not self._redshift.enabled then
        return
    end

    self:_stop_redshift_transition()
    self:_set_redshift_suspended(false)
    self:_query_redshift_target_temperature(function(target)
        local start = self:_default_redshift_temperature()

        self:_reset_redshift(function()
            self:_run_redshift_transition(start, target, function()
                self._redshift_temperature = target
            end)
        end)
    end)
end

function M:redshift_suspend()
    local start = self._redshift_temperature or self:_default_redshift_temperature()
    local target = self:_default_redshift_temperature()

    self:_stop_redshift_transition()
    self:_set_redshift_suspended(true)
    self:_run_redshift_transition(start, target, function()
        self:_reset_redshift(function()
            self._redshift_temperature = target
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
        self:_sync_redshift_temperature(function()
            self:_set_redshift_suspended(false)
        end)
    else
        self:_reset_redshift(function()
            self:_set_redshift_suspended(true)
        end)
    end
end

function M:redshift_suspend_immediate()
    self:_stop_redshift_transition()
    self:_reset_redshift(function()
        self._redshift_temperature = self:_default_redshift_temperature()
        self:_set_redshift_suspended(true)
    end)
end

function M:_start_redshift_timer()
    self._redshift_refresh_timer = gears.timer({
        timeout = tonumber(self._redshift.refresh_interval) or 120,
        autostart = true,
        call_now = false,
        callback = function()
            self:_sync_redshift_temperature()
        end,
    })
end

function M:_stop_redshift_timer()
    if self._redshift_refresh_timer then
        self._redshift_refresh_timer:stop()
        self._redshift_refresh_timer = nil
    end
end

function M:_shutdown()
    self:_stop_redshift_transition()
    self:_stop_redshift_timer()
end

function M:_setup_shutdown_hook()
    awesome.connect_signal("exit", function()
        self:_shutdown()
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
    self._icon_text = wibox.widget({
        text = beautiful.lxdisplay_icon or beautiful.lxdisplay_icon_brightness or "󰃟",
        font = beautiful.lxdisplay_icon_font or beautiful.font,
        widget = wibox.widget.textbox,
    })
    self._icon_role = wibox.widget({
        self._icon_text,
        fg = beautiful.lxdisplay_widget_fg or beautiful.fg_normal or "#ffffff",
        widget = wibox.container.background,
    })

    local content = {
        self._icon_role,
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
            background_color = beautiful.lxdisplay_bar_bg
                or beautiful.lxaudio_bar_bg
                or beautiful.bg_minimize
                or "#444444",
            color = beautiful.lxdisplay_bar_fg
                or beautiful.lxaudio_bar_fg
                or beautiful.fg_normal
                or "#ffffff",
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
            background_color = beautiful.lxdisplay_osd_bar_bg
                or beautiful.lxdisplay_bar_bg
                or beautiful.lxaudio_bar_bg
                or beautiful.bg_minimize
                or "#444444",
            color = beautiful.lxdisplay_osd_bar_fg
                or beautiful.lxdisplay_bar_fg
                or beautiful.lxaudio_bar_fg
                or beautiful.fg_normal
                or "#ffffff",
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
        command = commands.redshift.command or "xrandr",
        enabled = commands.redshift.enabled ~= false,
        autostart = commands.redshift.autostart ~= false,
        latitude = commands.redshift.latitude,
        longitude = commands.redshift.longitude,
        temperature_day = commands.redshift.temperature_day,
        temperature_night = commands.redshift.temperature_night,
        transition_steps = commands.redshift.transition_steps or 8,
        transition_interval = commands.redshift.transition_interval or 0.05,
        refresh_interval = commands.redshift.refresh_interval or 120,
        schedule_transition_seconds = commands.redshift.schedule_transition_seconds or 3600,
        day_start = commands.redshift.day_start,
        night_start = commands.redshift.night_start,
    }
    self._redshift_suspended = not self._redshift.autostart

    self.widget = wibox.container.place()
    self:_build_widget()
    self:_build_osd()
    self:_start_refresh_timer()
    self:_start_redshift_timer()
    self:_setup_shutdown_hook()
    self:_initialize_redshift()

    return self
end

return M
