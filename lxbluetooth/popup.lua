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

local function make_section_header(instance, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ), {
        top = 4,
        bottom = 2,
    })
end

local function make_status_line(instance, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ))
end

local function wrap_card(child)
    return popup_common.make_card(child, {
        margins = 6,
        radius = 8,
    })
end

local function selectable_card(instance, child, selected, index, onclick)
    return popup_common.make_selectable_click_container(child, onclick, {
        selected = selected,
        inner_bg = instance:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxbluetooth_button_hover", beautiful.bg_focus or "#444444"),
        outer_bg = instance:_theme_value("lxbluetooth_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = instance:_theme_value("lxbluetooth_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
        on_hover = function()
            instance:_set_popup_selection(index)
        end,
    })
end

local function device_metadata(device)
    local parts = {}

    if device.connected then
        parts[#parts + 1] = "connected"
    else
        parts[#parts + 1] = "paired"
    end

    if device.trusted then
        parts[#parts + 1] = "trusted"
    end

    if device.blocked then
        parts[#parts + 1] = "blocked"
    end

    if device.battery then
        parts[#parts + 1] = string.format("%d%%", device.battery)
    end

    return table.concat(parts, " • ")
end

local function make_device_row(instance, device, selected, selection_index, onclick)
    local meta_fg = instance:_theme_value("lxbluetooth_meta_fg", beautiful.fg_minimize or "#999999")
    local name = device.name or device.address
    local action = device.connected and "Disconnect" or "Connect"

    local row = wibox.widget({
        {
            {
                markup = gears.string.xml_escape(name),
                ellipsize = "end",
                widget = wibox.widget.textbox,
            },
            {
                markup = string.format(
                    "<span foreground='%s'>%s</span>",
                    gears.string.xml_escape(meta_fg),
                    gears.string.xml_escape(device_metadata(device))
                ),
                ellipsize = "end",
                widget = wibox.widget.textbox,
            },
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        },
        nil,
        {
            markup = string.format(
                "<span foreground='%s'>%s</span>",
                gears.string.xml_escape(meta_fg),
                gears.string.xml_escape(action)
            ),
            align = "right",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        expand = "inside",
        layout = wibox.layout.align.horizontal,
    })

    return selectable_card(instance, row, selected, selection_index, onclick)
end

---Attach popup rendering and selection-state methods to the lxbluetooth instance.
function popup.extend(instance_methods)
    function instance_methods:_set_popup_selection(index)
        local items = self._popup_items or {}
        if index == nil or index < 1 or index > #items or self._popup_selected_index == index then
            return
        end

        self._popup_selected_index = index

        for item_index, item in ipairs(items) do
            if item.widget and item.widget._lx_set_selected then
                item.widget:_lx_set_selected(item_index == index)
            end
        end
    end

    function instance_methods:_refresh_popup()
        if not self._popup_refs then
            return
        end

        local refs = self._popup_refs
        refs.list:reset()
        refs.status:reset()
        self._popup_items = {
            {
                widget = refs.open_manager_action,
                on_enter = function()
                    self:close_popup()
                    self:open_manager()
                end,
            },
            {
                widget = refs.toggle_power_action,
                on_enter = function()
                    self:toggle_power()
                end,
            },
        }

        local status_parts = {
            self.state.powered and "Bluetooth powered" or "Bluetooth disabled",
        }

        if self.state.powered and (self.state.connected_count or 0) > 0 then
            status_parts[#status_parts + 1] = string.format("%d connected", self.state.connected_count)
        end

        refs.status:add(wrap_card(wibox.widget({
            make_section_header(self, "Status"),
            make_status_line(self, table.concat(status_parts, " • ")),
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        })))

        refs.list:add(wrap_card(wibox.widget({
            make_section_header(self, "Devices"),
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        })))

        for _, device in ipairs(self.state.devices) do
            local next_index = #self._popup_items + 1
            local selected = self._popup_selected_index == next_index
            local row = make_device_row(self, device, selected, next_index, function()
                if device.connected then
                    self:_device_action("disconnect", device.address)
                else
                    self:_device_action("connect", device.address)
                end
            end)

            refs.list:add(row)
            self._popup_items[#self._popup_items + 1] = {
                widget = row,
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
            refs.list:add(wrap_card(make_status_line(self, "No paired devices found.")))
        end
    end

    function instance_methods:_build_popup()
        local open_manager_action = selectable_card(
            self,
            popup_common.make_text("Open blueman-manager"),
            self._popup_selected_index == 1,
            1,
            function()
                self:close_popup()
                self:open_manager()
            end
        )
        local toggle_power_action = selectable_card(
            self,
            popup_common.make_text("Toggle controller power"),
            self._popup_selected_index == 2,
            2,
            function()
                self:toggle_power()
            end
        )
        local status = wibox.layout.fixed.vertical()
        local list = wibox.layout.fixed.vertical()

        self._popup_refs = {
            open_manager_action = open_manager_action,
            toggle_power_action = toggle_power_action,
            status = status,
            list = list,
        }

        local popup_widget = wibox.widget({
            {
                open_manager_action,
                toggle_power_action,
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

        self:_set_popup_selection(math.max(1, math.min((self._popup_selected_index or 1) + delta, count)))
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
