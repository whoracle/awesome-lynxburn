local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxcommon.popup_ui")
local controller = require("lxnetwork.controller")
local password_prompt = require("lxnetwork.password_prompt")
local popup = require("lxnetwork.popup")
local state = require("lxnetwork.state")
local theme = require("lxnetwork.theme")

local M = {}
M.__index = M

local DEFAULTS = {
    refresh_interval = 20,
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
password_prompt.extend(M)
popup.extend(M)
controller.extend(M)

---Start the periodic refresh timer for the lxnetwork widget state.
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

---Create a new lxnetwork instance with widget, popup, and refresh state.
function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        enabled = false,
        current_ssid = nil,
        networks = {},
        scan_in_progress = false,
        vpn_active = false,
    }
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({
        markup = "",
        font = self:_theme_value("lxnetwork_icon_font", beautiful.font),
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
                    forced_width = self:_theme_value("lxnetwork_icon_width", 26),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    popup_common.attach_button_feedback(self.widget, {
        idle_bg = nil,
        hover_bg = self:_theme_value("lxnetwork_widget_hover_bg", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxnetwork_widget_press_bg", self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#666666")),
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end),
        awful.button({}, 3, function()
            self:scan()
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
