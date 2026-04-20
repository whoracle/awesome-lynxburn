local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_ui = require("lxcommon.popup_ui")
local controller = require("lxpower.controller")
local popup = require("lxpower.popup")
local state = require("lxpower.state")
local theme = require("lxpower.theme")

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
popup.extend(M)
controller.extend(M)

---Start the periodic refresh timer and auto-switch profiles on source change.
function M:_start_timer()
    self._timer = gears.timer({
        timeout = self.opts.refresh_interval,
        autostart = true,
        call_now = true,
        callback = function()
            local previous_source = self.state.power_source
            local current_source = self:_power_source()

            if previous_source and previous_source ~= current_source then
                if self.state.pinned then
                    self:refresh()
                    return
                end

                self:set_profile(self:_remembered_profile(current_source))
                return
            end

            self:refresh()
        end,
    })
end

---Create a new lxpower instance with widget, popup, and refresh state.
function M.new(opts)
    opts = merge_defaults(opts)

    local self = setmetatable({}, M)
    self.opts = opts
    self.state = {
        power_source = "battery",
        profile = "power-saver",
        dgpu_status = "unknown",
        dgpu_active = false,
        pinned = false,
    }
    self._preferred_profiles = self:normalize_preferred_profiles(opts.preferred_profiles)
    self._popup_selected_index = 1
    self._refs = {}

    local icon = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    icon.align = "center"
    icon.valign = "center"
    icon.font = self:_theme_value("lxpower_icon_font", beautiful.font)
    local label = wibox.widget({ markup = "", widget = wibox.widget.textbox })
    label.align = "center"
    label.valign = "center"
    self._refs.icon = icon
    self._refs.label = label

    self.widget = wibox.widget({
        {
            {
                {
                    icon,
                    forced_width = self:_theme_value("lxpower_icon_width", 16),
                    strategy = "exact",
                    widget = wibox.container.constraint,
                },
                label,
                spacing = 8,
                layout = wibox.layout.fixed.horizontal,
            },
            widget = wibox.container.margin,
        },
        widget = wibox.container.background,
    })

    popup_ui.attach_button_feedback(self.widget, {
        idle_bg = nil,
        hover_bg = self:_theme_value("lxpower_widget_hover_bg", beautiful.bg_focus or "#444444"),
        press_bg = self:_theme_value("lxpower_widget_press_bg", self:_theme_value("lxpower_button_hover", beautiful.bg_focus or "#666666")),
    })

    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:toggle()
        end),
        awful.button({}, 3, function()
            self:toggle_popup(mouse.current_widget_geometry)
        end)
    ))

    self:_refresh_widget()
    self:_start_timer()
    return self
end

return M
