local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local popup_common = require("lxcommon.popup_ui")
local screen_util = require("lxcommon.screen")
local popup_placement = require("lxcommon.popup_placement")

local popup = {}

local function apply_popup_geometry(instance, popup_widget, anchor)
    local target_screen = screen_util.resolve_screen(anchor)
    popup_placement.apply(
        popup_widget,
        target_screen,
        instance:_theme_value("lxnetwork_popup_placement", "side"),
        { width = math.min(instance:_theme_value("lxnetwork_popup_width", 380), target_screen.workarea.width) }
    )
end

local function make_signal_bar(instance, signal)
    return wibox.widget({
        max_value = 100,
        value = signal or 0,
        forced_width = instance:_theme_value("lxnetwork_signal_bar_width", 56),
        forced_height = 8,
        paddings = 0,
        border_width = 0,
        background_color = instance:_theme_value("lxnetwork_signal_bar_bg", beautiful.bg_minimize or "#140c0b"),
        color = instance:_theme_value("lxnetwork_signal_bar_fg", beautiful.fg_normal or "#e2ccb0"),
        widget = wibox.widget.progressbar,
    })
end

local function network_metadata(network)
    local parts = {}

    if network.active then
        parts[#parts + 1] = "connected"
    elseif network.known then
        parts[#parts + 1] = "saved"
    end

    if network.security and network.security ~= "" and network.security ~= "--" then
        parts[#parts + 1] = "secured"
    else
        parts[#parts + 1] = "open"
    end

    if network.standard then
        parts[#parts + 1] = network.standard
    end

    return table.concat(parts, " • ")
end

local function make_section_header(instance, text)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999")),
        gears.string.xml_escape(text)
    ), {
        top = 4,
        bottom = 2,
    })
end

local function make_status_line(instance, text, fg_key, fallback)
    return popup_common.make_info_line(string.format(
        "<span foreground='%s'>%s</span>",
        gears.string.xml_escape(instance:_theme_value(fg_key, fallback)),
        gears.string.xml_escape(text)
    ))
end

local function make_network_row(instance, network, selected, onclick)
    local name = network.ssid
    if network.active then
        name = "● " .. name
    end

    local signal = math.max(0, math.min(100, tonumber(network.signal) or 0))
    local meta_fg = instance:_theme_value("lxnetwork_meta_fg", beautiful.fg_minimize or "#999999")
    local row_content = wibox.widget({
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
                    gears.string.xml_escape(network_metadata(network))
                ),
                ellipsize = "end",
                widget = wibox.widget.textbox,
            },
            spacing = 2,
            layout = wibox.layout.fixed.vertical,
        },
        nil,
        {
            {
                {
                    markup = string.format(
                        "<span foreground='%s'>%d%%</span>",
                        gears.string.xml_escape(meta_fg),
                        signal
                    ),
                    align = "right",
                    widget = wibox.widget.textbox,
                },
                {
                    make_signal_bar(instance, signal),
                    top = 3,
                    widget = wibox.container.margin,
                },
                spacing = 0,
                layout = wibox.layout.fixed.vertical,
            },
            halign = "right",
            valign = "center",
            widget = wibox.container.place,
        },
        expand = "inside",
        layout = wibox.layout.align.horizontal,
    })

    return popup_common.make_selectable_click_container(row_content, onclick, {
        selected = selected,
        inner_bg = instance:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
        hover_bg = instance:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
        outer_bg = instance:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
        selected_bg = instance:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
    })
end

---Attach popup rendering and selection-state methods to the lxnetwork instance.
function popup.extend(instance_methods)
    function instance_methods:_refresh_popup()
        if not self._popup_refs then
            return
        end

        local refs = self._popup_refs
        refs.current_header:reset()
        refs.current_header:add(make_section_header(self, "Current"))
        refs.current_value_container:reset()

        if not self.state.enabled then
            refs.current_value_container:add(make_status_line(
                self,
                "wifi disabled",
                "lxnetwork_widget_disabled_fg",
                beautiful.fg_minimize or "#888888"
            ))
        elseif self.state.scan_in_progress then
            refs.current_value_container:add(make_status_line(
                self,
                "scanning...",
                "lxnetwork_widget_fg",
                beautiful.fg_normal or "#ffffff"
            ))
        else
            local current_network = self:current_network_entry()
            if current_network then
                refs.current_value_container:add(make_network_row(self, current_network, false, nil))
            else
                refs.current_value_container:add(make_status_line(
                    self,
                    "offline",
                    "lxnetwork_widget_fg",
                    beautiful.fg_normal or "#ffffff"
                ))
            end
        end

        refs.known_list:reset()
        refs.available_list:reset()
        local known_count = 0
        local available_count = 0
        self._popup_items = {
            {
                on_enter = function()
                    self:scan()
                end,
            },
            {
                on_enter = function()
                    self:toggle_wifi_enabled()
                end,
            },
        }

        for _, network in ipairs(self.state.networks) do
            if network.active or (self.state.current_ssid and network.ssid == self.state.current_ssid) then
                goto continue
            end

            local selected = self._popup_selected_index == (#self._popup_items + 1)
            local row = make_network_row(self, network, selected, function()
                self:_connect_network(network)
            end)

            self._popup_items[#self._popup_items + 1] = {
                on_enter = function()
                    self:_connect_network(network)
                end,
            }

            if network.known then
                refs.known_list:add(row)
                known_count = known_count + 1
            else
                refs.available_list:add(row)
                available_count = available_count + 1
            end

            ::continue::
        end

        if known_count == 0 then
            refs.known_list:add(make_status_line(
                self,
                "No visible known networks.",
                "lxnetwork_meta_fg",
                beautiful.fg_minimize or "#999999"
            ))
        end

        if available_count == 0 then
            refs.available_list:add(make_status_line(
                self,
                "No additional networks.",
                "lxnetwork_meta_fg",
                beautiful.fg_minimize or "#999999"
            ))
        end
    end

    function instance_methods:_build_popup()
        local current_header = wibox.layout.fixed.vertical()
        local current_value_container = wibox.layout.fixed.vertical()
        local known_list = wibox.layout.fixed.vertical()
        local available_list = wibox.layout.fixed.vertical()

        self._popup_refs = {
            current_header = current_header,
            current_value_container = current_value_container,
            known_list = known_list,
            available_list = available_list,
        }

        self:_refresh_popup()

        return wibox.widget({
            {
                popup_common.make_selectable_click_row("Scan WiFi", function()
                    self:scan()
                end, {
                    selected = self._popup_selected_index == 1,
                    inner_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                    hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
                    outer_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                    selected_bg = self:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
                }),
                popup_common.make_selectable_click_row(self.state.enabled and "Disable WiFi" or "Enable WiFi", function()
                    self:toggle_wifi_enabled()
                end, {
                    selected = self._popup_selected_index == 2,
                    inner_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                    hover_bg = self:_theme_value("lxnetwork_button_hover", beautiful.bg_focus or "#444444"),
                    outer_bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
                    selected_bg = self:_theme_value("lxnetwork_selected_bg", beautiful.border_focus or beautiful.bg_focus or "#666666"),
                }),
                current_header,
                current_value_container,
                make_section_header(self, "Known"),
                known_list,
                make_section_header(self, "Available"),
                available_list,
                spacing = 8,
                layout = wibox.layout.fixed.vertical,
            },
            margins = 10,
            widget = wibox.container.margin,
        })
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
                bg = self:_theme_value("lxnetwork_popup_bg", beautiful.bg_normal or "#222222"),
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
