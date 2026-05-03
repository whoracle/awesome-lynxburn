local awful = require("awful")
local gears = require("gears")

local helpers = require("lxdisplay.helpers")

local redshift = {}

---Attach redshift scheduling and xrandr gamma helpers to the instance.
function redshift.extend(instance_methods)
    ---Return the configured daytime color temperature.
    function instance_methods:_default_redshift_temperature()
        return self._redshift.temperature_day or 6500
    end

    ---Query currently connected outputs from the configured xrandr-compatible command.
    function instance_methods:_query_connected_outputs(callback)
        self._backend.query_connected_outputs(self, callback)
    end

    ---Build an argv array that applies one gamma triple to all connected outputs.
    function instance_methods:_build_xrandr_gamma_argv(gamma, outputs)
        return self._backend.build_gamma_argv and self._backend.build_gamma_argv(self, gamma, outputs) or nil
    end

    ---Queue a temperature apply request so fast updates collapse cleanly.
    function instance_methods:_apply_redshift_temperature(temperature, callback)
        self._redshift_pending_apply = {
            temperature = temperature,
            callback = callback,
        }

        self:_flush_redshift_apply_queue()
    end

    ---Run the latest queued apply request once no other xrandr apply is in flight.
    function instance_methods:_flush_redshift_apply_queue()
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

            self._backend.apply_gamma(
                self,
                helpers.temperature_to_gamma(apply_request.temperature),
                outputs,
                finish
            )
        end)
    end

    ---Restore neutral daytime temperature.
    function instance_methods:_reset_redshift(callback)
        self:_apply_redshift_temperature(self:_default_redshift_temperature(), callback)
    end

    ---Compute the target temperature for the current time and schedule settings.
    function instance_methods:_scheduled_redshift_temperature()
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
            sunrise_hours, mode = helpers.calculate_solar_event_hours(true, latitude, longitude)
            sunset_hours = helpers.calculate_solar_event_hours(false, latitude, longitude)

            if mode == "polar_night" then
                return night_temperature
            end

            if mode == "midnight_sun" then
                return day_temperature
            end
        end

        sunrise_hours = sunrise_hours or helpers.parse_clock_value(self._redshift.day_start, 7)
        sunset_hours = sunset_hours or helpers.parse_clock_value(self._redshift.night_start, 19)

        local now_seconds = helpers.current_time_seconds()
        local sunrise_seconds = helpers.seconds_from_hours(sunrise_hours)
        local sunset_seconds = helpers.seconds_from_hours(sunset_hours)
        local sunrise_start = sunrise_seconds - half_transition
        local sunrise_finish = sunrise_seconds + half_transition
        local sunset_start = sunset_seconds - half_transition
        local sunset_finish = sunset_seconds + half_transition

        if transition_seconds > 0 and helpers.time_window_contains(now_seconds, sunrise_start, sunrise_finish) then
            local progress = helpers.clamp((now_seconds - sunrise_start) / transition_seconds, 0, 1)
            return helpers.round(helpers.lerp(night_temperature, day_temperature, progress))
        end

        if transition_seconds > 0 and helpers.time_window_contains(now_seconds, sunset_start, sunset_finish) then
            local progress = helpers.clamp((now_seconds - sunset_start) / transition_seconds, 0, 1)
            return helpers.round(helpers.lerp(day_temperature, night_temperature, progress))
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

    ---Fetch the current target temperature; kept as a hook for future expansion.
    function instance_methods:_query_redshift_target_temperature(callback)
        callback(self:_scheduled_redshift_temperature())
    end

    ---Apply the currently scheduled temperature unless redshift is suspended or transitioning.
    function instance_methods:_sync_redshift_temperature(callback)
        if not self._redshift.enabled
            or not self._backend.supports_redshift()
            or self._redshift_suspended
            or self._redshift_transition_active then
            if callback then
                callback()
            end
            return
        end

        self:_apply_redshift_temperature(self:_scheduled_redshift_temperature(), callback)
    end

    ---Cancel the active transition timer and invalidate in-flight step callbacks.
    function instance_methods:_stop_redshift_transition()
        if self._redshift_transition_timer then
            self._redshift_transition_timer:stop()
            self._redshift_transition_timer = nil
        end

        self._redshift_transition_id = (self._redshift_transition_id or 0) + 1
        self._redshift_transition_active = false
    end

    ---Animate between two temperatures in small xrandr apply steps.
    function instance_methods:_run_redshift_transition(from_temp, to_temp, on_done)
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
            local temperature = helpers.round(helpers.lerp(from_temp, to_temp, progress))

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

    ---Resume scheduled redshift behavior with a smooth transition from neutral.
    function instance_methods:redshift_resume()
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

    ---Suspend scheduled redshift behavior and return smoothly to neutral temperature.
    function instance_methods:redshift_suspend()
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

    ---Toggle between scheduled and suspended redshift behavior.
    function instance_methods:redshift_toggle()
        if self._redshift_suspended then
            self:redshift_resume()
        else
            self:redshift_suspend()
        end
    end

    ---Apply initial redshift state during module construction.
    function instance_methods:_initialize_redshift()
        self._redshift_temperature = self:_default_redshift_temperature()

        if self._redshift.autostart and self._redshift.enabled and self._backend.supports_redshift() then
            self:_sync_redshift_temperature(function()
                self:_set_redshift_suspended(false)
            end)
        else
            self:_reset_redshift(function()
                self:_set_redshift_suspended(true)
            end)
        end
    end

    ---Immediately disable redshift without the usual transition.
    function instance_methods:redshift_suspend_immediate()
        self:_stop_redshift_transition()
        self:_reset_redshift(function()
            self._redshift_temperature = self:_default_redshift_temperature()
            self:_set_redshift_suspended(true)
        end)
    end

    ---Start the periodic schedule-sync timer.
    function instance_methods:_start_redshift_timer()
        self._redshift_refresh_timer = gears.timer({
            timeout = tonumber(self._redshift.refresh_interval) or 120,
            autostart = true,
            call_now = false,
            callback = function()
                self:_sync_redshift_temperature()
            end,
        })
    end

    ---Stop the periodic schedule-sync timer.
    function instance_methods:_stop_redshift_timer()
        if self._redshift_refresh_timer then
            self._redshift_refresh_timer:stop()
            self._redshift_refresh_timer = nil
        end
    end

    ---Stop background timers/transition work owned by this instance.
    function instance_methods:_shutdown()
        self:_stop_redshift_transition()
        self:_stop_redshift_timer()
    end

    ---Bind Awesome shutdown to the module's redshift cleanup path.
    function instance_methods:_setup_shutdown_hook()
        awesome.connect_signal("exit", function()
            self:_shutdown()
        end)
    end
end

return redshift
