local beautiful = require("beautiful")
local wibox = require("wibox")

local brightness = require("lxdisplay.brightness")
local displays = require("lxdisplay.displays")
local popup = require("lxdisplay.popup")
local redshift = require("lxdisplay.redshift")
local theme = require("lxdisplay.theme")
local popup_controller = require("lxcommon.popup_controller")

local M = {}
M.__index = M

theme.extend(M)
redshift.extend(M)
brightness.extend(M)
displays.extend(M)
popup.extend(M)
popup_controller.extend(M)

---Create a new lxdisplay instance with brightness, redshift, and widget state.
function M.new(opts)
    opts = opts or {}
    local self = setmetatable({}, M)
    local brightness_opts = opts.brightness or {}
    local redshift_opts = opts.redshift or {}
    self._opts = opts
    self._profiles = self:_normalize_profiles(opts.profiles or {})
    self._detected = {
        extend_relative_to = ((opts.detected or {}).extend_relative_to) or "profile-primary",
        extend_direction = ((opts.detected or {}).extend_direction) or "left",
    }

    self._commands = {
        get = brightness_opts.get or "xbacklight -get",
        set = brightness_opts.set or "xbacklight -set %d",
        step = brightness_opts.step or 5,
        min = brightness_opts.min or 10,
        max = brightness_opts.max or 100,
        off = brightness_opts.off or "xset dpms force off",
    }
    self._redshift = {
        command = redshift_opts.command or "xrandr",
        enabled = redshift_opts.enabled ~= false,
        autostart = redshift_opts.autostart ~= false,
        latitude = redshift_opts.latitude,
        longitude = redshift_opts.longitude,
        temperature_day = redshift_opts.temperature_day,
        temperature_night = redshift_opts.temperature_night,
        transition_steps = redshift_opts.transition_steps or 8,
        transition_interval = redshift_opts.transition_interval or 0.05,
        refresh_interval = redshift_opts.refresh_interval or 120,
        schedule_transition_seconds = redshift_opts.schedule_transition_seconds or 3600,
        day_start = redshift_opts.day_start,
        night_start = redshift_opts.night_start,
    }
    self._redshift_suspended = not self._redshift.autostart
    self.state = {
        active_profile_index = nil,
        connected_outputs = {},
        connected_output_set = {},
        current_primary_output = nil,
        detected_outputs = {},
    }
    self._popup_selected_index = 1

    self.widget = wibox.container.place()
    self:_build_widget()
    self:_build_osd()
    self:_start_refresh_timer()
    self:_start_redshift_timer()
    self:_setup_shutdown_hook()
    self:_initialize_redshift()
    self:refresh_display_state()

    return self
end

return M
