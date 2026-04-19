local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}
M.__index = M

local function destroy_channel(channel)
    if channel.hide_timer then
        channel.hide_timer:stop()
        channel.hide_timer = nil
    end

    if channel.notification then
        channel.notification:destroy()
        channel.notification = nil
    end

    channel.box = nil
end

local function build_notification_box(state, app_name, widget_template, width, margin)
    state.notification = naughty.notification({
        title = "",
        message = "",
        app_name = app_name,
        timeout = 0,
        position = "bottom_middle",
        ontop = true,
        screen = awful.screen.focused(),
    })

    state.box = naughty.layout.box({
        notification = state.notification,
        position = "bottom_middle",
        screen = awful.screen.focused(),
        widget_template = widget_template,
    })

    state.box.width = width + (margin * 2)
    state.box.visible = false

    state.notification:connect_signal("destroyed", function()
        state.notification = nil
        state.box = nil
    end)
end

local function arm_hide_timer(state, timeout)
    if state.hide_timer then
        state.hide_timer:stop()
    end

    state.hide_timer = gears.timer.start_new(timeout, function()
        destroy_channel(state)
        return false
    end)
end

function M:_build_progress_widget()
    local icon = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = 32,
        widget = wibox.widget.textbox,
    })

    local bar = wibox.widget({
        max_value = 100,
        value = 0,
        forced_width = self.width,
        forced_height = self.height,
        shape = gears.shape.rounded_bar,
        bar_shape = gears.shape.rounded_bar,
        background_color = self.bar_bg,
        color = self.bar_fg,
        widget = wibox.widget.progressbar,
    })

    return {
        icon = icon,
        bar = bar,
        template = {
            {
                {
                    {
                        icon,
                        {
                            bar,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = self.margin,
                widget = wibox.container.margin,
            },
            bg = self.bg,
            fg = self.fg,
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        },
    }
end

function M:_build_text_widget()
    local icon = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = 32,
        widget = wibox.widget.textbox,
    })

    local text = wibox.widget({
        align = "center",
        valign = "center",
        forced_width = self.width,
        widget = wibox.widget.textbox,
    })

    return {
        icon = icon,
        text = text,
        template = {
            {
                {
                    {
                        icon,
                        {
                            text,
                            widget = wibox.container.place,
                        },
                        spacing = 12,
                        layout = wibox.layout.fixed.horizontal,
                    },
                    widget = wibox.container.place,
                },
                margins = self.margin,
                widget = wibox.container.margin,
            },
            bg = self.bg,
            fg = self.fg,
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background,
        },
    }
end

function M:_ensure_progress_channel(app_name)
    if self._progress.box then
        return
    end

    build_notification_box(self._progress, app_name, self._progress_ui.template, self.width, self.margin)
end

function M:_ensure_text_channel(app_name)
    if self._text.box then
        return
    end

    build_notification_box(self._text, app_name, self._text_ui.template, self.width, self.margin)
end

function M:show_progress(opts)
    opts = opts or {}

    destroy_channel(self._text)
    self:_ensure_progress_channel(opts.app_name or "OSD")

    local value = tonumber(opts.value) or 0
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end

    self._progress_ui.icon.text = opts.icon or ""
    self._progress_ui.bar.value = value
    self._progress_ui.bar.color = opts.color or self.bar_fg

    self._progress.box.screen = awful.screen.focused()
    self._progress.box.visible = true
    arm_hide_timer(self._progress, opts.timeout or self.timeout)
end

function M:show_text(opts)
    opts = opts or {}

    destroy_channel(self._progress)
    self:_ensure_text_channel(opts.app_name or "OSD")

    self._text_ui.text.text = opts.text or ""
    self._text_ui.icon.text = opts.icon or ""

    self._text.box.screen = awful.screen.focused()
    self._text.box.visible = true
    arm_hide_timer(self._text, opts.timeout or self.timeout)
end

function M.new(opts)
    opts = opts or {}

    local self = setmetatable({}, M)
    self.width = opts.width or 260
    self.height = opts.height or 18
    self.margin = opts.margin or 16
    self.timeout = opts.timeout or 1
    self.bg = opts.bg or beautiful.notification_bg or beautiful.bg_normal or "#111111"
    self.fg = opts.fg or beautiful.notification_fg or beautiful.fg_normal or "#ffffff"
    self.bar_bg = opts.bar_bg or beautiful.bg_minimize or "#444444"
    self.bar_fg = opts.bar_fg or beautiful.fg_normal or "#ffffff"

    self._progress = {}
    self._text = {}
    self._progress_ui = self:_build_progress_widget()
    self._text_ui = self:_build_text_widget()

    return self
end

return M
