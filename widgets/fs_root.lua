local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")

local metric = require("widgets.metric")

return function(context)
    local theme = (context and context.beautiful) or require("beautiful")
    local icon = metric.icon(theme.icon_fs)
    local widget = wibox.widget.textbox()
    local warned = false

    local function set_usage(percentage)
        local fs_p = ""

        if percentage and percentage >= 90 then
            fs_p = metric.font(
                theme,
                (theme.space or " ")
                    .. metric.color(theme, "root ")
                    .. percentage
                    .. metric.color(theme, "%" .. (theme.space or " "))
            )
            metric.show(icon)
        else
            metric.hide(icon)
        end

        widget:set_markup(fs_p)

        if percentage and percentage >= 95 and not warned then
            warned = true
            naughty.notify({
                preset = naughty.config.presets.critical,
                title = "Warning",
                text = string.format("/ is above 95%% (%d%%)", percentage),
            })
        elseif percentage and percentage < 95 then
            warned = false
        end
    end

    local function refresh()
        awful.spawn.easy_async({ "df", "-P", "/" }, function(stdout, _, _, exit_code)
            if exit_code ~= 0 then
                return
            end

            local line = stdout:match("\n([^\n]+)")
            local percentage = line and tonumber(line:match("(%d+)%%"))
            set_usage(percentage)
        end)
    end

    local timer = gears.timer({ timeout = 600 })
    timer:connect_signal("timeout", refresh)
    timer:start()
    refresh()

    return metric.wrap(context, icon, widget).metric
end
