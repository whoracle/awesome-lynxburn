local awful = require("awful")
local gears = require("gears")

local helpers = require("lxdisplay.helpers")

local brightness = {}

---Attach brightness command and refresh helpers to the instance.
function brightness.extend(instance_methods)
    ---Read the current brightness from the configured backend command.
    function instance_methods:_refresh_from_command(callback)
        awful.spawn.easy_async_with_shell(self._commands.get, function(stdout)
            local value = helpers.parse_percent(stdout)
            self:_update_widget(value)

            if callback then
                callback(value)
            end
        end)
    end

    ---Refresh widget state and optionally surface the OSD.
    function instance_methods:brightness_refresh(options)
        options = options or {}

        self:_refresh_from_command(function(value)
            if options.show_osd then
                self:_show_brightness_osd(value)
            end
        end)
    end

    ---Debounce post-write refreshes so backends have time to settle.
    function instance_methods:_schedule_brightness_refresh(delay)
        if self._brightness_refresh_timer then
            self._brightness_refresh_timer:stop()
            self._brightness_refresh_timer = nil
        end

        self._brightness_refresh_timer = gears.timer.start_new(delay or 0.15, function()
            self._brightness_refresh_timer = nil
            self:brightness_refresh({ show_osd = false })
            return false
        end)
    end

    ---Apply an absolute brightness target through the configured backend.
    function instance_methods:_set_brightness(value, options)
        options = options or {}

        local target = helpers.clamp(
            value,
            self._commands.min or 0,
            self._commands.max or 100
        )
        local command = string.format(self._commands.set, target)

        self:_update_widget(target)
        if options.show_osd then
            self:_show_brightness_osd(target)
        end

        awful.spawn.easy_async_with_shell(command, function()
            self:_schedule_brightness_refresh(0.15)
        end)
    end

    ---Apply a relative brightness step from the latest known value.
    function instance_methods:_step_brightness(delta, options)
        options = options or {}

        local current = self._brightness_value
        if current == nil then
            self:_refresh_from_command(function(refreshed)
                self:_set_brightness(refreshed + delta, options)
            end)
            return
        end

        self:_set_brightness(current + delta, options)
    end

    ---Increase brightness by the configured step.
    function instance_methods:brightness_up(_, options)
        self:_step_brightness(self._commands.step, options)
    end

    ---Decrease brightness by the configured step.
    function instance_methods:brightness_down(_, options)
        self:_step_brightness(-self._commands.step, options)
    end

    ---Trigger the configured display-off command.
    function instance_methods:brightness_off()
        awful.spawn.easy_async_with_shell(self._commands.off, function() end)
    end

    ---Set brightness from a bar-relative click position.
    function instance_methods:_set_brightness_from_bar_click(local_x, width)
        if not width or width <= 0 then
            return
        end

        local relative_x = helpers.clamp(local_x or 0, 0, width)
        local ratio = relative_x / width
        local target = helpers.round(helpers.lerp(
            self._commands.min or 0,
            self._commands.max or 100,
            ratio
        ))

        self:_set_brightness(target, { show_osd = false })
    end

    ---Bind widget-local mouse controls for brightness and redshift toggle.
    function instance_methods:_attach_mouse_controls(widget)
        widget:buttons(gears.table.join(
            awful.button({}, 2, function()
                if self.redshift_toggle then
                    self:redshift_toggle()
                end
            end),
            awful.button({}, 3, function()
                self:toggle_popup(mouse.current_widget_geometry)
            end),
            awful.button({}, 4, function()
                self:brightness_up(nil, { show_osd = false })
            end),
            awful.button({}, 5, function()
                self:brightness_down(nil, { show_osd = false })
            end)
        ))
    end

    ---Poll brightness periodically so external changes stay reflected in the UI.
    function instance_methods:_start_refresh_timer()
        self._refresh_timer = gears.timer({
            timeout = tonumber(self._opts.refresh_interval) or 15,
            autostart = true,
            call_now = true,
            callback = function()
                self:brightness_refresh({ show_osd = false })
            end,
        })
    end
end

return brightness
