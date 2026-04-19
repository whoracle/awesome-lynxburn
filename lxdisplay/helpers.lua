local helpers = {}

---Clamp a numeric value to an inclusive range.
function helpers.clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

---Extract a percentage-like number from command output.
function helpers.parse_percent(stdout)
    return tonumber(tostring(stdout or ""):match("(%d+%.?%d*)")) or 0
end

---Linearly interpolate between two values.
function helpers.lerp(a, b, t)
    return a + ((b - a) * t)
end

---Round to the nearest integer.
function helpers.round(value)
    return math.floor(value + 0.5)
end

---Normalize arbitrary degrees into the `[0, 360)` range.
function helpers.normalize_degrees(value)
    local normalized = value % 360

    if normalized < 0 then
        normalized = normalized + 360
    end

    return normalized
end

---Parse connected output names from `xrandr --query`.
function helpers.parse_connected_outputs(stdout)
    local outputs = {}

    for line in tostring(stdout or ""):gmatch("[^\r\n]+") do
        local output = line:match("^(%S+)%s+connected%s")

        if output then
            outputs[#outputs + 1] = output
        end
    end

    return outputs
end

---Format a gamma channel value for xrandr.
function helpers.format_gamma(value)
    return string.format("%.4f", helpers.clamp(value, 0.0001, 1))
end

---Approximate RGB gamma values from a color temperature in Kelvin.
function helpers.temperature_to_gamma(temperature)
    local kelvin = helpers.clamp(tonumber(temperature) or 6500, 1000, 40000) / 100
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
        red = helpers.clamp(red / 255, 0, 1),
        green = helpers.clamp(green / 255, 0, 1),
        blue = helpers.clamp(blue / 255, 0, 1),
    }
end

---Return the current local wall-clock time as seconds since midnight.
function helpers.current_time_seconds()
    local now = os.date("*t")
    return (now.hour * 3600) + (now.min * 60) + now.sec
end

---Return the current timezone offset in fractional hours.
function helpers.timezone_offset_hours(reference_time)
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

---Approximate sunrise/sunset hours for the current day.
function helpers.calculate_solar_event_hours(is_sunrise, latitude, longitude)
    local day_of_year = tonumber(os.date("%j")) or 1
    local lng_hour = longitude / 15
    local t = day_of_year + (((is_sunrise and 6 or 18) - lng_hour) / 24)
    local mean_anomaly = (0.9856 * t) - 3.289
    local true_longitude = helpers.normalize_degrees(
        mean_anomaly
        + (1.916 * math.sin(math.rad(mean_anomaly)))
        + (0.02 * math.sin(math.rad(2 * mean_anomaly)))
        + 282.634
    )
    local right_ascension = math.deg(math.atan(0.91764 * math.tan(math.rad(true_longitude))))
    local true_longitude_quadrant = math.floor(true_longitude / 90) * 90
    local right_ascension_quadrant = math.floor(right_ascension / 90) * 90

    right_ascension = helpers.normalize_degrees(right_ascension + (true_longitude_quadrant - right_ascension_quadrant)) / 15

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
    local local_hours = (utc_hours + helpers.timezone_offset_hours(os.time())) % 24

    return local_hours
end

---Test whether `now_seconds` falls inside the inclusive window.
function helpers.time_window_contains(now_seconds, start_seconds, finish_seconds)
    return now_seconds >= start_seconds and now_seconds <= finish_seconds
end

---Convert fractional hours to seconds.
function helpers.seconds_from_hours(hours)
    return hours * 3600
end

---Parse either `HH:MM` strings or raw numeric hour values.
function helpers.parse_clock_value(value, fallback_hour)
    if type(value) == "number" then
        return helpers.clamp(value, 0, 24)
    end

    local hours, minutes = tostring(value or ""):match("^(%d%d?):(%d%d)$")

    if hours and minutes then
        return helpers.clamp(tonumber(hours) + (tonumber(minutes) / 60), 0, 24)
    end

    return fallback_hour
end

return helpers
