local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxcommon.popup_ui")
local popup_placement = require("lxcommon.popup_placement")
local screen_util = require("lxcommon.screen")

local popup = {}

local function apply_popup_geometry(instance, popup_widget, anchor)
    local target_screen = screen_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        instance:_theme_value("lxbluetooth_popup_placement", "side"),
        { width = math.min(instance:_theme_value("lxbluetooth_popup_width", 360), target_screen.workarea.width) }
    )
end

---Attach popup rendering and selection-state methods to the lxbluetooth instance.
function popup.extend(instance_methods)
    function instance_methods:_refresh_popup()
        if not self._popup_refs then
            return
        end

        local refs = self._popup_refs
        refs.list:reset()
        self._popup_items = {
            {
                on_enter = function()
                    self:close_popup()
                    self:open_manager()
                end,
            },
            {
                on_enter = function()
                    self:toggle_power()
                end,
            },
        }

        local status = self.state.powered and "Powered" or "Disabled"
        refs.status.markup = string.format(
            "<span foreground='%s'>Bluetooth %s</span>",
            gears.string.xml_escape(self:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999")),
            gears.string.xml_escape(status)
        )

        for _, device in ipairs(self.state.devices) do
            local prefix = device.connected and "● " or "○ "
            local suffix = {}
            if device.battery then
                suffix[#suffix + 1] = string.format("%d%%", device.battery)
            end
            local summary = device.name or device.address
            if #suffix > 0 then
                summary = string.format("%s  [%s]", summary, table.concat(suffix, ", "))
            end

            local next_index = #self._popup_items + 1
            local selected = self._popup_selected_index == next_index
            local row = popup_common.make_selectable_click_row(prefix .. summary, function()
                if device.connected then
                    self:_device_action("disconnect", device.address)
                else
                    self:_device_action("connect", device.address)
                end
            end, {
                selected = selected,
                inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
                outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
            })

            refs.list:add(row)
            self._popup_items[#self._popup_items + 1] = {
                on_enter = function()
                    if device.connected then
                        self:_device_action("disconnect", device.address)
                    else
                        self:_device_action("connect", device.address)
                    end
                end,
            }
        end

        if #self.state.devices == 0 then
            refs.list:add(popup_common.make_info_line(string.format(
                "<span foreground='%s'>No paired devices found.</span>",
                gears.string.xml_escape(self:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999"))
            )))
        end
    end

    function instance_methods:_build_popup()
        local status = wibox.widget({
            markup = "",
            widget = wibox.widget.textbox,
        })
        local list = wibox.layout.fixed.vertical()

        self._popup_refs = {
            status = status,
            list = list,
        }

        local popup_widget = wibox.widget({
            {
                popup_common.make_selectable_click_row("Open blueman-manager", function()
                    self:close_popup()
                    self:open_manager()
                end, {
                    selected = self._popup_selected_index == 1,
                    inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                    hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
                    outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                    selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
                }),
                popup_common.make_selectable_click_row("Toggle controller power", function()
                    self:toggle_power()
                end, {
                    selected = self._popup_selected_index == 2,
                    inner_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                    hover_bg = self:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
                    outer_bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                    selected_bg = self:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
                }),
                status,
                list,
                spacing = 8,
                layout = wibox.layout.fixed.vertical,
            },
            margins = 10,
            widget = wibox.container.margin,
        })

        self:_refresh_popup()
        return popup_widget
    end

    function instance_methods:_ensure_popup_selection()
        local count = #(self._popup_items or {})
        if count < 1 then
            self._popup_selected_index = 1
            return
        end

        self._popup_selected_index = math.max(1, math.min(self._popup_selected_index or 1, count))
    end

    function instance_methods:move_popup_selection(delta)
        self:_ensure_popup_selection()
        local count = #(self._popup_items or {})
        if count < 1 then
            return
        end

        self._popup_selected_index = math.max(1, math.min((self._popup_selected_index or 1) + delta, count))
        if self._popup and self._popup.visible then
            self._popup.widget = self:_build_popup()
        else
            self:_refresh_popup()
        end
    end

    function instance_methods:activate_selected_popup_item()
        self:_ensure_popup_selection()
        local item = (self._popup_items or {})[self._popup_selected_index or 1]
        if item and type(item.on_enter) == "function" then
            item.on_enter()
        end
    end

    function instance_methods:_ensure_popup(anchor)
        if not self._popup then
            self._popup = awful.popup({
                visible = false,
                ontop = true,
                type = "dock",
                bg = self:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
                widget = self:_build_popup(),
            })
        else
            self._popup.widget = self:_build_popup()
        end

        apply_popup_geometry(self, self._popup, anchor)
        return self._popup
    end
end

return popup
