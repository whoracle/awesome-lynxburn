local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_ui = require("lxcommon.popup_ui")
local controller = require("lxbluetooth.controller")
local popup = require("lxbluetooth.popup")
local state = require("lxbluetooth.state")
local theme = require("lxbluetooth.theme")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 15,
}

local function merge_defaults(opts)
    opts = opts or {}
    local merged = {}

    for key, value in pairs(DEFAULTS) do
        merged[key] = value
    end

    for key, value in pairs(opts) do
        merged[key] = value
    end

    return merged
end

theme.extend(M)
state.extend(M)
popup.extend(M)
controller.extend(M)

---Start the periodic bluetooth refresh timer.
function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            self:refresh()
        end,
    })
end

---Create a new lxbluetooth instance with widget, popup, and refresh state.
function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        powered = false,
        devices = {},
        connected_count = 0,
    }
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({
        markup = "",
        font = self:_theme_value("lxbluetooth_icon_font", beautiful.font),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })
    self._refs.icon = icon

    self.widget = wibox.widget({
        {
            {
                {
                    {
                        icon,
                        halign = "center",
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    forced_width = self:_theme_value("lxbluetooth_icon_width", 16),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 2,
            right = 2,
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    popup_ui.attach_button_feedback(self.widget, {
        idle_bg = nil,
        hover_bg = self:_theme_value("lxbluetooth_widget_hover_bg", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxbluetooth_widget_press_bg", self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#666666")),
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end),
        awful.button({}, 2, function()
            self:toggle_power()
        end),
        awful.button({}, 3, function()
            self:open_manager()
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
